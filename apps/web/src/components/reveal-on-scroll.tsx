'use client';

import { useEffect } from 'react';

/**
 * Lets the [data-reveal] items of the page rise into place as they scroll into
 * view (styles in globals.css). What is already on screen is marked shown first,
 * so nothing blinks; with "reduce motion" on, nothing is hidden at all.
 */
export function RevealOnScroll() {
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches || !('IntersectionObserver' in window)) return;
    const items = Array.from(document.querySelectorAll<HTMLElement>('[data-reveal]'));
    const h = window.innerHeight;
    for (const el of items) {
      const r = el.getBoundingClientRect();
      if (r.top < h && r.bottom > 0) el.classList.add('is-shown');
    }
    const root = document.documentElement;
    root.classList.add('reveal-ready');
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            e.target.classList.add('is-shown');
            io.unobserve(e.target);
          }
        }
      },
      { rootMargin: '0px 0px -8% 0px', threshold: 0.12 },
    );
    items.filter((el) => !el.classList.contains('is-shown')).forEach((el) => io.observe(el));
    return () => {
      io.disconnect();
      root.classList.remove('reveal-ready');
    };
  }, []);
  return null;
}
