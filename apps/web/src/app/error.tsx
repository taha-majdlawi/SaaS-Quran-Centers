'use client';

// Catches any crash inside a page/layout under the root layout and shows a
// branded screen instead of Next.js's generic "Application error" message.
export default function ErrorBoundary({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
      <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-red-500 text-xl font-bold text-white">
          !
        </div>
        <h1 className="mb-2 text-xl font-bold text-gray-900">حدث خطأ غير متوقع</h1>
        <p className="mb-6 text-sm text-gray-500">نعتذر، صار في مشكلة مؤقتة. جرّب مرة ثانية.</p>
        <button
          onClick={() => reset()}
          className="w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
        >
          أعد المحاولة
        </button>
        <a href="https://bustan-alquran.com" className="mt-3 block text-sm text-gray-400 underline">
          الصفحة الرئيسية
        </a>
        {error.digest && <p className="mt-4 text-xs text-gray-300">Digest: {error.digest}</p>}
      </div>
    </main>
  );
}
