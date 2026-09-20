import { cache } from 'react';
import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { ALL_MODULE_KEYS, type ModuleKey } from '@/lib/permissions/modules';

export interface OrgContext {
  id: string;
  name: string;
  slug: string;
  primaryColor: string;
  secondaryColor: string;
  logoUrl: string | null;
  /** Caller's role in THIS organization - null if authenticated but not a member (should redirect). */
  myRole: 'student' | 'teacher' | 'admin' | 'guardian' | null;
  /**
   * Dashboard modules the caller may use. Admins always get every module;
   * teachers get whatever the admin granted them (organization_members.permissions);
   * students/guardians get none - they use the /my portal instead, which
   * isn't gated by this list.
   */
  myPermissions: ModuleKey[];
}

/**
 * Resolves the tenant for the current request (the `[org]` route param,
 * populated by middleware.ts from the subdomain) and the caller's role in
 * it. Every page under app/(tenant)/[org]/* should call this first - RLS
 * still enforces the real boundary, this is what drives the UI.
 */
export const getOrgContext = cache(async (slug: string): Promise<OrgContext> => {
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
  let myPermissions: ModuleKey[] = [];
  if (user) {
    const { data: membership } = await supabase
      .from('organization_members')
      .select('role, permissions')
      .eq('organization_id', org.id)
      .eq('user_id', user.id)
      .eq('status', 'active')
      .maybeSingle();
    myRole = (membership?.role as OrgContext['myRole']) ?? null;
    if (myRole === 'admin') {
      myPermissions = ALL_MODULE_KEYS;
    } else if (myRole === 'teacher') {
      myPermissions = ((membership?.permissions as string[] | null) ?? []).filter(
        (p): p is ModuleKey => (ALL_MODULE_KEYS as string[]).includes(p),
      );
    }
  }

  return {
    id: org.id,
    name: org.name,
    slug: org.slug,
    primaryColor: org.primary_color,
    secondaryColor: org.secondary_color,
    logoUrl: org.logo_url,
    myRole,
    myPermissions,
  };
});
