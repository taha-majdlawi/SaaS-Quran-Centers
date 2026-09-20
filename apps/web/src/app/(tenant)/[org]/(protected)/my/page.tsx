import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SURAH_NAMES } from '@/lib/quran/data';
import { SerdSummaryCard, type SerdSummary } from '@/components/serd-summary-card';

const TYPE_LABELS: Record<string, string> = {
  new_memorization: 'حفظ جديد',
  recent_review: 'مراجعة قريبة',
  distant_review: 'مراجعة بعيدة',
};

interface StudentRow {
  id: string;
  student_code: string;
  full_name: string;
}

interface Recent {
  type: string;
  surah: number;
  ayah_from: number;
  ayah_to: number;
  grade_label: string | null;
  points_awarded: number;
  created_at: string;
  notes: string | null;
}

interface Dashboard {
  linked: boolean;
  student: {
    full_name: string;
    student_code: string;
    total_points: number;
    total_parts_count: number;
    total_progress: number;
    next_plan: string | null;
    phone: string | null;
    address: string | null;
  };
  circle: { name: string; teacher: string | null; stage: string | null } | null;
  stats: {
    total_recitations: number;
    recitations_this_week: number;
    recitations_last_week: number;
    ayahs_this_week: number;
    current_streak: number;
    longest_streak: number;
    weekly_attendance_rate: number | null;
    monthly_attendance_rate: number | null;
    last_recitation_at: string | null;
  };
  recent: Recent[];
}

const fmt = (iso: string | null) => (iso ? new Date(iso).toLocaleDateString('ar') : '—');

