import { headers } from 'next/headers';
import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { TenantSidebar, featureOf } from '@/components/tenant-sidebar';
import { getI18n } from '@/lib/i18n/server';

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

  // A feature the platform owner switched off for this center is closed to
  // everyone here (the database already refuses its data); a link typed in by
  // hand gets a clear note instead of an empty page.
  const first = ((await headers()).get('x-bustan-path') ?? '').split('/').filter(Boolean)[0] ?? '';
  const feature = featureOf(first);
  const off = !!feature && org.disabledModules.includes(feature);

  return (
    <div className="flex items-start">
      <TenantSidebar role={org.myRole} permissions={org.myPermissions} feesEnabled={org.feesEnabled} disabledModules={org.disabledModules} />
      <div className="min-w-0 flex-1 p-4 pb-24 sm:p-6 lg:pb-6">
        {off ? (
          <p className="mx-auto mt-10 max-w-md rounded-lg border bg-white p-6 text-center text-sm text-gray-600">{(await getI18n()).t.staff.common.featureOff}</p>
        ) : (
          children
        )}
      </div>
    </div>
  );
}
