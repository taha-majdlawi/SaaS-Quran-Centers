'use client';

import { useEffect, useRef } from 'react';

/** Keeps the newest message in view: put it right after the last message. */
export function ScrollToEnd({ count }: { count: number }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    ref.current?.scrollIntoView({ block: 'end' });
  }, [count]);
  return <div ref={ref} />;
}
