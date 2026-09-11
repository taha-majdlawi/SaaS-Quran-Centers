// Replaces Next.js's blank default 404 with the same branded look as
// error.tsx/global-error.tsx.
export default function NotFound() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
      <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-brand text-xl font-bold text-white">
          ٤٠٤
        </div>
        <h1 className="mb-2 text-xl font-bold text-gray-900">هذه الصفحة غير موجودة</h1>
        <p className="mb-6 text-sm text-gray-500">تأكد من الرابط، أو رجوع للصفحة الرئيسية.</p>
        <a
          href="https://bustan-alquran.com"
          className="block w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
        >
          الصفحة الرئيسية
        </a>
      </div>
    </main>
  );
}
