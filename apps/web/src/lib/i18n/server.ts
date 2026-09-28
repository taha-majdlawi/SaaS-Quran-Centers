import { cache } from 'react';
import { cookies, headers } from 'next/headers';
import { DEFAULT_LOCALE, I18N_READY_HEADER, LANG_OVERRIDE_HEADER, LOCALE_COOKIE, ORG_SLUG_HEADER, dirOf, fromAcceptLanguage, isLocale, type Locale } from './config';
import { getPublicSite } from '@/lib/tenant/public-site';
import { ar, type Dictionary } from './dictionaries/ar';
import { en } from './dictionaries/en';

const DICTIONARIES: Record<Locale, Dictionary> = { ar, en };

/**
 * The language of THIS request: an explicit ?lang= (forwarded by middleware),
 * else the viewer's saved choice (cookie), else - on a center's subdomain - the
 * center's default language (0069), else - on the marketing site - the
 * browser's language, else Arabic. Screens not translated yet always get
 * Arabic (see isI18nReady in config.ts).
 */
export const getLocale = cache(async (): Promise<Locale> => {
  const h = await headers();
  if (h.get(I18N_READY_HEADER) !== '1') return DEFAULT_LOCALE;
  const forced = h.get(LANG_OVERRIDE_HEADER);
  if (isLocale(forced)) return forced;
  const saved = (await cookies()).get(LOCALE_COOKIE)?.value;
  if (isLocale(saved)) return saved;
  if (h.get('x-bustan-scope') === 'marketing') return fromAcceptLanguage(h.get('accept-language')) ?? DEFAULT_LOCALE;
  const slug = h.get(ORG_SLUG_HEADER);
  if (slug) {
    const site = await getPublicSite(slug).catch(() => null);
    if (isLocale(site?.default_language)) return site.default_language;
  }
  return DEFAULT_LOCALE;
});

/** Is this screen translated (so a language picker belongs on it)? */
export async function isTranslatedScreen(): Promise<boolean> {
  return (await headers()).get(I18N_READY_HEADER) === '1';
}

/** Locale, direction and the dictionary for server components and server actions. */
export async function getI18n(): Promise<{ locale: Locale; dir: 'rtl' | 'ltr'; t: Dictionary }> {
  const locale = await getLocale();
  return { locale, dir: dirOf(locale), t: DICTIONARIES[locale] };
}

/** The dashboards' strings (t.staff) - for server actions and helpers. */
export async function staffStrings(): Promise<Dictionary['staff']> {
  return (await getI18n()).t.staff;
}
