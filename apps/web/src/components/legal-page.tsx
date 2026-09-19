import { OrgLogo } from '@/components/org-logo';
import { getPublicSite } from '@/lib/tenant/public-site';

/**
 * Shared chrome for the public pages every center needs (privacy, support,
 * account deletion): reachable without signing in, in the center's own identity.
 */
export async function LegalPage({
  orgSlug,
  title,
  children,
}: {
  orgSlug: string;
  title: string;
  children: (site: { name: string; contactEmail: string | null }) => React.ReactNode;
}) {
  const site = await getPublicSite(orgSlug);
  const name = site?.name ?? 'بستان القرآن';

  return (
    <div
      className="flex min-h-screen flex-col"
      style={
        {
          '--brand-primary': site?.primary_color,
          '--brand-secondary': site?.secondary_color,
        } as React.CSSProperties
      }
    >
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <a href="/" className="flex items-center gap-2 font-bold text-brand">
          <OrgLogo name={name} logoUrl={site?.logo_url} size={32} />
          {name}
        </a>
        <a href="/login" className="text-sm text-brand hover:underline">
          تسجيل الدخول
        </a>
      </header>
      <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-4 px-6 py-12">
        <h1 className="text-2xl font-bold">{title}</h1>
        <div className="flex flex-col gap-3 text-sm leading-7 text-gray-700">{children({ name, contactEmail: site?.contact_email ?? null })}</div>
      </main>
    </div>
  );
}
