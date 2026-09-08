import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export interface OrgContext {
  id: string;
  name: string;
  slug: string;
  primaryColor: string;
  secondaryColor: string;
  logoUrl: string | null;
  /** Caller's role in THIS organization - null if authenticated but not a member (should redirect). */
  myRole: 'student' | 'teacher' | 'admin' | 'guardian' | null;
}

/**
 * Resolves the tenant for the current request (the `[org]` route param,
 * populated by middleware.ts from the subdomain) and the caller's role in
 * it. Every page under app/(tenant)/[org]/* should call this first - RLS
 * still enforces the real boundary, this is what drives the UI.
 */
export async function getOrgContext(slug: string): Promise<OrgContext> {
  const supabase = await createClient();

  const { data: org } = await supabase
    .from('organizations')
    .select('id, name, slug, primary_color, secondary_color, logo_url')
    .eq('slug', slug)
    .single();

  if (!org) notFound();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  let myRole: OrgContext['myRole'] = null;
  if (user) {
    const { data: membership } = await supabase
      .from('organization_members')
      .select('role')
      .eq('organization_id', org.id)
      .eq('user_id', user.id)
      .eq('status', 'active')
      .maybeSingle();
    myRole = (membership?.role as OrgContext['myRole']) ?? null;
  }

  return {
    id: org.id,
    name: org.name,
    slug: org.slug,
    primaryColor: org.primary_color,
    secondaryColor: org.secondary_color,
    logoUrl: org.logo_url,
    myRole,
  };
}
