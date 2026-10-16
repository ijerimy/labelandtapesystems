(() => {
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // Mobile menu
  const toggle = document.querySelector('.nav-toggle');
  const menu = document.getElementById('menu');
  toggle.addEventListener('click', () => {
    const open = menu.classList.toggle('open');
    toggle.setAttribute('aria-expanded', String(open));
  });

  document.querySelectorAll('.yr').forEach((el) => { el.textContent = new Date().getFullYear(); });
  if (reduce || !('IntersectionObserver' in window)) return;

  // Staggered scroll reveal
  const items = document.querySelectorAll('.step, .system, .prod, .quote, .reasons li, .warranty, .kp-box, .kit, .labels, .howto li, .contact div, .terms div');
  items.forEach((el) => {
    el.classList.add('rv');
    const sibs = [...el.parentElement.children].filter((c) => c.matches(el.tagName));
    el.style.transitionDelay = `${Math.min(sibs.indexOf(el), 6) * 90}ms`;
  });
  const io = new IntersectionObserver((entries) => {
    entries.forEach((en) => { if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); } });
  }, { rootMargin: '0px 0px -8% 0px' });
  items.forEach((el) => io.observe(el));

  // Count-up stats (30, 11,000+, 100%)
  const counters = document.querySelectorAll('.facts b');
  const cio = new IntersectionObserver((entries) => {
    entries.forEach((en) => {
      if (!en.isIntersecting) return;
      cio.unobserve(en.target);
      const el = en.target, txt = el.textContent, m = txt.match(/[\d,]+/);
      if (!m) return;
      const end = parseInt(m[0].replace(/,/g, ''), 10), pre = txt.slice(0, m.index), post = txt.slice(m.index + m[0].length);
      const t0 = performance.now(), dur = 1400;
      const step = (t) => {
        const k = Math.min(1, (t - t0) / dur), e = 1 - Math.pow(1 - k, 3);
        el.textContent = pre + Math.round(end * e).toLocaleString('en-US') + post;
        if (k < 1) requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    });
  }, { threshold: 0.6 });
  counters.forEach((c) => cio.observe(c));

  // Dot-matrix "printing" on the hero label tag
  const tag = document.querySelector('.print-tag > span');
  if (tag) {
    const text = tag.textContent;
    tag.setAttribute('aria-label', text);
    tag.innerHTML = [...text].map((c) => `<span class="ch" aria-hidden="true">${c === ' ' ? '&nbsp;' : c}</span>`).join('');
    const chars = tag.querySelectorAll('.ch');
    let i = 0;
    setTimeout(function tick() {
      if (i < chars.length) { chars[i++].classList.add('on'); setTimeout(tick, 45); }
    }, 1500);
  }
})();
