import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

interface SiteSettingsRow {
  public_site_enabled: boolean;
  hero_title: string | null;
  hero_body: string | null;
  contact_email: string | null;
}

// The redirect target is relative to the ROOT domain, not `/[org]` - the
// user's browser is on `{slug}.bustan-alquran.com`, and middleware.ts
// re-derives `org` from that hostname on every request. Redirecting to
// `/${org}/dashboard` here would make middleware prepend the slug a
// second time (`/demo/demo/dashboard`) and 404.
//
// This route also matches any single-segment path on the ROOT domain
// (e.g. bustan-alquran.com/does-not-exist) since `[org]` is a dynamic
// segment Next.js resolves regardless of hostname - middleware.ts only
// scopes it correctly for real subdomains. getOrgContext() 404s on a slug
// that isn't a real organization, so a bad root-domain path renders our
// not-found page instead of blindly redirecting into a loop.
export default async function TenantRootPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const ctx = await getOrgContext(org);

  if (ctx.myRole) {
    redirect(ctx.myRole === 'student' || ctx.myRole === 'guardian' ? '/my' : '/dashboard');
  }

  // Not a member (or not signed in at all) - the org's public info page
  // (site_settings, migration 0007) if the admin turned it on, since RLS
  // ("site_settings_select_public_or_member") already permits this read
  // for an anon/non-member caller when public_site_enabled = true.
  // middleware.ts's PUBLIC_TENANT_PATHS allowlists '/' so this route is
  // even reachable pre-auth in the first place.
  const supabase = await createClient();
  const { data: site } = await supabase
    .from('site_settings')
    .select('public_site_enabled, hero_title, hero_body, contact_email')
    .eq('organization_id', ctx.id)
    .maybeSingle<SiteSettingsRow>();

  if (!site?.public_site_enabled) {
    redirect('/login');
  }

  return (
    <div
      className="flex min-h-screen flex-col"
      style={
        {
          '--brand-primary': ctx.primaryColor,
          '--brand-secondary': ctx.secondaryColor,
        } as React.CSSProperties
      }
    >
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <div className="flex items-center gap-2">
          {ctx.logoUrl && (
            // eslint-disable-next-line @next/next/no-img-element -- arbitrary
            // admin-supplied URL, same as the protected-area header.
            <img src={ctx.logoUrl} alt="" className="h-8 w-8 rounded-full object-cover" />
          )}
          <span className="font-bold text-brand">{ctx.name}</span>
        </div>
        <a href="/login" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          تسجيل الدخول
        </a>
      </header>

      <main className="mx-auto flex max-w-2xl flex-1 flex-col items-center justify-center gap-4 px-6 py-16 text-center">
        <h1 className="text-3xl font-bold">{site.hero_title || ctx.name}</h1>
        {site.hero_body && <p className="whitespace-pre-wrap text-gray-600">{site.hero_body}</p>}
        {site.contact_email && (
          <p className="text-sm text-gray-500">
            للتواصل:{' '}
            <a href={`mailto:${site.contact_email}`} className="text-brand hover:underline" dir="ltr">
              {site.contact_email}
            </a>
          </p>
        )}
      </main>

      <footer className="border-t bg-white px-6 py-4 text-center text-xs text-gray-400">
        <a href="/privacy" className="hover:underline">
          سياسة الخصوصية
        </a>
        {' · '}
        <a href="/support" className="hover:underline">
          الدعم
        </a>
      </footer>
    </div>
  );
}
