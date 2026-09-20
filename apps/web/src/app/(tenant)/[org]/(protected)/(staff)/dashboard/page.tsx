import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { fmtDay, pct } from '@/lib/reports/format';

interface Attention {
  serd_submitted: number;
  market_pending: number;
  deletion_pending: number;
  inactive_total: number;
  inactive_students: { id: string; name: string; circle: string | null; last_at: string | null }[];
  upcoming: { id: string; title: string; start_date: string; starts_at: string | null; registered: number; capacity: number | null }[];
  week: { recitations: number; points: number; reciting_students: number; attendance_rate: number | null };
}

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

  const { data: todayData } = await supabase.rpc('get_teacher_today', { p_org: org.id });
  const today = todayData as {
    is_working_day: boolean;
    circles: { id: string; name: string; students: number; recited: number; present: number; absent: number }[];
  } | null;

  // Admin only: what needs a decision or a call today (one RPC)
  const { data: attentionData } = org.myRole === 'admin' ? await supabase.rpc('admin_attention', { p_org: org.id }) : { data: null };
  const att = attentionData as Attention | null;
  const waiting = att
    ? [
        { label: 'سرد بانتظار الاعتماد', value: att.serd_submitted, href: '/serd?status=submitted' },
        { label: 'طلبات سوق بانتظار القرار', value: att.market_pending, href: '/market' },
      ].filter((w) => w.value > 0)
    : [];

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

      {att && (
        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <section className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">يحتاج انتباهك</h2>
            {waiting.length ? (
              <ul className="flex flex-col gap-2 text-sm">
                {waiting.map((w) => (
                  <li key={w.label}>
                    <a href={w.href as never} className="flex items-center justify-between rounded bg-amber-50 px-3 py-2 hover:bg-amber-100">
                      <span>{w.label}</span>
                      <b className="text-amber-800">{w.value}</b>
                    </a>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">لا شيء ينتظر قرارك ✓</p>
            )}
            <h3 className="mb-2 mt-5 text-sm font-semibold">
              لم يسمّعوا منذ أسبوعين {att.inactive_total > 0 && <span className="text-gray-400">({att.inactive_total})</span>}
            </h3>
            {att.inactive_students.length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {att.inactive_students.map((s) => (
                  <li key={s.id} className="flex justify-between">
                    <a href={`/students/${s.id}/report` as never} className="text-brand hover:underline">
                      {s.name}
                    </a>
                    <span className="text-xs text-gray-400">
                      {s.circle ?? '—'} · {s.last_at ? fmtDay(s.last_at) : 'لم يسمّع بعد'}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">الجميع نشط ✓</p>
            )}
          </section>

          <section className="rounded-lg border bg-white p-4">
            <h2 className="mb-3 font-semibold">هذا الأسبوع</h2>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div>
                <p className="text-gray-500">التسميعات</p>
                <p className="text-xl font-bold text-brand">{att.week.recitations}</p>
              </div>
              <div>
                <p className="text-gray-500">طلاب سمّعوا</p>
                <p className="text-xl font-bold text-brand">{att.week.reciting_students}</p>
              </div>
              <div>
                <p className="text-gray-500">النقاط</p>
                <p className="text-xl font-bold text-brand">{att.week.points}</p>
              </div>
              <div>
                <p className="text-gray-500">الحضور</p>
                <p className="text-xl font-bold text-brand">{pct(att.week.attendance_rate)}</p>
              </div>
            </div>
            <h3 className="mb-2 mt-5 text-sm font-semibold">فعاليات قادمة (7 أيام)</h3>
            {att.upcoming.length ? (
              <ul className="flex flex-col gap-1 text-sm">
                {att.upcoming.map((e) => (
                  <li key={e.id} className="flex justify-between">
                    <a href={`/calendar/${e.id}` as never} className="text-brand hover:underline">
                      {e.title}
                    </a>
                    <span className="text-xs text-gray-500">
                      {fmtDay(e.start_date)} · مسجّل {e.registered}
                      {e.capacity ? `/${e.capacity}` : ''}
                    </span>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="text-sm text-gray-500">لا فعاليات قريبة</p>
            )}
          </section>
        </div>
      )}

      {today && today.circles.length > 0 && (
        <div className="mt-8">
          <h2 className="mb-3 font-semibold">حلقاتك اليوم</h2>
          {!today.is_working_day && (
            <p className="mb-3 rounded bg-amber-50 px-3 py-2 text-sm text-amber-800">اليوم ليس من أيام الدوام في مركزك</p>
          )}
          <div className="grid gap-3 sm:grid-cols-2">
            {today.circles.map((c) => (
              <div key={c.id} className="rounded-lg border bg-white p-4">
                <p className="font-semibold">{c.name}</p>
                <p className="mt-1 text-sm text-gray-600">
                  {c.students} طالب · سمّع {c.recited} · حاضر {c.present}
                  {c.absent > 0 && ` · غائب ${c.absent}`}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
