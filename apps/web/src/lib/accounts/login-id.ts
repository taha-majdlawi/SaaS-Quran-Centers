// Login identity shared by the web login, the account API and the mobile app
// (mobile mirrors this rule in features/auth/login_repository.dart).
//
// eqraa logs students/teachers in with an ID NUMBER + password, using a
// virtual email `{number}@eqraa.com` behind the scenes. Bustan is multi-tenant,
// so the virtual email carries the CENTER CODE too - the same number can
// exist in two centers without colliding. People who do have a real email
// may still sign in with it.
export const LOGIN_DOMAIN = 'id.bustan-alquran.com';

export function isEmail(value: string): boolean {
  return value.includes('@');
}

/** An account that signs in with a number has a made-up address that receives no mail. */
export function hasRealEmail(email: string | null | undefined): boolean {
  return !!email && !email.toLowerCase().endsWith(`.${LOGIN_DOMAIN}`);
}

/** Arabic-Indic (٠-٩) and Persian (۰-۹) digits - an Arabic keyboard's - become 0-9. */
export function latinDigits(value: string): string {
  return value
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x06f0));
}

/**
 * The auth email behind a number-style identifier in a given center. The number is the same
 * whichever digits were typed: "١٢٣" on an Arabic keyboard is the account made as "123".
 */
export function toLoginEmail(centerSlug: string, identifier: string): string {
  const id = identifier.trim().toLowerCase();
  if (isEmail(id)) return id;
  return `${latinDigits(id)}@${centerSlug.trim().toLowerCase()}.${LOGIN_DOMAIN}`;
}

/**
 * The address the same identifier gave before digits were made Latin, when it differs - an account
 * made then with Arabic digits in its number still signs in. Null when there is no such address.
 */
export function legacyLoginEmail(centerSlug: string, identifier: string): string | null {
  const id = identifier.trim().toLowerCase();
  if (isEmail(id) || latinDigits(id) === id) return null;
  return `${id}@${centerSlug.trim().toLowerCase()}.${LOGIN_DOMAIN}`;
}
