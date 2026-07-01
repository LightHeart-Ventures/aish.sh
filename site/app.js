/* ============================================================
   aish marketing site — behavior
   - terminal typing demo (intent -> streamed result)
   - scroll reveal (IntersectionObserver, staggered cascade)
   - nav scrolled state
   - copy install command + toast
   - respects prefers-reduced-motion; pauses on tab hidden
   ============================================================ */
(function () {
  "use strict";

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  /* ---------- year ---------- */
  var yr = document.getElementById("yr");
  if (yr) yr.textContent = new Date().getFullYear();

  /* ---------- nav scrolled state ---------- */
  var nav = document.getElementById("nav");
  function onScroll() {
    if (!nav) return;
    nav.classList.toggle("is-scrolled", window.scrollY > 12);
  }
  window.addEventListener("scroll", onScroll, { passive: true });
  onScroll();

  /* ---------- scroll reveal w/ staggered cascade ---------- */
  var revealEls = Array.prototype.slice.call(document.querySelectorAll(".reveal"));
  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealEls.forEach(function (el) { el.classList.add("is-in"); });
  } else {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        var el = entry.target;
        // stagger siblings inside a reveal-group for a waterfall effect
        var group = el.closest(".reveal-group");
        if (group) {
          var sibs = Array.prototype.slice.call(group.querySelectorAll(".reveal"));
          el.style.transitionDelay = (sibs.indexOf(el) * 90) + "ms";
        }
        el.classList.add("is-in");
        io.unobserve(el);
      });
    }, { threshold: 0.16, rootMargin: "0px 0px -8% 0px" });
    revealEls.forEach(function (el) { io.observe(el); });
  }

  /* ---------- terminal typing demo ---------- */
  var term = document.getElementById("term");

  // Each step: type the user's intent after the prompt, then stream system output.
  var script = [
    { type: "prompt" },
    { type: "type", cls: "t-user", text: "tail the error logs for the api service, last hour" },
    { type: "out", cls: "t-sys", text: "→ searching logs · service=api · severity=ERROR · 60m" },
    { type: "out", cls: "t-dim", text: "  17:42:03  api   POST /v1/runs   504 upstream timeout" },
    { type: "out", cls: "t-dim", text: "  17:48:51  api   POST /v1/runs   504 upstream timeout" },
    { type: "out", cls: "t-ok",  text: "✓ 2 errors · both 504 on /v1/runs · likely idle-timeout" },
    { type: "gap" },
    { type: "prompt" },
    { type: "type", cls: "t-user", text: "open a draft PR bumping the ALB idle timeout to 120s" },
    { type: "out", cls: "t-sys", text: "→ branch fix/alb-idle-timeout · 1 file · gh pr create --draft" },
    { type: "out", cls: "t-ok",  text: "✓ draft PR #128 opened — review-ready" },
    { type: "gap" },
    { type: "prompt" },
    { type: "type", cls: "t-user", text: ":backend local" },
    { type: "out", cls: "t-sys", text: "→ loading Qwen3-1.7B · in-process · GGUF" },
    { type: "out", cls: "t-ok",  text: "✓ backend: local — offline, no API key needed" },
    { type: "gap" },
    { type: "prompt" },
    { type: "cursorhold" }
  ];

  function renderFinalState() {
    // Non-animated full render for reduced-motion / no-JS-anim fallback.
    var html = "";
    script.forEach(function (s) {
      if (s.type === "prompt") html += '<span class="t-prompt">&gt; </span>';
      else if (s.type === "type") html += '<span class="' + s.cls + '">' + esc(s.text) + "</span>\n";
      else if (s.type === "out") html += '<span class="' + s.cls + '">' + esc(s.text) + "</span>\n";
      else if (s.type === "gap") html += "\n";
      else if (s.type === "cursorhold") html += '<span class="t-cursor"></span>';
    });
    term.innerHTML = html;
  }

  function esc(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }

  if (!term) {
    /* nothing */
  } else if (reduceMotion) {
    renderFinalState();
  } else {
    runTypingDemo();
  }

  function runTypingDemo() {
    var i = 0;            // step index
    var paused = false;
    var timer = null;
    var cursorEl = null;

    function setCursor(on) {
      if (cursorEl) { cursorEl.remove(); cursorEl = null; }
      if (on) {
        cursorEl = document.createElement("span");
        cursorEl.className = "t-cursor";
        term.appendChild(cursorEl);
      }
    }

    function append(cls, text) {
      var span = document.createElement("span");
      if (cls) span.className = cls;
      span.textContent = text;
      term.insertBefore(span, cursorEl || null);
      return span;
    }

    function schedule(fn, ms) {
      if (paused) { pendingResume = fn; return; }
      timer = setTimeout(fn, ms);
    }

    var pendingResume = null;

    function step() {
      if (i >= script.length) {
        // loop: clear and restart after a beat
        schedule(function () {
          term.innerHTML = "";
          cursorEl = null;
          i = 0;
          step();
        }, 2600);
        return;
      }
      var s = script[i++];

      if (s.type === "prompt") {
        append("t-prompt", "> ");
        setCursor(true);
        schedule(step, 360);

      } else if (s.type === "type") {
        setCursor(true);
        var span = append(s.cls, "");
        var t = 0;
        (function typeChar() {
          if (paused) { pendingResume = typeChar; return; }
          span.textContent += s.text.charAt(t++);
          if (t < s.text.length) {
            timer = setTimeout(typeChar, 26 + Math.random() * 34);
          } else {
            append(null, "\n");
            setCursor(false);
            schedule(step, 420);
          }
        })();

      } else if (s.type === "out") {
        setCursor(false);
        append(s.cls, s.text + "\n");
        schedule(step, 360);

      } else if (s.type === "gap") {
        append(null, "\n");
        schedule(step, 240);

      } else if (s.type === "cursorhold") {
        setCursor(true);
        schedule(step, 1800);
      }
    }

    // Pause animation when tab hidden (battery/CPU; avoids mid-flight resume jank)
    document.addEventListener("visibilitychange", function () {
      if (document.hidden) {
        paused = true;
        if (timer) { clearTimeout(timer); timer = null; }
      } else if (paused) {
        paused = false;
        var fn = pendingResume; pendingResume = null;
        if (fn) fn();
      }
    });

    step();
  }

  /* ---------- copy install command ---------- */
  var copyBtn = document.getElementById("copyBtn");
  var codeEl = document.getElementById("install-code");
  var toast = document.getElementById("toast");
  var toastTimer = null;

  function showToast() {
    if (!toast) return;
    toast.classList.add("is-show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toast.classList.remove("is-show"); }, 2200);
  }

  if (copyBtn && codeEl) {
    copyBtn.addEventListener("click", function () {
      var text = codeEl.innerText || codeEl.textContent || "";
      var done = function () {
        copyBtn.classList.add("is-copied");
        var label = copyBtn.querySelector(".copy-label");
        var prev = label ? label.textContent : null;
        if (label) label.textContent = "Copied";
        showToast();
        setTimeout(function () {
          copyBtn.classList.remove("is-copied");
          if (label && prev) label.textContent = prev;
        }, 2000);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done).catch(fallbackCopy);
      } else {
        fallbackCopy();
      }
      function fallbackCopy() {
        var ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand("copy"); } catch (e) {}
        document.body.removeChild(ta);
        done();
      }
    });
  }
})();
