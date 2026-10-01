import { initOpenNextCloudflareForDev } from '@opennextjs/cloudflare';

// Baseline response headers for every route. No CSP yet on purpose: Next's
// inline bootstrap scripts need a nonce setup first, and a wrong CSP breaks
// the whole app.
const securityHeaders = [
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(), geolocation=(self)' },
  { key: 'Strict-Transport-Security', value: 'max-age=31536000; includeSubDomains' },
];

/** @type {import('next').NextConfig} */
const nextConfig = {
  typedRoutes: true,
  poweredByHeader: false,
  // which build an error report came from (the commit when built by CI)
  env: { NEXT_PUBLIC_BUILD_ID: (process.env.GITHUB_SHA ?? '').slice(0, 7) || 'local' },
  async headers() {
    return [{ source: '/:path*', headers: securityHeaders }];
  },
};

export default nextConfig;

initOpenNextCloudflareForDev();
