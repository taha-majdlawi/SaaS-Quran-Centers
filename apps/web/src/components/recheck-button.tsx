'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { RotateCcw } from 'lucide-react';

/** Runs the site's check again on a recording that has none yet (the service was busy the first time). */
export function RecheckButton({ id, label }: { id: string; label: string }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  return (
    <button
      type="button"
      disabled={busy}
      onClick={async () => {
        setBusy(true);
        await fetch('/api/recitations/check', { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ id }) }).catch(() => null);
        setBusy(false);
        router.refresh();
      }}
      className="inline-flex items-center gap-1 rounded border px-2.5 py-1 text-xs text-gray-600 hover:bg-gray-50 disabled:opacity-50"
    >
      <RotateCcw size={13} className={busy ? 'animate-spin' : ''} /> {label}
    </button>
  );
}
