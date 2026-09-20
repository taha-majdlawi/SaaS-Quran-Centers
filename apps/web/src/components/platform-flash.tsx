import { OK_MESSAGES } from '@/lib/platform/labels';

export function Flash({ ok, error }: { ok?: string; error?: string }) {
  return (
    <>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK_MESSAGES[ok] ?? 'تم'}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
    </>
  );
}

export const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';
export const btn = 'rounded bg-gray-900 px-4 py-2 text-sm font-semibold text-white disabled:opacity-50';
export const btnGhost = 'rounded border px-3 py-1.5 text-sm hover:bg-gray-50';
