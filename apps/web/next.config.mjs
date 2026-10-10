import { initOpenNextCloudflareForDev } from '@opennextjs/cloudflare';

// Baseline response headers for every route. The pages' Content-Security-Policy
// needs a new nonce per request, so the middleware sets it (src/lib/csp.ts).
const securityHeaders = [
  { key: 'X-Content-Type-Options', value: 'nosniff' },
  { key: 'X-Frame-Options', value: 'DENY' },
  { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
  { key: 'Permissions-Policy', value: 'camera=(), microphone=(self), geolocation=(self)' },
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

// no remote bindings locally or in CI builds: the AI binding (speech check) would need a Cloudflare token
initOpenNextCloudflareForDev({ remoteBindings: false });
