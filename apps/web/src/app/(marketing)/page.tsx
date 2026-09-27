import type { Metadata } from 'next';
import { getI18n } from '@/lib/i18n/server';
import { LanguageSwitcher } from '@/lib/i18n/client';
import { LOCALES } from '@/lib/i18n/config';

// Replaces the legacy static index.html marketing page from
// wep-eqraa-center - but now markets the SaaS platform itself (sign up
// your center), not one specific center. A tenant's own public page (the
// old per-center "site_settings" concept) lives instead at
// app/(tenant)/[org]/(public)/page.tsx once built out.

// search engines index every language version (?lang= also renders directly in it)
export const metadata: Metadata = {
  alternates: { languages: Object.fromEntries(LOCALES.map((l) => [l, `/?lang=${l}`])) },
};

export default async function MarketingHomePage() {
  const { t } = await getI18n();
  return (
    <div className="min-h-screen bg-white">
      <header className="flex items-center justify-between border-b px-6 py-4">
        <span className="text-lg font-bold text-brand">{t.common.brand}</span>
        <nav className="flex items-center gap-4 text-sm">
          <LanguageSwitcher />
          <a href="/login" className="text-gray-600 hover:text-brand">
            {t.common.login}
          </a>
          <a href="/signup" className="rounded-lg bg-brand px-4 py-2 font-semibold text-white hover:opacity-90">
            {t.common.registerCenter}
          </a>
        </nav>
      </header>

      <main className="mx-auto flex max-w-3xl flex-col items-center gap-6 px-8 py-20 text-center">
        <h1 className="text-4xl font-bold text-brand">{t.marketing.heroTitle}</h1>
        <p className="text-lg text-gray-600">{t.marketing.heroBody}</p>
        <a href="/signup" className="rounded-lg bg-brand px-6 py-3 font-semibold text-white transition hover:opacity-90">
          {t.common.registerCenterNow}
        </a>

        <div className="mt-12 grid gap-6 text-start sm:grid-cols-3">
          {t.marketing.steps.map((step) => (
            <div key={step.title} className="rounded-xl border border-gray-100 p-5">
              <h2 className="mb-2 font-bold text-brand">{step.title}</h2>
              <p className="text-sm text-gray-600">{step.body}</p>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
