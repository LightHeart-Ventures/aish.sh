/* ============================================================
   aish docs — behavior
   - year stamp
   - scrollspy: highlight the sidebar link for the section in view
   - smooth in-page nav; respects prefers-reduced-motion
   ============================================================ */
(function () {
  "use strict";

  /* ---------- year ---------- */
  var yr = document.getElementById("yr");
  if (yr) yr.textContent = new Date().getFullYear();

  /* ---------- scrollspy ---------- */
  var links = Array.prototype.slice.call(
    document.querySelectorAll('.docs-nav__list a[href^="#"]')
  );
  if (!links.length || !("IntersectionObserver" in window)) return;

  var byId = {};
  links.forEach(function (a) {
    var id = a.getAttribute("href").slice(1);
    if (id) byId[id] = a;
  });

  var sections = links
    .map(function (a) { return document.getElementById(a.getAttribute("href").slice(1)); })
    .filter(Boolean);

  var current = null;
  function setActive(id) {
    if (id === current) return;
    current = id;
    links.forEach(function (a) { a.classList.remove("is-active"); });
    if (byId[id]) byId[id].classList.add("is-active");
  }

  var visible = {};
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      visible[e.target.id] = e.isIntersecting ? e.intersectionRatio : 0;
    });
    // pick the top-most section currently intersecting
    var best = null, bestTop = Infinity;
    sections.forEach(function (s) {
      if (visible[s.id] > 0) {
        var top = s.getBoundingClientRect().top;
        if (top < bestTop) { bestTop = top; best = s.id; }
      }
    });
    if (best) setActive(best);
  }, { rootMargin: "-30% 0px -60% 0px", threshold: [0, 0.2, 1] });

  sections.forEach(function (s) { io.observe(s); });

  // set initial active from hash or first section
  var hash = window.location.hash.slice(1);
  setActive(hash && byId[hash] ? hash : (sections[0] && sections[0].id));
})();
