/**
 * Whether Google is switched on in Supabase (Authentication -> Providers -> Google), from the
 * project's public auth settings: the "Continue with Google" buttons appear by themselves once
 * it is, instead of leading to Supabase's "provider is not enabled" page before. Re-read every
 * five minutes.
 */
export async function googleEnabled(): Promise<boolean> {
  try {
    const res = await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/auth/v1/settings`, {
      headers: { apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '' },
      next: { revalidate: 300 },
    });
    if (!res.ok) return false;
    const settings = (await res.json()) as { external?: Record<string, boolean> };
    return settings.external?.google === true;
  } catch {
    return false;
  }
}
