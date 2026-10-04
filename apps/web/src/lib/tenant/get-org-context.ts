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
  /** Modules the platform switched off for this center (hidden for everyone, enforced in the DB). */
  disabledModules: string[];
  /** The platform owner looking at a center they are not a member of (support mode). */
  isPlatformOwner: boolean;
  /** Student fees are switched on (0081 - off by default, most centers are free). */
  feesEnabled: boolean;
}

/**
 * Resolves the tenant for the current request (the `[org]` route param,
 * populated by middleware.ts from the subdomain) and the caller's role in
 * it. Every page under app/(tenant)/[org]/* should call this first - RLS
 * still enforces the real boundary, this is what drives the UI.
 */
export const getOrgContext = cache(async (slug: string): Promise<OrgContext> => {
  const supabase = await createClient();

  // the org row and the session do not depend on each other - fetch them together
  const [{ data: org }, { data: { user } }] = await Promise.all([
    supabase.from('organizations').select('id, name, slug, primary_color, secondary_color, logo_url').eq('slug', slug).single(),
    supabase.auth.getUser(),
  ]);

  if (!org) notFound();

  let myRole: OrgContext['myRole'] = null;
  let myPermissions: ModuleKey[] = [];
  let isPlatformOwner = false;
  let disabledModules: string[] = [];
  let feesEnabled = false;
  if (user) {
    // one round trip instead of three: the two RPCs are only read when the
    // caller turns out to belong here (they check access themselves)
    const [{ data: membership }, { data: off }, { data: fees }] = await Promise.all([
      supabase
        .from('organization_members')
        .select('role, permissions')
        .eq('organization_id', org.id)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle(),
      supabase.rpc('disabled_modules', { p_org: org.id }),
      supabase.rpc('get_fee_settings', { p_org: org.id }),
    ]);
    myRole = (membership?.role as OrgContext['myRole']) ?? null;
    if (myRole === 'admin') {
      myPermissions = ALL_MODULE_KEYS;
    } else if (myRole === 'teacher') {
      myPermissions = ((membership?.permissions as string[] | null) ?? []).filter(
        (p): p is ModuleKey => (ALL_MODULE_KEYS as string[]).includes(p),
      );
    }

    if (!myRole) {
      // not a member: the platform owner may still open any center as its admin
      const { data: owner } = await supabase.from('platform_owners').select('user_id').eq('user_id', user.id).maybeSingle();
      if (owner) {
        isPlatformOwner = true;
        myRole = 'admin';
        myPermissions = ALL_MODULE_KEYS;
      }
    }

    if (myRole && !isPlatformOwner) {
      disabledModules = (off as string[] | null) ?? [];
      myPermissions = myPermissions.filter((p) => !disabledModules.includes(p));
    }
    if (myRole) {
      feesEnabled = (fees as { enabled?: boolean } | null)?.enabled === true;
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
    disabledModules,
    isPlatformOwner,
    feesEnabled,
  };
});
