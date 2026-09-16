import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { authCookieDomain } from './lib/supabase/cookie-options';

const ROOT_DOMAIN = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').toLowerCase();

// Reserved subdomains that must never be treated as a tenant slug.
const RESERVED_SUBDOMAINS = new Set(['www', 'admin', 'api', 'app']);

// Paths reachable pre-auth, as the BROWSER sees them (i.e. before the
// subdomain->path rewrite below adds the /{slug} or /platform prefix back
// on) - everything else in that scope requires a session.
const PUBLIC_TENANT_PATHS = new Set(['/', '/login', '/join', '/privacy', '/parent-consent', '/trip-consent', '/delete-account', '/support']);
const PUBLIC_PLATFORM_PATHS = new Set(['/login']);

/**
 * Three hostname shapes, one Next.js app - see docs/ARCHITECTURE.md #4.
 *
 *   bustan-alquran.com        -> marketing site               (no rewrite)
 *   admin.bustan-alquran.com  -> platform-owner console        -> /platform/*
 *   {slug}.bustan-alquran.com -> that tenant's admin dashboard -> /{slug}/*
 *
 * Also refreshes the Supabase auth session cookie on every request - required
 * by @supabase/ssr so Server Components always see an up-to-date session
 * instead of an expired one.
 */
export async function middleware(req: NextRequest) {
  const hostname = (req.headers.get('host') ?? '').toLowerCase();
  const url = req.nextUrl.clone();

  const bareHost = hostname.split(':')[0];
  const bareRoot = ROOT_DOMAIN.split(':')[0];

  const isRootDomain =
    bareHost === bareRoot || bareHost === `www.${bareRoot}` || bareHost === 'localhost';

  let response: NextResponse;
  // Which public-path allowlist applies, if any - null for the marketing
  // site and the 'api'/'app' reserved subdomains, neither of which this
  // backstop touches.
  let scope: 'platform' | 'tenant' | null = null;

  if (isRootDomain) {
    response = NextResponse.next();
  } else {
    const subdomain = bareHost.endsWith(`.${bareRoot}`)
      ? bareHost.slice(0, -(`.${bareRoot}`.length))
      : bareHost.split('.')[0]; // e.g. demo.localhost during local dev

    if (subdomain === 'admin') {
      scope = 'platform';
      url.pathname = `/platform${req.nextUrl.pathname}`;
      response = NextResponse.rewrite(url);
    } else if (RESERVED_SUBDOMAINS.has(subdomain)) {
      response = NextResponse.next();
    } else {
      scope = 'tenant';
      url.pathname = `/${subdomain}${req.nextUrl.pathname}`;
      response = NextResponse.rewrite(url);
    }
  }

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => req.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value }) => req.cookies.set(name, value));
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, { ...options, domain: authCookieDomain() }),
          );
        },
      },
    },
  );

  // Touching getUser() is what actually triggers the refresh-token exchange
  // when the access token has expired - a plain getSession() would not.
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // Defense-in-depth, not the real gate: (protected)/layout.tsx and
  // platform/(protected)/layout.tsx already independently re-verify both
  // session AND org membership/role on every request via
  // getOrgContext()/getPlatformContext(), regardless of what happens here -
  // that's what actually decides access. This only catches "no session at
  // all" one layer earlier for the small, fixed set of paths that are
  // always public, so a future route accidentally added outside
  // (protected) fails closed (redirected) instead of silently rendering
  // for a signed-out visitor. It deliberately does NOT check org
  // membership itself - that needs the DB round trip the layouts already
  // do correctly.
  if (!user && scope) {
    const isPublicPath =
      scope === 'platform'
        ? PUBLIC_PLATFORM_PATHS.has(req.nextUrl.pathname)
        : PUBLIC_TENANT_PATHS.has(req.nextUrl.pathname);
    if (!isPublicPath) {
      // Relative to the root domain the browser is actually on, same as
      // every in-app redirect to /login - see (tenant)/[org]/page.tsx's
      // comment for why this can't be `/${subdomain}/login` here.
      const redirectResponse = NextResponse.redirect(new URL('/login', req.url));
      // Carry over whatever getUser() just refreshed on `response` (e.g. a
      // cleared/rotated cookie) - returning a fresh response here would
      // otherwise drop it.
      response.cookies.getAll().forEach((cookie) => redirectResponse.cookies.set(cookie));
      return redirectResponse;
    }
  }

  // Baseline security headers on every response - clickjacking, MIME
  // sniffing, referrer leakage, and forcing HTTPS on repeat visits.
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');

  return response;
}

export const config = {
  matcher: ['/((?!_next|api|favicon.ico|.*\\..*).*)'],
};
