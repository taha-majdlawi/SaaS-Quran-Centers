import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { giveConsent, withdrawConsent } from './actions';

const ATTENDANCE_LABELS: Record<string, string> = {
  present: 'حاضر',
  absent: 'غائب',
  excused: 'معذور',
  late: 'متأخر',
};

interface StudentRow {
  id: string;
  student_code: string;
  full_name: string;
  status: string;
}

interface WalletRow {
  student_id: string;
  balance: number;
}

interface BadgeRow {
  student_id: string;
  badge_id: string;
}

interface AttendanceRow {
  student_id: string;
  session_date: string;
  status: string;
}

interface SerdRow {
  student_id: string;
  session_type: string;
  status: string;
  scheduled_at: string | null;
}

interface EventRow {
  id: string;
  title: string;
  starts_at: string;
  location: string | null;
  requires_guardian_consent: boolean;
}

interface RegistrationRow {
  id: string;
  event_id: string;
  student_id: string;
}

// The entire web dashboard under (staff) is off-limits to student/guardian
// accounts (see (staff)/layout.tsx) - this is the one page they land on
// instead. Every table read here is already scoped by RLS to the caller's
// own linked student(s) (migration 0015), so a plain select is enough -
// there is no need to re-filter in application code.
export default async function MyPortalPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const isGuardian = org.myRole === 'guardian';
  const supabase = await createClient();

  const { data: students } = await supabase
    .from('students_profile')
    .select('id, student_code, full_name, status')
    .eq('organization_id', org.id);

  const rows = (students ?? []) as StudentRow[];

  if (!rows.length) {
    return (
      <div className="mx-auto max-w-lg py-16 text-center text-gray-500">
        <p>لا يوجد ملف طالب مرتبط بحسابك حاليًا في {org.name}.</p>
        <p className="mt-2 text-sm">تواصل مع إدارة المركز إذا كنت تتوقع رؤية بيانات هنا.</p>
        <a href="/chat" className="mt-4 inline-block text-sm text-brand hover:underline">
          المحادثات
        </a>
      </div>
    );
  }

  const studentIds = rows.map((s) => s.id);

  const { data: upcomingEvents } = await supabase
    .from('center_calendar')
    .select('id, title, starts_at, location, requires_guardian_consent')
    .eq('organization_id', org.id)
    .gte('starts_at', new Date().toISOString())
    .order('starts_at')
    .limit(5);

  const events = (upcomingEvents ?? []) as EventRow[];
  const eventIds = events.map((e) => e.id);

  const [{ data: wallets }, { data: badges }, { data: attendance }, { data: serd }, { data: registrations }] =
    await Promise.all([
    supabase.from('student_wallets').select('student_id, balance').in('student_id', studentIds),
    supabase.from('student_badges').select('student_id, badge_id').in('student_id', studentIds),
    supabase
      .from('attendance')
      .select('student_id, session_date, status')
      .in('student_id', studentIds)
      .order('session_date', { ascending: false })
      .limit(30),
    supabase
      .from('serd_sessions')
      .select('student_id, session_type, status, scheduled_at')
      .in('student_id', studentIds)
      .order('scheduled_at', { ascending: false })
      .limit(20),
    eventIds.length
      ? supabase.from('calendar_registrations').select('id, event_id, student_id').in('student_id', studentIds).in('event_id', eventIds)
      : Promise.resolve({ data: [] as RegistrationRow[] }),
  ]);

  const walletByStudent = new Map<string, number>();
  ((wallets ?? []) as WalletRow[]).forEach((w) => walletByStudent.set(w.student_id, w.balance));

  const badgeCountByStudent = new Map<string, number>();
  ((badges ?? []) as BadgeRow[]).forEach((b) =>
    badgeCountByStudent.set(b.student_id, (badgeCountByStudent.get(b.student_id) ?? 0) + 1),
  );

  const attendanceByStudent = new Map<string, AttendanceRow[]>();
  ((attendance ?? []) as AttendanceRow[]).forEach((a) => {
    const list = attendanceByStudent.get(a.student_id) ?? [];
    list.push(a);
    attendanceByStudent.set(a.student_id, list);
  });

  const serdByStudent = new Map<string, SerdRow[]>();
  ((serd ?? []) as SerdRow[]).forEach((s) => {
    const list = serdByStudent.get(s.student_id) ?? [];
    list.push(s);
    serdByStudent.set(s.student_id, list);
  });

  // Keyed `${eventId}:${studentId}` - a registration already exists (consent
  // given) for that specific student/event pair.
  const registrationByEventStudent = new Map<string, RegistrationRow>();
  ((registrations ?? []) as RegistrationRow[]).forEach((r) =>
    registrationByEventStudent.set(`${r.event_id}:${r.student_id}`, r),
  );

  // General events (no consent needed) shown once above the student cards;
  // consent-required events get an actionable per-student row inside each
  // student's own card below instead, same split as mobile's my_portal_screen.
  const generalEvents = events.filter((e) => !e.requires_guardian_consent);
  const consentEvents = events.filter((e) => e.requires_guardian_consent);

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6 p-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">
          {org.myRole === 'guardian' ? 'أبناؤك في' : 'ملفك في'} {org.name}
        </h1>
        <a href="/chat" className="rounded border px-3 py-1.5 text-sm font-medium text-brand hover:bg-brand/5">
          المحادثات
        </a>
      </div>

      {error && <p className="rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {generalEvents.length > 0 && (
        <div className="rounded-lg border bg-white p-4">
          <h2 className="mb-3 text-sm font-semibold text-gray-600">فعاليات قادمة</h2>
          <ul className="flex flex-col gap-2 text-sm">
            {generalEvents.map((e) => (
              <li key={e.id} className="flex items-center justify-between rounded bg-gray-50 px-3 py-2">
                <span>{e.title}</span>
                <span className="text-gray-500">
                  {new Date(e.starts_at).toLocaleString('ar')}
                  {e.location ? ` - ${e.location}` : ''}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}

      {rows.map((student) => {
        const studentAttendance = (attendanceByStudent.get(student.id) ?? []).slice(0, 8);
        const studentSerd = (serdByStudent.get(student.id) ?? []).slice(0, 5);
        const studentConsentEvents = consentEvents.map((e) => ({
          event: e,
          registration: registrationByEventStudent.get(`${e.id}:${student.id}`) ?? null,
        }));

        return (
          <div key={student.id} className="rounded-lg border bg-white p-6">
            <div className="mb-4 flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold">{student.full_name}</h2>
                <p className="text-sm text-gray-500" dir="ltr">
                  {student.student_code}
                </p>
              </div>
              <div className="flex gap-4 text-center text-sm">
                <div>
                  <p className="text-xl font-bold text-brand">{walletByStudent.get(student.id) ?? 0}</p>
                  <p className="text-gray-500">نقاط</p>
                </div>
                <div>
                  <p className="text-xl font-bold text-brand">{badgeCountByStudent.get(student.id) ?? 0}</p>
                  <p className="text-gray-500">شارات</p>
                </div>
              </div>
            </div>

            <div className="grid gap-6 sm:grid-cols-2">
              <div>
                <h3 className="mb-2 text-sm font-semibold text-gray-600">آخر الحضور</h3>
                {studentAttendance.length ? (
                  <ul className="flex flex-col gap-1 text-sm">
                    {studentAttendance.map((a, i) => (
                      <li key={i} className="flex justify-between rounded bg-gray-50 px-3 py-1.5">
                        <span>{a.session_date}</span>
                        <span
                          className={a.status === 'present' ? 'text-green-600' : 'text-gray-500'}
                        >
                          {ATTENDANCE_LABELS[a.status] ?? a.status}
                        </span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-gray-400">لا يوجد سجل حضور بعد</p>
                )}
              </div>

              <div>
                <h3 className="mb-2 text-sm font-semibold text-gray-600">جلسات السرد</h3>
                {studentSerd.length ? (
                  <ul className="flex flex-col gap-1 text-sm">
                    {studentSerd.map((s, i) => (
                      <li key={i} className="flex justify-between rounded bg-gray-50 px-3 py-1.5">
                        <span>{s.session_type === 'full' ? 'سرد كامل' : 'سرد جزئي'}</span>
                        <span className="text-gray-500">{s.status}</span>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-gray-400">لا توجد جلسات سرد بعد</p>
                )}
              </div>
            </div>

            {studentConsentEvents.length > 0 && (
              <div className="mt-6 border-t pt-4">
                <h3 className="mb-2 text-sm font-semibold text-gray-600">فعاليات تحتاج موافقة ولي الأمر</h3>
                <ul className="flex flex-col gap-2">
                  {studentConsentEvents.map(({ event: e, registration }) => (
                    <li
                      key={e.id}
                      className="flex items-center justify-between gap-3 rounded bg-gray-50 px-3 py-2 text-sm"
                    >
                      <div>
                        <p className="font-medium">{e.title}</p>
                        <p className="text-xs text-gray-500">
                          {new Date(e.starts_at).toLocaleString('ar')}
                          {e.location ? ` - ${e.location}` : ''}
                        </p>
                      </div>
                      {isGuardian ? (
                        registration ? (
                          <form action={withdrawConsent}>
                            <input type="hidden" name="registrationId" value={registration.id} />
                            <SubmitButton
                              className="rounded border border-red-200 px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50"
                              pendingText="..."
                            >
                              سحب الموافقة
                            </SubmitButton>
                          </form>
                        ) : (
                          <form action={giveConsent}>
                            <input type="hidden" name="eventId" value={e.id} />
                            <input type="hidden" name="studentId" value={student.id} />
                            <SubmitButton
                              className="rounded bg-brand px-3 py-1.5 text-xs font-semibold text-white"
                              pendingText="..."
                            >
                              موافقة
                            </SubmitButton>
                          </form>
                        )
                      ) : (
                        <span className={`text-xs ${registration ? 'text-green-600' : 'text-gray-400'}`}>
                          {registration ? 'تمت الموافقة' : 'بانتظار موافقة ولي الأمر'}
                        </span>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
