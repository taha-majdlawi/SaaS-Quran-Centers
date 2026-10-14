/**
 * The Content-Security-Policy of every page, set by the middleware with a new
 * nonce per request. Next reads the nonce back from the request's header and
 * puts it on its own scripts; 'strict-dynamic' lets those load the rest of the
 * app, so a script injected into a page (XSS) does not run.
 *
 * - connect: the app itself and Supabase (REST, Storage, and wss for Realtime)
 * - img/media: Supabase Storage (named: a local run is http), any https source (center logos, reciters' audio from several
 *   hosts) plus blob:/data: (the recording heard before upload, previews)
 * - Google sign-in (Google Identity Services on /google): its script, button styles, frames and calls
 * - form-action: the product's own subdomains only
 * - 'unsafe-eval' only for the dev server (dev = true)
 * - style 'unsafe-inline': React's style attributes need it; styles cannot run code
 */
const GOOGLE = 'https://accounts.google.com';

export function contentSecurityPolicy(nonce: string, supabaseUrl: string, rootDomain: string, dev = false): string {
  let supabase = '';
  let storage = '';
  try {
    const u = new URL(supabaseUrl);
    storage = u.origin;
    supabase = `${u.origin} ${u.protocol === 'http:' ? 'ws:' : 'wss:'}//${u.host}`;
  } catch {
    // no Supabase URL: only the app itself
  }
  // a form may land on another subdomain of the product (sign-up -> the new center)
  // local runs (localhost) are plain http
  const local = /^localhost(:|$)/.test(rootDomain);
  const scheme = local ? 'http' : 'https';
  const product = `${scheme}://${rootDomain} ${scheme}://*.${rootDomain}`;
  const directives = [
    `default-src 'self'`,
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'${dev ? " 'unsafe-eval'" : ''}`,
    `style-src 'self' 'unsafe-inline' ${GOOGLE}/gsi/style`,
    `img-src 'self' data: blob: https: ${storage}`.trim(),
    `media-src 'self' data: blob: https: ${storage}`.trim(),
    `font-src 'self' data:`,
    ['connect-src', "'self'", supabase, `${GOOGLE}/gsi/`].filter(Boolean).join(' '),
    `frame-src ${GOOGLE}/gsi/`,
    `worker-src 'self' blob:`,
    `object-src 'none'`,
    `base-uri 'self'`,
    `form-action 'self' ${product}`,
    `frame-ancestors 'none'`,
    ...(local ? [] : ['upgrade-insecure-requests']),
  ];
  return directives.join('; ');
}

/** 128 random bits, base64. */
export function newNonce(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(16));
  return btoa(String.fromCharCode(...bytes));
}
