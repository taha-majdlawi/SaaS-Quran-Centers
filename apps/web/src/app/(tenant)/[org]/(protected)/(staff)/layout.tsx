import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { TenantSidebar } from '@/components/tenant-sidebar';

// Everything under this route group is the staff dashboard. Students and
// guardians are never meant to see it - not just because most of it is
// blank for them, but because it exposes org-wide student data (grades,
// attendance, wallets...) that RLS + the /my portal deliberately don't.
export default async function StaffLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ org: string }>;
}) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);

  if (org.myRole === 'student' || org.myRole === 'guardian') {
    redirect('/my' as never);
  }

  return (
    <div className="flex">
      <TenantSidebar role={org.myRole} permissions={org.myPermissions} feesEnabled={org.feesEnabled} />
      <div className="flex-1 p-6">{children}</div>
    </div>
  );
}
