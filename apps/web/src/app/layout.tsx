import type { Metadata } from 'next';
import './globals.css';
import { getI18n } from '@/lib/i18n/server';
import { I18nProvider } from '@/lib/i18n/client';

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getI18n();
  return { title: t.meta.title, description: t.meta.description };
}

// lang/dir follow the viewer's language on translated screens and stay
// Arabic/RTL on the platform console (lib/i18n/config.ts isI18nReady).
export default async function RootLayout({ children }: { children: React.ReactNode }) {
  const { locale, dir, t } = await getI18n();
  return (
    <html lang={locale} dir={dir}>
      <body>
        <I18nProvider locale={locale} t={t.client}>
          {children}
        </I18nProvider>
      </body>
    </html>
  );
}
