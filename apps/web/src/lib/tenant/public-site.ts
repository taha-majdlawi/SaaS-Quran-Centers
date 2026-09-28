import { cache } from 'react';
import { createClient } from '@/lib/supabase/server';

export interface PublicSite {
  name: string;
  slug: string;
  logo_url: string | null;
  primary_color: string;
  secondary_color: string;
  enabled: boolean;
  /** The center's default language (0069): 'ar' | 'en'. */
  default_language?: string;
  hero_title: string | null;
  hero_body: string | null;
  contact_email: string | null;
}

/**
 * A center's public face for a signed-out visitor: branding always, landing
 * text and contact only when the admin published the page. Goes through the
 * get_public_site RPC because anonymous table access is closed (migration 0018).
 */
export const getPublicSite = cache(async (slug: string): Promise<PublicSite | null> => {
  const supabase = await createClient();
  const { data } = await supabase.rpc('get_public_site', { p_slug: slug });
  return (data as PublicSite | null) ?? null;
});

/** Only https image links may become a logo. */
export function safeLogoUrl(value: string | null | undefined): string | null {
  const v = (value ?? '').trim();
  if (!v) return null;
  try {
    const u = new URL(v);
    return u.protocol === 'https:' && v.length <= 500 ? v : null;
  } catch {
    return null;
  }
}
