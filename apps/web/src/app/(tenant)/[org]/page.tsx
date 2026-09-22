import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { OrgLogo } from '@/components/org-logo';
import { getPublicSite } from '@/lib/tenant/public-site';

// The redirect target is relative to the ROOT domain, not `/[org]` - the
// user's browser is on `{slug}.bustan-alquran.com`, and middleware.ts
// re-derives `org` from that hostname on every request. Redirecting to
// `/${org}/dashboard` here would make middleware prepend the slug a
// second time and 404.
//
// Members go straight to their area. Anyone else sees the center's public
// page if the admin turned it on (identity + intro + contact), otherwise the
// sign-in screen. getOrgContext() 404s on a slug that is not a real center.
// `?preview=1` (linked from the site settings page) lets a signed-in admin
// see the page a logged-out visitor gets, without signing out first.
export default async function TenantRootPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ preview?: string }> }) {
  const { org } = await params;
  const { preview } = await searchParams;
  const ctx = await getOrgContext(org);

  if (ctx.myRole && preview !== '1') redirect(ctx.myRole === 'student' || ctx.myRole === 'guardian' ? '/my' : '/dashboard');

  const site = await getPublicSite(org);
  if (!site?.enabled) {
    if (preview === '1') redirect(('/site?error=' + encodeURIComponent('الصفحة العامة موقوفة حاليًا — فعّلها أولًا من هذه الشاشة')) as never);
    redirect('/login' as never);
  }

  return (
    <div
      className="flex min-h-screen flex-col"
      style={{ '--brand-primary': site.primary_color, '--brand-secondary': site.secondary_color } as React.CSSProperties}
    >
      {preview === '1' && (
        <div className="bg-amber-100 px-4 py-2 text-center text-xs text-amber-800">
          معاينة — هذا ما يراه زائر غير مسجّل الدخول. <a href="/site" className="underline">رجوع للإعدادات</a>
        </div>
      )}
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <div className="flex items-center gap-2 font-bold text-brand">
          <OrgLogo name={site.name} logoUrl={site.logo_url} size={36} />
          {site.name}
        </div>
        <a href="/login" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          تسجيل الدخول
        </a>
      </header>

      <main className="mx-auto flex max-w-2xl flex-1 flex-col items-center justify-center gap-5 px-6 py-16 text-center">
        <OrgLogo name={site.name} logoUrl={site.logo_url} size={88} />
        <h1 className="text-3xl font-bold">{site.hero_title || site.name}</h1>
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

      <footer className="border-t bg-white px-6 py-4 text-center text-xs text-gray-500">
        <a href="/privacy" className="hover:underline">
          الخصوصية
        </a>
        {' · '}
        <a href="/support" className="hover:underline">
          الدعم
        </a>
        {' · '}
        <a href="/delete-account" className="hover:underline">
          حذف الحساب
        </a>
      </footer>
    </div>
  );
}
