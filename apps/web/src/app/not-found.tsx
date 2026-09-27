import { getI18n } from '@/lib/i18n/server';

// Replaces Next.js's blank default 404 with the same branded look as
// error.tsx/global-error.tsx.
export default async function NotFound() {
  const { t } = await getI18n();
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
      <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 text-center shadow-sm">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl bg-brand text-xl font-bold text-white">
          {t.notFound.code}
        </div>
        <h1 className="mb-2 text-xl font-bold text-gray-900">{t.notFound.title}</h1>
        <p className="mb-6 text-sm text-gray-500">{t.notFound.body}</p>
        <a
          href="https://bustan-alquran.com"
          className="block w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white transition hover:opacity-90"
        >
          {t.client.home}
        </a>
      </div>
    </main>
  );
}
