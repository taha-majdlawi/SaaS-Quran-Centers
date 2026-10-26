'use client';

import { useEffect } from 'react';
import { useClientI18n } from '@/lib/i18n/client';
import { reportError } from '@/lib/monitoring/client';
import { PlatformLogo } from '@/components/org-logo';

// Catches any crash inside a page/layout under the root layout and shows a
// branded screen instead of Next.js's generic "Application error" message.
export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const t = useClientI18n()?.t;
  useEffect(() => reportError(error, { kind: 'error-boundary' }), [error]);
  return (
    <main className="flex min-h-screen items-center justify-center bg-page p-6">
      <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
        <div className="mx-auto mb-4 flex justify-center">
          <PlatformLogo size={56} />
        </div>
        <h1 className="mb-2 text-xl font-bold text-gray-900">{t?.errorTitle ?? 'حدث خطأ غير متوقع'}</h1>
        <p className="mb-6 text-sm text-gray-500">{t?.errorBody ?? 'نعتذر، صار في مشكلة مؤقتة. جرّب مرة ثانية.'}</p>
        <button
          onClick={() => reset()}
          className="w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
        >
          {t?.retry ?? 'أعد المحاولة'}
        </button>
        <a href="https://bustan-alquran.com" className="mt-3 block text-sm text-gray-400 underline">
          {t?.home ?? 'الصفحة الرئيسية'}
        </a>
        {error.digest && <p className="mt-4 text-xs text-gray-300">Digest: {error.digest}</p>}
      </div>
    </main>
  );
}
