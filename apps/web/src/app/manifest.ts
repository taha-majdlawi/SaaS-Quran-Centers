import type { MetadataRoute } from 'next';

// Makes the web app installable ("Add to home screen" / desktop install) on
// the marketing site and on every center's subdomain - a center's staff and
// families can keep it as an app even without the store app. Paths with a dot
// skip middleware.ts, so this one file serves every subdomain.
export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'بستان القرآن',
    short_name: 'بستان القرآن',
    description: 'منصة لإدارة مراكز تحفيظ القرآن الكريم — Quran memorization center management',
    start_url: '/',
    scope: '/',
    display: 'standalone',
    orientation: 'portrait',
    dir: 'rtl',
    lang: 'ar',
    background_color: '#FBF8F1',
    theme_color: '#1E7A54',
    categories: ['education', 'productivity'],
    icons: [
      { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
      { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
      { src: '/icons/maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
    ],
  };
}
