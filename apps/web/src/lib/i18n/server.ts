import { cache } from 'react';
import { cookies, headers } from 'next/headers';
import { DEFAULT_LOCALE, I18N_READY_HEADER, LANG_OVERRIDE_HEADER, LOCALE_COOKIE, dirOf, fromAcceptLanguage, isLocale, type Locale } from './config';
import { ar, type Dictionary } from './dictionaries/ar';
import { en } from './dictionaries/en';

const DICTIONARIES: Record<Locale, Dictionary> = { ar, en };

/**
 * The language of THIS request: an explicit ?lang= (forwarded by middleware),
 * else the viewer's saved choice (cookie), else - on the marketing site only -
 * the browser's language, else Arabic. Screens not translated yet always get
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
