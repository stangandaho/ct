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
      '<section id="ct-ai-panel" hidden aria-live="polite">' +
      '  <header id="ct-ai-header">' +
      "    <span>ct assistant</span>" +
      '    <button id="ct-ai-close" aria-label="Close">&times;</button>' +
      "  </header>" +
      '  <div id="ct-ai-log">' +
      '    <div class="ct-ai-msg ct-ai-a"><div class="ct-ai-bubble">' +
      "Ask me anything about analysing camera trap data with the <code>ct</code> package. " +
      "You can also attach a CSV, TXT or Excel file for tailored code." +
      "</div></div>" +
      "  </div>" +
      '  <div id="ct-ai-chip" hidden></div>' +
      '  <form id="ct-ai-form">' +
      '    <button type="button" id="ct-ai-attach" aria-label="Attach a data file" ' +
      '      title="Attach CSV, TXT or Excel">&#128206;</button>' +
      '    <input id="ct-ai-file" type="file" accept=".csv,.tsv,.txt,.xlsx,.xls" hidden />' +
      '    <input id="ct-ai-input" type="text" autocomplete="off" placeholder="How to ..." />' +
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
    var chip = root.querySelector("#ct-ai-chip");
    var fileInput = root.querySelector("#ct-ai-file");

    function toggle(show) {
      panel.hidden = show === undefined ? !panel.hidden : !show;
      if (!panel.hidden) input.focus();
    }
    root.querySelector("#ct-ai-toggle").addEventListener("click", function () { toggle(); });
    root.querySelector("#ct-ai-close").addEventListener("click", function () { toggle(false); });

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
        display += "  \u{1F4CE} " + pendingDataset.name;
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
