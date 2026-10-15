import { headers } from 'next/headers';
import { redirect as nextRedirect } from 'next/navigation';

const ROOT = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').toLowerCase().split(':')[0];

/**
 * redirect() for server actions, to the full address on the request's own subdomain
 * (admin.{ROOT_DOMAIN} for the owner console, {center}.{ROOT_DOMAIN} for sign-in / sign-out).
 * A relative redirect is rendered by Next through an internal request that can lose the
 * subdomain on Cloudflare (middleware.ts, x-bustan-host): "mark as fixed" on the errors page
 * ended on the 404 page. A full address skips that request - the browser opens the page itself.
 * Only a subdomain of the root domain is used (the request's own host); anything else stays relative.
 */
export async function redirect(path: string): Promise<never> {
  const h = await headers();
  const host = (h.get('x-bustan-host') || h.get('host') || '').toLowerCase();
  const bare = host.split(':')[0];
  const ours = bare.endsWith(`.${ROOT}`) || (ROOT === 'localhost' && bare.endsWith('.localhost'));
  if (!ours || !path.startsWith('/')) nextRedirect(path as never);
  const local = bare === 'localhost' || bare.endsWith('.localhost');
  const proto = h.get('x-forwarded-proto')?.split(',')[0]?.trim() || (local ? 'http' : 'https');
  nextRedirect(`${proto}://${host}${path}` as never);
}
