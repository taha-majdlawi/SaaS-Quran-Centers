import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { TenantSidebar } from '@/components/tenant-sidebar';
import { SubmitButton } from '@/components/submit-button';
import { signOut } from '@/lib/auth/actions';

export default async function TenantProtectedLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ org: string }>;
}) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);

  if (!org) notFound();
  // Not authenticated, or authenticated but not a member of THIS org - RLS
  // would block every query anyway, so send them to sign in rather than show
  // an empty shell.
  if (!org.myRole) redirect('/login');

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
          <div className="flex items-center gap-4 text-sm text-gray-500">
            <span>{org.myRole}</span>
            <form action={signOut}>
              <SubmitButton className="hover:text-red-600" pendingText="جاري الخروج...">
                تسجيل خروج
              </SubmitButton>
            </form>
          </div>
        </header>
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}
