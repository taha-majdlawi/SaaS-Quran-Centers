import type { MetadataRoute } from 'next';

// The marketing site's public pages (each center's own page lives on its subdomain).
export default function sitemap(): MetadataRoute.Sitemap {
  const root = process.env.NEXT_PUBLIC_ROOT_DOMAIN || 'bustan-alquran.com';
  const base = root.startsWith('localhost') ? `http://${root}` : `https://${root}`;
  const now = new Date();
  return [
    { url: `${base}/`, lastModified: now, changeFrequency: 'weekly', priority: 1, alternates: { languages: { ar: `${base}/?lang=ar`, en: `${base}/?lang=en` } } },
    { url: `${base}/signup`, lastModified: now, changeFrequency: 'monthly', priority: 0.8 },
    { url: `${base}/login`, lastModified: now, changeFrequency: 'yearly', priority: 0.3 },
  ];
}
