import type { Metadata, Viewport } from 'next';
import './globals.css';
import { getI18n } from '@/lib/i18n/server';
import { I18nProvider } from '@/lib/i18n/client';

export async function generateMetadata(): Promise<Metadata> {
  const { t } = await getI18n();
  const root = process.env.NEXT_PUBLIC_ROOT_DOMAIN || 'bustan-alquran.com';
  return {
    metadataBase: new URL(root.startsWith('localhost') ? `http://${root}` : `https://${root}`),
    title: t.meta.title,
    description: t.meta.description,
    appleWebApp: { capable: true, title: t.meta.title, statusBarStyle: 'default' },
    // the card WhatsApp / social apps show when a link is shared
    openGraph: { title: t.meta.title, description: t.meta.description, siteName: t.meta.title, type: 'website', images: [{ url: '/icons/icon-512.png', width: 512, height: 512 }] },
    twitter: { card: 'summary', title: t.meta.title, description: t.meta.description, images: ['/icons/icon-512.png'] },
  };
}

// the installed web app's status bar / browser chrome in the brand green
export const viewport: Viewport = { themeColor: '#1E7A54', width: 'device-width', initialScale: 1 };

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
