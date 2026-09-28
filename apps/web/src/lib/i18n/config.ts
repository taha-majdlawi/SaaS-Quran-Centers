// Languages of the web app (docs/I18N.md). Adding one = a dictionary file +
// an entry here; the build fails until every key is translated.
export const LOCALES = ['ar', 'en'] as const;
export type Locale = (typeof LOCALES)[number];

export const DEFAULT_LOCALE: Locale = 'ar';

/** The viewer's choice - shared across every subdomain (see authCookieDomain). */
export const LOCALE_COOKIE = 'lang';

export const LOCALE_NAMES: Record<Locale, string> = { ar: 'العربية', en: 'English' };

const RTL: ReadonlySet<Locale> = new Set<Locale>(['ar']);

export const isLocale = (v: unknown): v is Locale => typeof v === 'string' && (LOCALES as readonly string[]).includes(v);

export const dirOf = (l: Locale): 'rtl' | 'ltr' => (RTL.has(l) ? 'rtl' : 'ltr');

/** "{name} is here" + { name: 'x' } -> "x is here". */
export function fmt(template: string, vars: Record<string, string | number> = {}): string {
  return template.replace(/\{(\w+)\}/g, (m, k: string) => (k in vars ? String(vars[k]) : m));
}

// ---- which screens are translated -------------------------------------------
// Every screen renders in the viewer's language except the platform owner's
// console, which stays Arabic / right-to-left by design. middleware.ts marks a
// request as translatable (header below) from this.

/** Request header set by middleware.ts on a translatable request. */
export const I18N_READY_HEADER = 'x-bustan-i18n';
/** Request header carrying an explicit ?lang= choice for this very request. */
export const LANG_OVERRIDE_HEADER = 'x-bustan-lang';
/** Request header with the center's slug on a tenant request (its default language is the fallback). */
export const ORG_SLUG_HEADER = 'x-bustan-org';

/** scope: how middleware.ts routed the request ('platform' is Arabic-only by design). */
export function isI18nReady(scope: 'marketing' | 'tenant' | 'platform'): boolean {
  return scope !== 'platform';
}

/** The browser's first choice we support - Arabic whenever the visitor lists it at all. */
export function fromAcceptLanguage(header: string | null): Locale | null {
  if (!header) return null;
  const wanted = header
    .split(',')
    .map((p) => p.trim().split(';')[0].toLowerCase().split('-')[0])
    .filter(Boolean);
  if (wanted.includes('ar')) return 'ar';
  return wanted.find(isLocale) ?? null;
}
