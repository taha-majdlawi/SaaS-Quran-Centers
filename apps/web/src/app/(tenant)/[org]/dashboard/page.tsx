import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

// Replaces wep-eqraa-center/admin/dashboard - same KPI-counter idea, now
// scoped by organization_id via RLS instead of "the one Supabase project".
export default async function DashboardPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ count: studentCount }, { count: teacherCount }, { count: circleCount }] = await Promise.all([
    supabase
      .from('students_profile')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', org.id),
    supabase
      .from('organization_members')
      .select('*', { count: 'exact', head: true })
      .eq('organization_id', org.id)
      .eq('role', 'teacher'),
    supabase.from('circles').select('*', { count: 'exact', head: true }).eq('organization_id', org.id),
  ]);

  const stats = [
    { label: 'الطلاب', value: studentCount ?? 0 },
    { label: 'المعلمون', value: teacherCount ?? 0 },
    { label: 'الحلقات', value: circleCount ?? 0 },
  ];

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">لوحة التحكم</h1>
      <div className="grid grid-cols-3 gap-4">
        {stats.map((s) => (
          <div key={s.label} className="rounded-lg border bg-white p-6">
            <p className="text-sm text-gray-500">{s.label}</p>
            <p className="text-3xl font-bold text-brand">{s.value}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
