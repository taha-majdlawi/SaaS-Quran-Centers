'use client';

import { useRouter } from 'next/navigation';
import { useEffect } from 'react';

/** Re-renders the (server) conversation every few seconds while the tab is visible. */
export function ChatAutoRefresh({ everyMs = 5000 }: { everyMs?: number }) {
  const router = useRouter();
  useEffect(() => {
    const id = setInterval(() => {
      if (document.visibilityState === 'visible' && !document.activeElement?.matches('textarea, input')) router.refresh();
    }, everyMs);
    return () => clearInterval(id);
  }, [router, everyMs]);
  return null;
}
