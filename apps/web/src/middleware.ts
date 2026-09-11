import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { authCookieDomain } from './lib/supabase/cookie-options';

const ROOT_DOMAIN = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').toLowerCase();

// Reserved subdomains that must never be treated as a tenant slug.
const RESERVED_SUBDOMAINS = new Set(['www', 'admin', 'api', 'app']);

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

  if (isRootDomain) {
    response = NextResponse.next();
  } else {
    const subdomain = bareHost.endsWith(`.${bareRoot}`)
      ? bareHost.slice(0, -(`.${bareRoot}`.length))
      : bareHost.split('.')[0]; // e.g. demo.localhost during local dev

    if (subdomain === 'admin') {
      url.pathname = `/platform${req.nextUrl.pathname}`;
      response = NextResponse.rewrite(url);
    } else if (RESERVED_SUBDOMAINS.has(subdomain)) {
      response = NextResponse.next();
    } else {
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
  await supabase.auth.getUser();

  return response;
}

export const config = {
  matcher: ['/((?!_next|api|favicon.ico|.*\\..*).*)'],
};
