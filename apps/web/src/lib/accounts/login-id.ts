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

/** The auth email behind a number-style identifier in a given center. */
export function toLoginEmail(centerSlug: string, identifier: string): string {
  const id = identifier.trim().toLowerCase();
  if (isEmail(id)) return id;
  return `${id}@${centerSlug.trim().toLowerCase()}.${LOGIN_DOMAIN}`;
}
