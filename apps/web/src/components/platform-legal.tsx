import { getI18n } from '@/lib/i18n/server';
import { LanguageSwitcher } from '@/lib/i18n/client';
import type { LegalDoc } from '@/lib/legal/platform';

/** The platform's privacy policy / terms (lib/legal/platform.ts): Arabic, or English for the other languages. */
export async function PlatformLegal({ docs }: { docs: Record<'ar' | 'en', LegalDoc> }) {
  const { locale, t } = await getI18n();
  const lang = locale === 'ar' ? 'ar' : 'en';
  const doc = docs[lang];
  return (
    <div className="flex min-h-screen flex-col bg-[#FBFAF6]">
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <a href="/" className="flex items-center gap-2 font-bold text-brand">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand text-white">ب</span>
          {t.common.brand}
        </a>
        <LanguageSwitcher />
      </header>
      <main lang={lang} dir={lang === 'ar' ? 'rtl' : 'ltr'} className="mx-auto w-full max-w-2xl flex-1 px-6 py-12">
        <h1 className="text-2xl font-bold">{doc.title}</h1>
        <p className="mt-1 text-xs text-gray-400">{doc.updated}</p>
        <p className="mt-6 text-sm leading-7 text-gray-700">{doc.intro}</p>
        {doc.sections.map((s) => (
          <section key={s.heading} className="mt-6">
            <h2 className="mb-2 font-semibold text-gray-900">{s.heading}</h2>
            {s.body.map((p) => (
              <p key={p} className="mb-2 text-sm leading-7 text-gray-700">
                {p}
              </p>
            ))}
          </section>
        ))}
        <p className="mt-10 flex gap-4 border-t pt-4 text-sm">
          <a href="/privacy" className="text-brand hover:underline">{lang === 'ar' ? 'سياسة الخصوصية' : 'Privacy Policy'}</a>
          <a href="/terms" className="text-brand hover:underline">{lang === 'ar' ? 'شروط الاستخدام' : 'Terms of Use'}</a>
        </p>
      </main>
    </div>
  );
}