// The entire web dashboard under (staff) is off-limits to student/guardian
// accounts (see (staff)/layout.tsx) - this is the one page they land on
// instead. All numbers come from the get_student_dashboard RPC (the same call
// the mobile home uses), which enforces access itself.
export default async function MyPortalPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: students } = await supabase
    .from('students_profile')
    .select('id, student_code, full_name')
    .eq('organization_id', org.id)
    .order('full_name');

  const rows = (students ?? []) as StudentRow[];

  if (!rows.length) {
    return (
      <div className="mx-auto max-w-lg py-16 text-center text-gray-500">
        <p>لا يوجد ملف طالب مرتبط بحسابك حاليًا في {org.name}.</p>
        <p className="mt-2 text-sm">تواصل مع إدارة المركز إذا كنت تتوقع رؤية بيانات هنا.</p>
      </div>
    );
  }

  const dashboards = await Promise.all(
    rows.map(async (s) => {
      const { data } = await supabase.rpc('get_student_dashboard', { p_org: org.id, p_student_id: s.id });
      return data as Dashboard | null;
    }),
  );

  const serdSummaries = await Promise.all(
    rows.map(async (s) => {
      const { data } = await supabase.rpc('serd_student_summary', { p_org: org.id, p_student: s.id });
      return data as SerdSummary | null;
    }),
  );

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-2xl font-bold">
          {org.myRole === 'guardian' ? 'أبناؤك في' : 'ملفك في'} {org.name}
        </h1>
        <div className="flex flex-wrap gap-2">
          <a href="/my/quran" className="rounded border px-4 py-2 text-sm text-brand">
            المصحف
          </a>
          <a href="/my/announcements" className="rounded border px-4 py-2 text-sm text-brand">
            الإعلانات
          </a>
          <a href="/my/chat" className="rounded border px-4 py-2 text-sm text-brand">
            المحادثات
          </a>
          <a href="/my/notifications" className="rounded border px-4 py-2 text-sm text-brand">
            الإشعارات
          </a>
          <a href="/my/badges" className="rounded border px-4 py-2 text-sm text-brand">
            الشارات
          </a>
          <a href="/my/market" className="rounded border px-4 py-2 text-sm text-brand">
            السوق
          </a>
          <a href="/my/report" className="rounded border px-4 py-2 text-sm text-brand">
            التقرير
          </a>
          <a href="/my/certificates" className="rounded border px-4 py-2 text-sm text-brand">
            الشهادات
          </a>
          <a href="/my/calendar" className="rounded border px-4 py-2 text-sm text-brand">
            التقويم والفعاليات
          </a>
        </div>
      </div>

      {dashboards.map((d, idx) => {
        if (!d || !d.linked) return null;
        const { student, circle, stats, recent } = d;
        const change = stats.recitations_this_week - stats.recitations_last_week;
        const weekText =
          change > 0
            ? `أفضل من الأسبوع الماضي (+${change})`
            : change < 0
              ? `أقل من الأسبوع الماضي (${change})`
              : 'ثابت مقارنة بالأسبوع الماضي';

        return (
          <div key={rows[idx].id} className="flex flex-col gap-4 rounded-lg border bg-white p-6">
            <div className="flex items-center justify-between rounded-lg bg-brand p-5 text-white">
              <div>
                <h2 className="text-lg font-bold">{student.full_name}</h2>
                <p className="text-sm opacity-85">
                  {circle ? `${circle.name}${circle.teacher ? ` · الشيخ ${circle.teacher}` : ''}` : 'لم يُسند إلى حلقة بعد'}
                </p>
                <p className="text-xs opacity-70" dir="ltr">
                  {student.student_code}
                </p>
              </div>
              <div className="text-center">
                <p className="text-3xl font-bold">{student.total_points}</p>
                <p className="text-sm opacity-85">نقطة</p>
              </div>
            </div>

            <div>
              <div className="mb-1 flex justify-between text-sm">
                <span className="font-semibold">{student.total_parts_count} من 30 جزءًا</span>
                <span>{student.total_progress}%</span>
              </div>
              <div className="h-2.5 overflow-hidden rounded bg-gray-100">
                <div
                  className="h-full bg-brand"
                  style={{ width: `${Math.min(100, (student.total_parts_count / 30) * 100)}%` }}
                />
              </div>
              {student.next_plan && (
                <p className="mt-3 rounded bg-amber-50 p-3 text-sm">خطتك القادمة: {student.next_plan}</p>
              )}
            </div>

            <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-4">
              <Stat label="آيات هذا الأسبوع" value={String(stats.ayahs_this_week)} />
              <Stat
                label="الحضور الأسبوعي"
                value={stats.weekly_attendance_rate == null ? '—' : `${stats.weekly_attendance_rate}%`}
              />
              <Stat label="إجمالي التسميعات" value={String(stats.total_recitations)} />
              <Stat label="آخر تسميع" value={fmt(stats.last_recitation_at)} />
            </div>

            <p className="text-sm text-gray-600">
              {stats.recitations_this_week} تسميعات هذا الأسبوع — {weekText} · 🔥 سلسلتك {stats.current_streak} يوم
              (أطول سلسلة {stats.longest_streak})
            </p>

            <div>
              <h3 className="mb-2 text-sm font-semibold text-gray-600">السرد القرآني</h3>
              <SerdSummaryCard summary={serdSummaries[idx]} />
            </div>

            <div>
              <h3 className="mb-2 text-sm font-semibold text-gray-600">سجل التسميع</h3>
              {recent.length ? (
                <ul className="flex flex-col gap-2 text-sm">
                  {recent.map((r, i) => (
                    <li key={i} className="rounded bg-gray-50 px-3 py-2">
                      <div className="flex justify-between">
                        <span className="font-semibold">
                          {SURAH_NAMES[r.surah - 1]} ({r.ayah_from}–{r.ayah_to})
                        </span>
                        <span className="text-brand">+{r.points_awarded}</span>
                      </div>
                      <p className="text-xs text-gray-500">
                        {TYPE_LABELS[r.type] ?? r.type} · {r.grade_label ?? '—'} · {fmt(r.created_at)}
                      </p>
                      {r.notes && <p className="mt-1 text-xs text-gray-600">{r.notes}</p>}
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="text-sm text-gray-400">لا يوجد تسميعات بعد</p>
              )}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded border bg-gray-50 p-3 text-center">
      <p className="text-lg font-bold">{value}</p>
      <p className="text-xs text-gray-500">{label}</p>
    </div>
  );
}
