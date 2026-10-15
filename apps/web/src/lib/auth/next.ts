/**
 * Where a sign-in leads. `next` is the page the visitor was on when the session ran out
 * (added by middleware.ts and the protected layouts): only a path on this same site is
 * followed - never another site (//evil.com, /\evil.com, https://...).
 */
export function safeNext(value: unknown): string | null {
  const v = typeof value === 'string' ? value.trim() : '';
  if (!v.startsWith('/') || v.startsWith('//') || v.includes('\\') || v.length > 500) return null;
  if (/[\u0000-\u001f]/.test(v)) return null;
  // no point coming back to the sign-in pages themselves
  if (/^\/(login|mfa)(\/|\?|$)/.test(v)) return null;
  return v;
}

/** A role's own first page in a center: the portal for students and guardians, the dashboard for staff. */
export function homeFor(role: string | null | undefined): '/my' | '/dashboard' {
  return role === 'student' || role === 'guardian' ? '/my' : '/dashboard';
}

/** Where a member goes after signing in: back to `next` when it is a page of their own area, else their first page. */
export function destinationFor(role: string | null | undefined, next: string | null): string {
  const home = homeFor(role);
  if (!next) return home;
  // students and guardians have only the portal (/my); staff pages would send them round again
  if (home === '/my' && !/^\/my(\/|\?|$)/.test(next)) return home;
  return next;
}

/** "/login?next=<path>", or just "/login" for the home page. */
export function loginWithNext(path: string | null | undefined): string {
  const next = safeNext(path);
  return next && next !== '/' ? `/login?next=${encodeURIComponent(next)}` : '/login';
}
