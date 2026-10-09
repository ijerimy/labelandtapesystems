(() => {
  const toggle = document.querySelector('.nav-toggle');
  const menu = document.getElementById('menu');
  toggle.addEventListener('click', () => {
    const open = menu.classList.toggle('open');
    toggle.setAttribute('aria-expanded', String(open));
  });

  // Gentle reveal as content scrolls in
  if ('IntersectionObserver' in window) {
    const items = document.querySelectorAll('.step, .system, .prod, .quote, .reasons li, .warranty, .kp-box');
    items.forEach((el) => el.classList.add('rv'));
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => { if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); } });
    }, { rootMargin: '0px 0px -6% 0px' });
    items.forEach((el) => io.observe(el));
  }

  document.querySelectorAll('.yr').forEach((el) => { el.textContent = new Date().getFullYear(); });
})();
