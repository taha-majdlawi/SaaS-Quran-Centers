import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { authCookieDomain } from './lib/supabase/cookie-options';
import { contentSecurityPolicy, newNonce } from './lib/csp';
import { I18N_READY_HEADER, LANG_OVERRIDE_HEADER, LOCALE_COOKIE, ORG_SLUG_HEADER, isI18nReady, isLocale } from './lib/i18n/config';

const ROOT_DOMAIN = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').toLowerCase();

// Reserved subdomains that must never be treated as a tenant slug.
const RESERVED_SUBDOMAINS = new Set(['www', 'admin', 'api', 'app']);

// Paths a signed-out visitor may open, as the BROWSER sees them (before the
// subdomain -> /{slug} rewrite). Defense-in-depth only: (protected)/layout.tsx
// re-verifies session AND membership on every request; this just makes a future
// route added outside (protected) fail closed instead of rendering for anyone.
const PUBLIC_TENANT_PATHS = new Set([
  '/',
  '/login',
  '/join',
  '/privacy',
  '/support',
  '/delete-account',
  '/forgot-password',
  '/reset-password',
]);
// /verify/<serial> lets anyone check a printed certificate is genuine
const isPublicTenantPath = (p: string) => PUBLIC_TENANT_PATHS.has(p) || /^\/verify\/[A-Za-z0-9-]{1,40}$/.test(p);
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
/**
 * A Server Action that ends in redirect() is rendered by Next itself through an
 * internal fetch to the app's own origin - which drops the subdomain, so the
 * redirect target used to render as the root-domain route: the marketing page
 * after the platform login, a 404 after saving any tenant form. The original
 * host rides along on the rewritten request under this header (Next forwards
 * request headers into that internal fetch) and is honoured only when the
 * request did not itself arrive on a tenant/platform subdomain.
 */
const FORWARDED_HOST_HEADER = 'x-bustan-host';

function isSubdomainOfRoot(bareHost: string, bareRoot: string): boolean {
  return bareHost.endsWith(`.${bareRoot}`) || (bareRoot === 'localhost' && bareHost.endsWith('.localhost'));
}

export async function middleware(req: NextRequest) {
  const bareRoot = ROOT_DOMAIN.split(':')[0];
  const requestHost = (req.headers.get('host') ?? '').toLowerCase();
  const carriedHost = (req.headers.get(FORWARDED_HOST_HEADER) ?? '').toLowerCase();
  const hostname =
    carriedHost && !isSubdomainOfRoot(requestHost.split(':')[0], bareRoot) && isSubdomainOfRoot(carriedHost.split(':')[0], bareRoot)
      ? carriedHost
      : requestHost;
  const url = req.nextUrl.clone();
  // a new nonce per page: Next reads it from the request's CSP and puts it on its scripts
  const csp = contentSecurityPolicy(
    newNonce(),
    process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
    ROOT_DOMAIN,
    process.env.NODE_ENV === 'development',
  );

  const bareHost = hostname.split(':')[0];
  // ?lang=en in a link: this request renders in it, and it is remembered (cookie set below)
  const langParam = req.nextUrl.searchParams.get('lang');
  const forcedLang = isLocale(langParam) ? langParam : null;
  // What the page learns about its request: its real host (see FORWARDED_HOST_HEADER),
  // which part of the product it is, and whether it may render in the viewer's language.
  const requestHeaders = (scopeName: 'marketing' | 'tenant' | 'platform', orgSlug?: string) => {
    const headers = new Headers(req.headers);
    headers.set(FORWARDED_HOST_HEADER, hostname);
    headers.set('x-bustan-scope', scopeName);
    // the center's slug, so a page can fall back to the center's default language
    headers.delete(ORG_SLUG_HEADER);
    if (orgSlug) headers.set(ORG_SLUG_HEADER, orgSlug);
    headers.delete(I18N_READY_HEADER);
    headers.delete(LANG_OVERRIDE_HEADER);
    if (isI18nReady(scopeName)) headers.set(I18N_READY_HEADER, '1');
    if (forcedLang) headers.set(LANG_OVERRIDE_HEADER, forcedLang);
    // the path as visited (before the rewrite to /[org]/...), for the staff layout's feature gate
    headers.set('x-bustan-path', req.nextUrl.pathname);
    headers.set('content-security-policy', csp);
    return headers;
  };
  const rewriteTo = (target: URL, scopeName: 'tenant' | 'platform', orgSlug?: string) =>
    NextResponse.rewrite(target, { request: { headers: requestHeaders(scopeName, orgSlug) } });

  const isRootDomain =
    bareHost === bareRoot || bareHost === `www.${bareRoot}` || bareHost === 'localhost';

  let response: NextResponse;
  let scope: 'platform' | 'tenant' | null = null;

  if (isRootDomain) {
    response = NextResponse.next({ request: { headers: requestHeaders('marketing') } });
  } else {
    const subdomain = bareHost.endsWith(`.${bareRoot}`)
      ? bareHost.slice(0, -(`.${bareRoot}`.length))
      : bareHost.split('.')[0]; // e.g. demo.localhost during local dev

    if (subdomain === 'admin') {
      scope = 'platform';
      url.pathname = `/platform${req.nextUrl.pathname}`;
      response = rewriteTo(url, 'platform');
    } else if (RESERVED_SUBDOMAINS.has(subdomain)) {
      response = NextResponse.next({ request: { headers: requestHeaders('marketing') } });
    } else {
      scope = 'tenant';
      url.pathname = `/${subdomain}${req.nextUrl.pathname}`;
      response = rewriteTo(url, 'tenant', subdomain);
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

  if (!user && scope) {
    const isPublic =
      scope === 'platform' ? PUBLIC_PLATFORM_PATHS.has(req.nextUrl.pathname) : isPublicTenantPath(req.nextUrl.pathname);
    if (!isPublic) {
      const redirectResponse = NextResponse.redirect(new URL('/login', req.url));
      // keep whatever getUser() just refreshed (a rotated / cleared cookie)
      response.cookies.getAll().forEach((cookie) => redirectResponse.cookies.set(cookie));
      return redirectResponse;
    }
  }

  // remember a ?lang= choice for every subdomain, like the viewer's own switcher does
  if (forcedLang) {
    response.cookies.set(LOCALE_COOKIE, forcedLang, { path: '/', maxAge: 60 * 60 * 24 * 365, sameSite: 'lax', domain: authCookieDomain() });
  }

  // Baseline security headers on every response - clickjacking, MIME
  // sniffing, referrer leakage, and forcing HTTPS on repeat visits.
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(self), geolocation=()');
  response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  response.headers.set('Content-Security-Policy', csp);

  return response;
}

export const config = {
  matcher: ['/((?!_next|api|favicon.ico|.*\\..*).*)'],
};
