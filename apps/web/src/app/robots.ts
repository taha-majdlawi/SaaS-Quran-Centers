import type { MetadataRoute } from 'next';

// Search engines may read the public pages; the API and the platform console stay out.
export default function robots(): MetadataRoute.Robots {
  const root = process.env.NEXT_PUBLIC_ROOT_DOMAIN || 'bustan-alquran.com';
  const base = root.startsWith('localhost') ? `http://${root}` : `https://${root}`;
  return {
    rules: [{ userAgent: '*', allow: '/', disallow: ['/api/', '/platform'] }],
    sitemap: `${base}/sitemap.xml`,
  };
}
