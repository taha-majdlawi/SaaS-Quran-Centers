/**
 * Self sign-up with "Confirm email" on: the visitor's choice (the new center, or the
 * invitation being accepted) rides in the account's user_metadata until the address is
 * confirmed, then /confirm finishes it (app/(marketing)/confirm). With confirmation off,
 * signUp returns a session and the forms finish at once, as before.
 */

export const RESERVED_SLUGS = new Set(['www', 'admin', 'api', 'app', 'platform']);
export const SLUG_PATTERN = /^[a-z0-9]+(-[a-z0-9]+)*$/;

export const validSlug = (slug: string) => SLUG_PATTERN.test(slug) && slug.length <= 63 && !RESERVED_SLUGS.has(slug);

/** What waits in user_metadata for the confirmation link. */
export interface PendingSignup {
  pending_org_name?: string | null;
  pending_org_slug?: string | null;
  pending_invite?: string | null;
}

/** The product's own address (http only for a local run). */
export function productUrl(path: string, subdomain?: string): string {
  const root = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').toLowerCase();
  const scheme = /^localhost(:|$)/.test(root) ? 'http' : 'https';
  return `${scheme}://${subdomain ? `${subdomain}.` : ''}${root}${path}`;
}

/** Where the confirmation email's link lands (the template builds it from the Site URL too). */
export const confirmUrl = () => productUrl('/confirm');

/** The cookie that carries a new center's name and link across the Google round-trip (lib/auth/google.ts). */
export const PENDING_ORG_COOKIE = 'bustan-pending-org';

/**
 * signUp() for an email that already has an account: with "Confirm email" on, Supabase answers
 * as if it worked (so nobody can probe which emails are registered) but creates nothing and sends
 * no email - the user it returns has no identities. Said plainly here instead of "check your email".
 */
export function isExistingAccount(user: { identities?: unknown[] | null } | null | undefined): boolean {
  return !!user && Array.isArray(user.identities) && user.identities.length === 0;
}
