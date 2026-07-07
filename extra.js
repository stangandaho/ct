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
  // A dataset the user attached but has not sent yet: { name, profile }.
  var pendingDataset = null;

  // ---- Inline SVG icons ---------------------------------------------------
  var SEND_SVG = '<svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden="true"><path d="M2 21l21-9L2 3v7l15 2-15 2z"/></svg>';
  var EXPAND_SVG = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M4 9V4h5M20 15v5h-5M15 4h5v5M9 20H4v-5"/></svg>';
  var COMPRESS_SVG = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M9 4v5H4M20 9h-5V4M4 15h5v5M15 20v-5h5"/></svg>';
  var CLOSE_SVG = '<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg>';
  var COPY_SVG = '<svg viewBox="0 0 24 24" width="13" height="13" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>';

  // ---- Syntax highlighting (lazy) -----------------------------------------
  // highlight.js + the R grammar are fetched from a CDN the first time an
  // answer contains a code block, giving IDE-like colours.
  var hljsPromise = null;
  function loadHighlighter() {
    if (window.hljs) return Promise.resolve(window.hljs);
    if (hljsPromise) return hljsPromise;
    var base = "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/";
    hljsPromise = new Promise(function (resolve, reject) {
      var core = document.createElement("script");
      core.src = base + "highlight.min.js";
      core.onload = function () {
        var rlang = document.createElement("script");
        rlang.src = base + "languages/r.min.js";
        rlang.onload = function () { resolve(window.hljs); };
        rlang.onerror = function () { resolve(window.hljs); }; // core still works
        document.head.appendChild(rlang);
      };
      core.onerror = function () { reject(new Error("highlighter load failed")); };
      document.head.appendChild(core);
    });
    return hljsPromise;
  }

  // Wire the copy buttons and apply syntax colouring inside a rendered answer.
  function enhanceAnswer(bubble) {
    var blocks = bubble.querySelectorAll(".ct-ai-code");
    if (!blocks.length) return;
    blocks.forEach(function (block) {
      if (block.dataset.enhanced) return;
      block.dataset.enhanced = "1";
      var btn = block.querySelector(".ct-ai-copy");
      var codeEl = block.querySelector("code");
      if (!btn || !codeEl) return;
      btn.addEventListener("click", function () {
        navigator.clipboard.writeText(codeEl.textContent).then(function () {
          btn.classList.add("ct-ai-copied");
          btn.innerHTML = "Copied";
          setTimeout(function () {
            btn.classList.remove("ct-ai-copied");
            btn.innerHTML = COPY_SVG + "Copy";
          }, 1500);
        });
      });
    });
    loadHighlighter()
      .then(function (hljs) {
        if (!hljs) return;
        bubble.querySelectorAll("pre code").forEach(function (el) {
          if (el.dataset.highlighted) return;
          el.dataset.highlighted = "1";
          hljs.highlightElement(el);
        });
      })
      .catch(function () {});
  }

  // ---- Minimal, XSS-safe Markdown -> HTML ---------------------------------
  function escapeHtml(s) {
    return s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderInline(s) {
    s = s.replace(/`([^`]+)`/g, function (_, c) { return "<code>" + c + "</code>"; });
    s = s.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
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
        // fenced code block: capture optional language token; default to R
        var langMatch = parts[i].match(/^([a-zA-Z0-9_-]+)\n/);
        var lang = langMatch ? langMatch[1].toLowerCase() : "r";
        var code = parts[i].replace(/^[a-zA-Z0-9_-]*\n/, "").replace(/\n$/, "");
        html +=
          '<div class="ct-ai-code">' +
          '<button class="ct-ai-copy" type="button" aria-label="Copy code">' + COPY_SVG + "Copy</button>" +
          '<pre><code class="language-' + lang + '">' + code + "</code></pre>" +
          "</div>";
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

  // ---- Data file parsing --------------------------------------------------
  // We never upload the raw file. We read it in the browser and send only a
  // compact PROFILE (columns, inferred types, a few sample rows, row count) so
  // the assistant can tailor ct code to the user's actual columns.
  function detectDelimiter(headerLine) {
    var cands = [",", ";", "\t", "|"];
    var best = ",", max = -1;
    cands.forEach(function (c) {
      var n = headerLine.split(c).length - 1;
      if (n > max) { max = n; best = c; }
    });
    return best;
  }

  function splitRow(line, delim) {
    var out = [], cur = "", inQ = false;
    for (var i = 0; i < line.length; i++) {
      var ch = line[i];
      if (ch === '"') { inQ = !inQ; continue; }
      if (ch === delim && !inQ) { out.push(cur); cur = ""; continue; }
      cur += ch;
    }
    out.push(cur);
    return out;
  }

  function inferType(values) {
    var nums = 0, dates = 0, nonEmpty = 0;
    values.forEach(function (v) {
      v = (v == null ? "" : String(v)).trim();
      if (!v) return;
      nonEmpty++;
      if (!isNaN(Number(v))) nums++;
      else if (/^\d{4}[-/]\d{1,2}[-/]\d{1,2}/.test(v) || /\d{1,2}:\d{2}/.test(v)) dates++;
    });
    if (nonEmpty === 0) return "empty";
    if (nums === nonEmpty) return "number";
    if (dates >= nonEmpty * 0.6) return "datetime";
    return "text";
  }

  function buildProfile(name, header, rows, totalRows) {
    header = header.slice(0, 40).map(function (h) {
      return (h == null ? "" : String(h)).trim() || "(unnamed)";
    });
    var sample = rows.slice(0, 5);
    var colLines = header.map(function (h, i) {
      return h + " (" + inferType(sample.map(function (r) { return r[i]; })) + ")";
    });
    var out = [
      "[Attached dataset: " + name + " — " + totalRows + " rows, " + header.length + " columns]",
      "Columns: " + colLines.join(", "),
      "Sample rows:",
      header.join(" | ")
    ];
    sample.forEach(function (r) {
      out.push(header.map(function (_, i) {
        return String(r[i] == null ? "" : r[i]).slice(0, 30);
      }).join(" | "));
    });
    return out.join("\n").slice(0, 6000);
  }

  function parseDelimited(name, text) {
    var lines = text.split(/\r?\n/).filter(function (l) { return l.length > 0; });
    if (!lines.length) return null;
    var delim = detectDelimiter(lines[0]);
    var header = splitRow(lines[0], delim);
    var rows = lines.slice(1, 6).map(function (l) { return splitRow(l, delim); });
    return buildProfile(name, header, rows, lines.length - 1);
  }

  // SheetJS is only fetched (from a CDN) the first time an Excel file is chosen.
  function loadSheetJS() {
    return new Promise(function (resolve, reject) {
      if (window.XLSX) return resolve(window.XLSX);
      var s = document.createElement("script");
      s.src = "https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js";
      s.onload = function () { resolve(window.XLSX); };
      s.onerror = function () { reject(new Error("Could not load the Excel reader.")); };
      document.head.appendChild(s);
    });
  }

  function parseXlsx(name, buffer) {
    return loadSheetJS().then(function (XLSX) {
      var wb = XLSX.read(buffer, { type: "array" });
      var ws = wb.Sheets[wb.SheetNames[0]];
      var rows = XLSX.utils.sheet_to_json(ws, { header: 1, blankrows: false });
      if (!rows.length) return null;
      return buildProfile(name, rows[0], rows.slice(1, 6), rows.length - 1);
    });
  }

  // ---- UI -----------------------------------------------------------------
  function build() {
    var root = document.createElement("div");
    root.id = "ct-ai";
    root.innerHTML =
      '<button id="ct-ai-toggle" aria-label="Ask the ct assistant" title="Ask the ct assistant">' +
      "Ask ct</button>" +
      '<div id="ct-ai-backdrop" hidden></div>' +
      '<section id="ct-ai-panel" hidden aria-live="polite" role="dialog" aria-modal="true" aria-label="ct assistant">' +
      '  <header id="ct-ai-header">' +
      "    <span>ct assistant</span>" +
      '    <div id="ct-ai-actions">' +
      '      <button id="ct-ai-expand" type="button" aria-label="Expand" title="Expand">' + EXPAND_SVG + "</button>" +
      '      <button id="ct-ai-close" type="button" aria-label="Close" title="Close">' + CLOSE_SVG + "</button>" +
      "    </div>" +
      "  </header>" +
      '  <div id="ct-ai-log">' +
      '    <div class="ct-ai-msg ct-ai-a"><div class="ct-ai-bubble">' +
      "Ask me anything about analysing camera trap data with the <code>ct</code> package. " +
      "</div></div>" +
      "  </div>" +
      '  <div id="ct-ai-chip" hidden></div>' +
      '  <form id="ct-ai-form">' +
      '    <button type="button" id="ct-ai-attach" aria-label="Attach a data file" ' +
      '      title="Attach CSV, TXT or Excel">&#128206;</button>' +
      '    <input id="ct-ai-file" type="file" accept=".csv,.tsv,.txt,.xlsx,.xls" hidden />' +
      '    <input id="ct-ai-input" type="text" autocomplete="off" placeholder="How to ..." />' +
      '    <button type="submit" id="ct-ai-send" aria-label="Send" title="Send">' + SEND_SVG + "</button>" +
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
    var chip = root.querySelector("#ct-ai-chip");
    var fileInput = root.querySelector("#ct-ai-file");

    var backdrop = root.querySelector("#ct-ai-backdrop");
    var expandBtn = root.querySelector("#ct-ai-expand");
    var expanded = false;

    function setOpen(open) {
      panel.hidden = !open;
      backdrop.hidden = !open;
      if (open) input.focus();
    }
    root.querySelector("#ct-ai-toggle").addEventListener("click", function () { setOpen(panel.hidden); });
    root.querySelector("#ct-ai-close").addEventListener("click", function () { setOpen(false); });
    backdrop.addEventListener("click", function () { setOpen(false); });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && !panel.hidden) setOpen(false);
    });

    expandBtn.addEventListener("click", function () {
      expanded = !expanded;
      panel.classList.toggle("ct-ai-expanded", expanded);
      expandBtn.innerHTML = expanded ? COMPRESS_SVG : EXPAND_SVG;
      expandBtn.title = expanded ? "Restore size" : "Expand";
    });

    // ---- Attachment chip ----
    function renderChip() {
      if (!pendingDataset) { chip.hidden = true; chip.textContent = ""; return; }
      chip.hidden = false;
      chip.innerHTML =
        '<span>&#128206; ' + escapeHtml(pendingDataset.name) + "</span>" +
        '<button type="button" id="ct-ai-chip-x" aria-label="Remove attachment">&times;</button>';
      chip.querySelector("#ct-ai-chip-x").addEventListener("click", function () {
        pendingDataset = null;
        renderChip();
      });
    }
    function chipError(msg) {
      pendingDataset = null;
      chip.hidden = false;
      chip.innerHTML = '<span class="ct-ai-chip-err">' + escapeHtml(msg) + "</span>";
      setTimeout(function () {
        if (!pendingDataset) { chip.hidden = true; chip.textContent = ""; }
      }, 4000);
    }

    function handleFile(file) {
      if (!file) return;
      if (file.size > 8 * 1024 * 1024) { chipError(file.name + " is too large (max 8 MB)."); return; }
      var lower = file.name.toLowerCase();
      var done = function (profile) {
        if (!profile) { chipError("Couldn't read " + file.name + "."); return; }
        pendingDataset = { name: file.name, profile: profile };
        renderChip();
      };
      if (/\.(xlsx|xls)$/.test(lower)) {
        file.arrayBuffer()
          .then(function (buf) { return parseXlsx(file.name, buf); })
          .then(done)
          .catch(function (e) { chipError(String((e && e.message) || e)); });
      } else if (/\.(csv|tsv|txt)$/.test(lower)) {
        file.text().then(function (t) { done(parseDelimited(file.name, t)); })
          .catch(function () { chipError("Couldn't read " + file.name + "."); });
      } else {
        chipError("Unsupported file. Use CSV, TXT or Excel.");
      }
    }

    root.querySelector("#ct-ai-attach").addEventListener("click", function () { fileInput.click(); });
    fileInput.addEventListener("change", function () {
      handleFile(fileInput.files && fileInput.files[0]);
      fileInput.value = ""; // allow re-selecting the same file
    });

    // ---- Messages ----
    function addMessage(role, text) {
      var wrap = document.createElement("div");
      wrap.className = "ct-ai-msg " + (role === "user" ? "ct-ai-u" : "ct-ai-a");
      var bubble = document.createElement("div");
      bubble.className = "ct-ai-bubble";
      wrap.appendChild(bubble);
      log.appendChild(wrap);
      if (role === "user") bubble.textContent = text;
      log.scrollTop = log.scrollHeight;
      return bubble;
    }

    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var q = input.value.trim();
      if (!q && !pendingDataset) return;

      // Build what we DISPLAY vs what we SEND (the send text carries the
      // dataset profile so the model sees the columns).
      var display = q || "Analyse the attached file";
      var sendContent = q;
      if (pendingDataset) {
        sendContent =
          pendingDataset.profile +
          "\n\nQuestion: " +
          (q || "Help me analyse this dataset with the ct package.");
      }

      input.value = "";
      input.disabled = true;
      send.disabled = true;
      pendingDataset = null;
      renderChip();

      history.push({ role: "user", content: sendContent });
      addMessage("user", display);
      var answerBubble = addMessage("assistant", "");
      answerBubble.classList.add("ct-ai-typing");
      answerBubble.innerHTML =
        '<span class="ct-ai-dots"><span></span><span></span><span></span></span>';

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
          function pump() {
            return reader.read().then(function (r) {
              if (r.done) {
                history.push({ role: "assistant", content: full });
                return;
              }
              full += dec.decode(r.value, { stream: true });
              answerBubble.classList.remove("ct-ai-typing");
              answerBubble.innerHTML = renderMarkdown(full);
              enhanceAnswer(answerBubble);
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
