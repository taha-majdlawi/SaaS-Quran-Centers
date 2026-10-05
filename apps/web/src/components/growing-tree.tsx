'use client';

import { useEffect, useState } from 'react';

// The garden's tree (the same drawing as the platform's video): it grows for
// as long as the visitor stays on the site - a sprout, the trunk, the branches
// one after another, the leaves, then the fruit, then a slow sway. The clock
// starts on the first page of the visit and carries over to the next pages
// (sessionStorage), so moving around never sends it back to a seed.
//
// Pure CSS animations with negative delays: no JavaScript runs while it grows.
// Small at the side on a phone, in the middle at the bottom on a large screen;
// it never takes a click (pointer-events: none).

const KEY = 'bustan_tree_t0';
const INK = '#1F3A2E';
const BARK = '#8B5A3C';
const LEAF = ['#5FA77A', '#4A9367', '#7BBF92'];
const FRUIT = '#E2A93B';

/** Seconds into the growth at which each part starts. */
const T = { trunk: 0, top: 9, branches: 14, branchStep: 16, leaves: 22, fruit: 125, fruitStep: 9, sway: 185 };

// branches: from the trunk at (100, y0) to the tip, alternating sides, lowest first
const BRANCHES: { y0: number; x: number; y: number }[] = [
  { y0: 160, x: 152, y: 132 },
  { y0: 146, x: 47, y: 120 },
  { y0: 124, x: 148, y: 100 },
  { y0: 110, x: 53, y: 88 },
  { y0: 90, x: 139, y: 70 },
  { y0: 80, x: 62, y: 62 },
];

/** A leaf pointing right from (0,0), with its middle vein. */
const LEAF_PATH = 'M0 0 C 6 -7, 17 -8, 24 0 C 17 8, 6 7, 0 0 Z';

function Leaf({ x, y, angle, fill, delay }: { x: number; y: number; angle: number; fill: string; delay: number }) {
  return (
    <g transform={`translate(${x} ${y}) rotate(${angle})`}>
      <g className="tree-pop" style={{ animationDelay: `${delay}s` }}>
        <path d={LEAF_PATH} fill={fill} stroke={INK} strokeWidth={1.4} strokeLinejoin="round" />
        <path d="M2 0 L 20 0" stroke={INK} strokeWidth={0.8} strokeLinecap="round" opacity={0.55} />
      </g>
    </g>
  );
}

/** A cluster of leaves fanned around a branch tip. */
function Cluster({ x, y, right, delay }: { x: number; y: number; right: boolean; delay: number }) {
  const base = right ? -20 : 200;
  const angles = [-70, -38, -8, 22, 52, 82].map((a) => base + (right ? a : -a));
  return (
    <g>
      {angles.map((a, i) => (
        <Leaf key={i} x={x} y={y} angle={a} fill={LEAF[i % LEAF.length]} delay={delay + i * 0.9} />
      ))}
    </g>
  );
}

function Fruit({ x, y, delay }: { x: number; y: number; delay: number }) {
  return (
    <g transform={`translate(${x} ${y})`}>
      <g className="tree-pop" style={{ animationDelay: `${delay}s` }}>
        <circle r={5.2} fill={FRUIT} stroke={INK} strokeWidth={1.4} />
        <circle cx={-1.6} cy={-1.8} r={1.4} fill="#fff" opacity={0.55} />
      </g>
    </g>
  );
}

/** A stroke that draws itself from its start: a dark outline under the bark colour. */
function Limb({ d, width, delay, duration }: { d: string; width: number; delay: number; duration: number }) {
  const style = { animationDelay: `${delay}s`, animationDuration: `${duration}s` };
  return (
    <g>
      <path d={d} pathLength={1} className="tree-draw" style={style} fill="none" stroke={INK} strokeWidth={width + 4} strokeLinecap="round" />
      <path d={d} pathLength={1} className="tree-draw" style={style} fill="none" stroke={BARK} strokeWidth={width} strokeLinecap="round" />
    </g>
  );
}

/** `corner`: the small one for the dashboards - bottom left, out of the way, under every menu. */
export function GrowingTree({ corner = false }: { corner?: boolean }) {
  const [elapsed, setElapsed] = useState<number | null>(null);

  useEffect(() => {
    let t0 = Date.now();
    try {
      const saved = Number(sessionStorage.getItem(KEY));
      if (saved > 0 && saved <= t0) t0 = saved;
      else sessionStorage.setItem(KEY, String(t0));
    } catch {
      // private mode: it simply starts again on each page
    }
    setElapsed((Date.now() - t0) / 1000);
  }, []);

  if (elapsed == null) return null; // drawn in the browser only: the time is the visitor's
  // a negative delay = "this much of it has already happened"
  const at = (s: number) => s - elapsed;

  const fruits = BRANCHES.flatMap((b, i) => {
    const dx = b.x > 100 ? -7 : 7;
    return [
      { x: b.x + dx, y: b.y + 9, i: i * 2 },
      { x: (b.x + 100) / 2 + dx, y: (b.y + b.y0) / 2 - 8, i: i * 2 + 1 },
    ];
  });

  return (
    <div
      aria-hidden
      className={
        corner
          ? 'growing-tree pointer-events-none fixed bottom-0 left-1 z-10 w-[62px] opacity-95 print:hidden sm:w-[76px]'
          : 'growing-tree pointer-events-none fixed bottom-0 left-1 z-30 w-[92px] print:hidden sm:w-[118px] lg:left-1/2 lg:w-[210px] lg:-translate-x-1/2'
      }
    >
      <svg viewBox="0 0 200 222" className="block h-auto w-full overflow-visible">
        {/* the crown sways gently once the tree is grown */}
        <g className="tree-sway" style={{ animationDelay: `${at(T.sway)}s`, transformOrigin: '100px 205px' }}>
          <Limb d="M100 208 L100 50" width={11} delay={at(T.trunk)} duration={9} />
          {BRANCHES.map((b, i) => (
            <Limb key={i} d={`M100 ${b.y0} L${b.x} ${b.y}`} width={8} delay={at(T.branches + i * T.branchStep)} duration={6} />
          ))}
          <g className="tree-pop" style={{ animationDelay: `${at(T.top + 3)}s`, transformOrigin: '100px 150px' }}>
            <circle cx={100} cy={150} r={3.6} fill="none" stroke={INK} strokeWidth={1.6} />
          </g>
          {/* the first two leaves of the sprout, at the top of the trunk */}
          <Leaf x={100} y={50} angle={-150} fill={LEAF[0]} delay={at(T.top)} />
          <Leaf x={100} y={50} angle={-30} fill={LEAF[1]} delay={at(T.top + 0.8)} />
          {BRANCHES.map((b, i) => (
            <Cluster key={i} x={b.x} y={b.y} right={b.x > 100} delay={at(T.leaves + i * T.branchStep)} />
          ))}
          {fruits.map((f) => (
            <Fruit key={f.i} x={f.x} y={f.y} delay={at(T.fruit + f.i * (T.fruitStep / 2))} />
          ))}
        </g>
        {/* the hill it stands on */}
        <path d="M-6 223 C 18 200, 60 190, 100 191 C 140 192, 182 200, 206 223 Z" fill="#9CC9A6" stroke={INK} strokeWidth={2} strokeLinejoin="round" />
        <path d="M-16 223 C 18 211, 70 204, 110 206 C 150 208, 188 212, 216 223 Z" fill="#5E9C6E" stroke={INK} strokeWidth={2} strokeLinejoin="round" />
      </svg>
    </div>
  );
}
