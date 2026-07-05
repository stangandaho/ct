/*
 * ct package website assistant widget.
 *
 * pkgdown automatically links pkgdown/extra.js on every page of the built
 * site. It talks to the Cloudflare Worker in assistant/worker.ts.
 *
 * Set ENDPOINT to your deployed Worker URL before building the site.
 */
(function () {
  "use strict";

  var ENDPOINT = "https://ct-assistant.stangandaho.workers.dev";

  // Conversation state (kept in memory only, cleared on reload).
  var history = [];

  // ---- Minimal, XSS-safe Markdown -> HTML ---------------------------------
  // Handles the constructs a code-heavy Q&A actually produces: fenced code
  // blocks, inline code, bold, headings, links, and lists. Everything is
  // HTML-escaped first, so model output can never inject markup.
  function escapeHtml(s) {
    return s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderInline(s) {
    // inline code
    s = s.replace(/`([^`]+)`/g, function (_, c) {
      return "<code>" + c + "</code>";
    });
    // bold
    s = s.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    // links [text](url) — only http(s) URLs
    s = s.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g, function (_, t, u) {
      return '<a href="' + u + '" target="_blank" rel="noopener">' + t + "</a>";
    });
    return s;
  }

  function renderMarkdown(md) {
    var escaped = escapeHtml(md);
    var parts = escaped.split(/```/); // odd indices are code blocks
    var html = "";
    for (var i = 0; i < parts.length; i++) {
      if (i % 2 === 1) {
        // code block: strip an optional language token on the first line
        var code = parts[i].replace(/^[a-zA-Z0-9_-]*\n/, "");
        html += "<pre><code>" + code.replace(/\n$/, "") + "</code></pre>";
        continue;
      }
      var lines = parts[i].split("\n");
      var inList = false;
      for (var j = 0; j < lines.length; j++) {
        var line = lines[j];
        var heading = line.match(/^(#{1,4})\s+(.*)$/);
        var bullet = line.match(/^[-*]\s+(.*)$/);
        if (heading) {
          if (inList) { html += "</ul>"; inList = false; }
          var lvl = heading[1].length + 2; // h3..h6
          html += "<h" + lvl + ">" + renderInline(heading[2]) + "</h" + lvl + ">";
        } else if (bullet) {
          if (!inList) { html += "<ul>"; inList = true; }
          html += "<li>" + renderInline(bullet[1]) + "</li>";
        } else if (line.trim() === "") {
          if (inList) { html += "</ul>"; inList = false; }
        } else {
          if (inList) { html += "</ul>"; inList = false; }
          html += "<p>" + renderInline(line) + "</p>";
        }
      }
      if (inList) html += "</ul>";
    }
    return html;
  }

  // UI
  function build() {
    var root = document.createElement("div");
    root.id = "ct-ai";
    root.innerHTML =
      '<button id="ct-ai-toggle" aria-label="Ask the ct assistant" title="Ask the ct assistant">' +
      "Ask ct</button>" +
      '<section id="ct-ai-panel" hidden aria-live="polite">' +
      '  <header id="ct-ai-header">' +
      "    <span>ct assistant</span>" +
      '    <button id="ct-ai-close" aria-label="Close">&times;</button>' +
      "  </header>" +
      '  <div id="ct-ai-log">' +
      '    <div class="ct-ai-msg ct-ai-a"><div class="ct-ai-bubble">' +
      "Ask me anything about analysing camera trap data with the <code>ct</code> package" +
      "</div></div>" +
      "  </div>" +
      '  <form id="ct-ai-form">' +
      '    <input id="ct-ai-input" type="text" autocomplete="off" ' +
      '      placeholder="How to ..." />' +
      '    <button type="submit" id="ct-ai-send" aria-label="Send">Send</button>' +
      "  </form>" +
      '  <footer id="ct-ai-foot">Answers are AI-generated. ' +
      "Verify before relying on them.</footer>" +
      "</section>";
    document.body.appendChild(root);

    var panel = root.querySelector("#ct-ai-panel");
    var log = root.querySelector("#ct-ai-log");
    var form = root.querySelector("#ct-ai-form");
    var input = root.querySelector("#ct-ai-input");
    var send = root.querySelector("#ct-ai-send");

    function toggle(show) {
      panel.hidden = show === undefined ? !panel.hidden : !show;
      if (!panel.hidden) input.focus();
    }
    root.querySelector("#ct-ai-toggle").addEventListener("click", function () { toggle(); });
    root.querySelector("#ct-ai-close").addEventListener("click", function () { toggle(false); });

    function addMessage(role, initialText) {
      var wrap = document.createElement("div");
      wrap.className = "ct-ai-msg " + (role === "user" ? "ct-ai-u" : "ct-ai-a");
      var bubble = document.createElement("div");
      bubble.className = "ct-ai-bubble";
      wrap.appendChild(bubble);
      log.appendChild(wrap);
      if (role === "user") {
        bubble.textContent = initialText;
      }
      log.scrollTop = log.scrollHeight;
      return bubble;
    }

    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var q = input.value.trim();
      if (!q) return;
      input.value = "";
      input.disabled = true;
      send.disabled = true;

      history.push({ role: "user", content: q });
      addMessage("user", q);
      var answerBubble = addMessage("assistant", "");
      answerBubble.classList.add("ct-ai-typing");
      answerBubble.textContent = "…";

      fetch(ENDPOINT, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ messages: history }),
      })
        .then(function (res) {
          if (!res.ok) throw new Error("HTTP " + res.status);
          var reader = res.body.getReader();
          var dec = new TextDecoder();
          var full = "";
          answerBubble.classList.remove("ct-ai-typing");
          function pump() {
            return reader.read().then(function (r) {
              if (r.done) {
                history.push({ role: "assistant", content: full });
                return;
              }
              full += dec.decode(r.value, { stream: true });
              answerBubble.innerHTML = renderMarkdown(full);
              log.scrollTop = log.scrollHeight;
              return pump();
            });
          }
          return pump();
        })
        .catch(function () {
          answerBubble.classList.remove("ct-ai-typing");
          answerBubble.textContent =
            "Sorry! I couldn't reach the assistant. Please try again in a moment.";
        })
        .finally(function () {
          input.disabled = false;
          send.disabled = false;
          input.focus();
        });
    });
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", build);
  } else {
    build();
  }
})();
