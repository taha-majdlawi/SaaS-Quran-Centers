'use client';

import { useEffect } from 'react';

/**
 * The garden's numbers grow: the big figures on a page (points, counts, totals - a bold
 * text-xl / 2xl / 3xl that is only a whole number) count up from zero when the page opens,
 * the way the app's header numbers do. The rest of the page's motion is CSS (globals.css,
 * .garden-main). Nothing moves with "reduce motion" on.
 *
 * Only the text node's value changes, and it ends on exactly what the server sent, so
 * React keeps owning the same node.
 */
export function GardenMotion() {
  useEffect(() => {
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;
    const frames: number[] = [];
    const counted: { node: Text; text: string }[] = [];
    const els = document.querySelectorAll<HTMLElement>('.garden-main :is(.text-xl, .text-2xl, .text-3xl, .text-4xl):is(.font-bold, .font-extrabold, .font-black)');
    els.forEach((el, i) => {
      const node = el.childNodes.length === 1 && el.firstChild?.nodeType === Node.TEXT_NODE ? (el.firstChild as Text) : null;
      const text = node?.nodeValue?.trim() ?? '';
      if (!node || !/^\d{1,6}$/.test(text)) return;
      const end = Number(text);
      if (end < 2) return;
      const orig = node.nodeValue ?? text;
      const duration = Math.min(1400, 600 + end * 8);
      const delay = Math.min(i, 8) * 60;
      let start = 0;
      const step = (now: number) => {
        if (!start) start = now + delay;
        const t = Math.max(0, Math.min(1, (now - start) / duration));
        const eased = 1 - Math.pow(1 - t, 3);
        node.nodeValue = t >= 1 ? orig : String(Math.round(end * eased));
        if (t < 1) frames.push(requestAnimationFrame(step));
      };
      counted.push({ node, text: orig });
      node.nodeValue = '0';
      frames.push(requestAnimationFrame(step));
    });
    return () => {
      frames.forEach(cancelAnimationFrame);
      // whatever was mid-count goes back to its real value
      counted.forEach(({ node, text }) => (node.nodeValue = text));
    };
  }, []);
  return null;
}
