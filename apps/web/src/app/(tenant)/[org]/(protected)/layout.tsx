import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { SubmitButton } from '@/components/submit-button';
import { OrgLogo } from '@/components/org-logo';
import { signOut } from '@/lib/auth/actions';
import { createClient } from '@/lib/supabase/server';

const ROLE_LABELS: Record<string, string> = {
  admin: 'مدير',
  teacher: 'معلم',
  guardian: 'ولي أمر',
  student: 'طالب',
};

// Shell shared by the full staff dashboard (see (staff)/layout.tsx, which
// adds the sidebar and blocks student/guardian from these routes) and the
// student/guardian portal at /my. Only auth + the org header live here.
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

  // A viewing (read-only) account is told so on every page; the database refuses its writes regardless.
  const supabase = await createClient();
  const { data: access } = await supabase.rpc('my_access', { p_org: org.id });
  const viewer = (access as { is_read_only?: boolean } | null)?.is_read_only === true;

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
      <div className="flex-1">
        {viewer && (
          <div className="bg-amber-500 px-6 py-2 text-center text-sm font-semibold text-white print:hidden">
            هذا حساب عرض — البيانات للاطّلاع فقط
          </div>
        )}
        <header className="flex items-center justify-between border-b bg-white px-6 py-4 print:hidden">
          <span className="flex items-center gap-2 font-bold text-brand">
            <OrgLogo name={org.name} logoUrl={org.logoUrl} size={32} />
            {org.name}
          </span>
          <div className="flex items-center gap-4 text-sm text-gray-500">
            <span>{ROLE_LABELS[org.myRole] ?? org.myRole}</span>
            <form action={signOut}>
              <SubmitButton className="hover:text-red-600" pendingText="جاري الخروج...">
                تسجيل خروج
              </SubmitButton>
            </form>
          </div>
        </header>
        <main>{children}</main>
      </div>
    </div>
  );
}
