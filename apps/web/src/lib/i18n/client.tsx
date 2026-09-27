'use client';

import { createContext, useContext } from 'react';
import { LOCALE_COOKIE, LOCALE_NAMES, LOCALES, type Locale } from './config';
import type { Dictionary } from './dictionaries/ar';

type ClientStrings = Dictionary['client'];

const I18nContext = createContext<{ locale: Locale; t: ClientStrings } | null>(null);

/** Only the small `client` section travels to the browser; server components read the full dictionary. */
export function I18nProvider({ locale, t, children }: { locale: Locale; t: ClientStrings; children: React.ReactNode }) {
  return <I18nContext.Provider value={{ locale, t }}>{children}</I18nContext.Provider>;
}

export function useClientI18n() {
  return useContext(I18nContext);
}

/** Saves the choice for every subdomain (the auth cookies' domain rule) and reloads in that language. */
export function saveLocale(locale: Locale) {
  const root = (process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com').split(':')[0].toLowerCase();
  const domain = root === 'localhost' ? '' : `; domain=.${root}`;
  document.cookie = `${LOCALE_COOKIE}=${locale}; path=/; max-age=31536000; samesite=lax${domain}`;
  // drop a ?lang= in the URL, or it would keep overriding the new choice
  const url = new URL(window.location.href);
  url.searchParams.delete('lang');
  window.location.replace(url.toString());
}

export function LanguageSwitcher({ className = '' }: { className?: string }) {
  const ctx = useClientI18n();
  const current = ctx?.locale ?? 'ar';
  return (
    <select
      aria-label={ctx?.t.language ?? 'Language'}
      value={current}
      onChange={(e) => saveLocale(e.target.value as Locale)}
      className={`rounded-md border border-gray-200 bg-white px-2 py-1 text-xs text-gray-600 ${className}`}
    >
      {LOCALES.map((l) => (
        <option key={l} value={l}>
          {LOCALE_NAMES[l]}
        </option>
      ))}
    </select>
  );
}
