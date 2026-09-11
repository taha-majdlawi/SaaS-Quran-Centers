import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { TenantSidebar } from '@/components/tenant-sidebar';

export default async function TenantLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ org: string }>;
}) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);

  // TODO once auth is wired: redirect to /login if org.myRole is null.
  if (!org) notFound();

  return (
    <div
      className="flex min-h-screen"
      style={
        {
          '--brand-primary': org.primaryColor,
          '--brand-secondary': org.secondaryColor,
        } as React.CSSProperties
      }
    >
      <TenantSidebar />
      <div className="flex-1">
        <header className="flex items-center justify-between border-b bg-white px-6 py-4">
          <span className="font-bold text-brand">{org.name}</span>
          <span className="text-sm text-gray-500">{org.myRole ?? 'زائر'}</span>
        </header>
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
