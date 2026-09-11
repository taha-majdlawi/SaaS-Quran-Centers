import { NextRequest, NextResponse } from 'next/server';

const ROOT_DOMAIN = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').toLowerCase();

// Reserved subdomains that must never be treated as a tenant slug.
const RESERVED_SUBDOMAINS = new Set(['www', 'admin', 'api', 'app']);

/**
 * Three hostname shapes, one Next.js app - see docs/ARCHITECTURE.md #4.
 *
 *   bustan-alquran.com        -> marketing site               (no rewrite)
 *   admin.bustan-alquran.com  -> platform-owner console        -> /platform/*
 *   {slug}.bustan-alquran.com -> that tenant's admin dashboard -> /{slug}/*
 */
export function middleware(req: NextRequest) {
  const hostname = (req.headers.get('host') ?? '').toLowerCase();
  const url = req.nextUrl.clone();

  const bareHost = hostname.split(':')[0];
  const bareRoot = ROOT_DOMAIN.split(':')[0];

  const isRootDomain =
    bareHost === bareRoot || bareHost === `www.${bareRoot}` || bareHost === 'localhost';

  if (isRootDomain) {
    return NextResponse.next();
  }

  const subdomain = bareHost.endsWith(`.${bareRoot}`)
    ? bareHost.slice(0, -(`.${bareRoot}`.length))
    : bareHost.split('.')[0]; // e.g. demo.localhost during local dev

  if (subdomain === 'admin') {
    url.pathname = `/platform${req.nextUrl.pathname}`;
    return NextResponse.rewrite(url);
  }

  if (RESERVED_SUBDOMAINS.has(subdomain)) {
    return NextResponse.next();
  }

  url.pathname = `/${subdomain}${req.nextUrl.pathname}`;
  return NextResponse.rewrite(url);
}

export const config = {
  matcher: ['/((?!_next|api|favicon.ico|.*\\..*).*)'],
};
