'use client';

import './globals.css';
import { useEffect } from 'react';
import { reportError } from '@/lib/monitoring/client';

const TEXT = {
  ar: { title: 'حدث خطأ غير متوقع', body: 'نعتذر، صار في مشكلة مؤقتة. جرّب مرة ثانية.', retry: 'أعد المحاولة', home: 'الصفحة الرئيسية' },
  en: { title: 'Something went wrong', body: 'Sorry, there was a temporary problem. Please try again.', retry: 'Try again', home: 'Home' },
};

// Catches a crash in the root layout itself (rare, but if it happens this
// replaces the ENTIRE document - hence its own <html>/<body>) with the same
// branded screen as error.tsx instead of Next.js's generic message.
export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  // no layout (and so no I18nProvider) here: the saved choice comes straight from the cookie
  useEffect(() => reportError(error, { kind: 'global-error' }), [error]);
  const en = typeof document !== 'undefined' && /(?:^|; )lang=en(?:;|$)/.test(document.cookie);
  const t = en ? TEXT.en : TEXT.ar;
  return (
    <html lang={en ? 'en' : 'ar'} dir={en ? 'ltr' : 'rtl'}>
      <body>
        <main className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
          <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
            <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-red-500 text-xl font-bold text-white">
              !
            </div>
            <h1 className="mb-2 text-xl font-bold text-gray-900">{t.title}</h1>
            <p className="mb-6 text-sm text-gray-500">{t.body}</p>
            <button
              onClick={() => reset()}
              className="w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
            >
              {t.retry}
            </button>
            <a href="https://bustan-alquran.com" className="mt-3 block text-sm text-gray-400 underline">
              {t.home}
            </a>
            {error.digest && <p className="mt-4 text-xs text-gray-300">Digest: {error.digest}</p>}
          </div>
        </main>
      </body>
    </html>
  );
}
