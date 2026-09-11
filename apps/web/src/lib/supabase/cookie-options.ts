const ROOT_DOMAIN = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com')
  .toLowerCase()
  .split(':')[0];

/**
 * Auth cookies must be shared across bustan-alquran.com, admin.bustan-alquran.com,
 * and every {slug}.bustan-alquran.com - a session created on one host (e.g. on
 * the root domain during signup) must carry over to another (the new tenant's
 * own subdomain right after). A leading dot makes it a parent-domain cookie.
 * Skipped for localhost, which does not support this the same way.
 */
export function authCookieDomain(): string | undefined {
  return ROOT_DOMAIN === 'localhost' ? undefined : `.${ROOT_DOMAIN}`;
}
