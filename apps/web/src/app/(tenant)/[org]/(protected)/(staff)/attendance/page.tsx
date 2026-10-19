import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveAttendance } from './actions';
import { getI18n } from '@/lib/i18n/server';

const STATUS_OPTIONS = ['present', 'absent', 'excused', 'late'];
/** each status's colour once chosen (a radio styled as a chip, no script needed) */
const STATUS_CHIP: Record<string, string> = {
  present: 'has-[:checked]:border-green-600 has-[:checked]:bg-green-600 has-[:checked]:text-white',
  late: 'has-[:checked]:border-amber-500 has-[:checked]:bg-amber-500 has-[:checked]:text-white',
  excused: 'has-[:checked]:border-sky-600 has-[:checked]:bg-sky-600 has-[:checked]:text-white',
  absent: 'has-[:checked]:border-red-600 has-[:checked]:bg-red-600 has-[:checked]:text-white',
};

function today() {
  return new Date().toISOString().slice(0, 10);
}

export default async function AttendancePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ circleId?: string; date?: string; saved?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { circleId: pickedCircle, date, saved, error } = await searchParams;
  const sessionDate = date || today();
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const [{ data: circles }, { data: auth }] = await Promise.all([
    supabase.from('circles').select('id, name, teacher_id').eq('organization_id', org.id).order('name'),
    supabase.auth.getUser(),
  ]);
  // no circle chosen yet: open the teacher's own circle (or the first one) instead of an empty page
  const circleId =
    pickedCircle ?? ((circles ?? []).find((c) => c.teacher_id === auth.user?.id) ?? (circles ?? [])[0])?.id;

  let students: { id: string; full_name: string; student_code: string }[] = [];
  let existingByStudent = new Map<string, string>();
  let circleName = '';

  if (circleId) {
    const [{ data: circleStudents }, { data: circle }, { data: existing }] = await Promise.all([
      supabase
        .from('students_profile')
        .select('id, full_name, student_code')
        .eq('organization_id', org.id)
        .eq('circle_id', circleId)
        .order('full_name'),
      supabase.from('circles').select('name').eq('id', circleId).maybeSingle(),
      supabase
        .from('attendance')
        .select('student_id, status')
        .eq('circle_id', circleId)
        .eq('session_date', sessionDate),
    ]);

    students = circleStudents ?? [];
    circleName = circle?.name ?? '';
    existingByStudent = new Map((existing ?? []).map((a) => [a.student_id, a.status]));
  }

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold">{S.attendance.title}</h1>

      <form method="get" className="mb-6 flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4 text-sm">
        <label>
          {S.attendance.circle}
          <select name="circleId" defaultValue={circleId ?? ''} className="mt-1 block rounded border px-3 py-2">
            <option value="" disabled>
              {S.attendance.pickCircle}
            </option>
            {(circles ?? []).map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          {S.attendance.date}
          <input type="date" name="date" defaultValue={sessionDate} className="mt-1 block rounded border px-3 py-2" />
        </label>
        <button type="submit" className="rounded bg-brand px-4 py-2 font-semibold text-white">
          {S.attendance.show}
        </button>
      </form>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.attendance.saved}</p>}

      {circleId && (
        <form action={saveAttendance} className="rounded-lg border bg-white">
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="circleId" value={circleId} />
          <input type="hidden" name="sessionDate" value={sessionDate} />

          <div className="border-b p-4">
            <span className="font-semibold text-brand">{circleName}</span>
            <span className="text-sm text-gray-500"> — {sessionDate}</span>
          </div>

          <ul className="divide-y">
            {students.map((s) => (
              <li key={s.id} className="flex flex-col gap-2 px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
                <div className="min-w-0">
                  <a href={`/students/${s.id}` as never} className="font-medium text-brand hover:underline">
                    {s.full_name}
                  </a>
                  <span className="mx-2 text-xs text-gray-400" dir="ltr">{s.student_code}</span>
                </div>
                <div className="flex flex-wrap gap-1.5" role="radiogroup" aria-label={`${S.attendance.colStatus} - ${s.full_name}`}>
                  {STATUS_OPTIONS.map((opt) => (
                    <label
                      key={opt}
                      className={`cursor-pointer rounded-full border px-3 py-1.5 text-xs font-medium text-gray-600 transition-colors hover:bg-gray-50 has-[:focus-visible]:ring-2 has-[:focus-visible]:ring-brand/40 ${STATUS_CHIP[opt]}`}
                    >
                      <input
                        type="radio"
                        className="sr-only"
                        name={`status_${s.id}`}
                        value={opt}
                        defaultChecked={(existingByStudent.get(s.id) ?? 'present') === opt}
                      />
                      {S.attendance.status[opt]}
                    </label>
                  ))}
                </div>
              </li>
            ))}
            {!students.length && <li className="px-4 py-6 text-center text-gray-400">{S.attendance.noStudents}</li>}
          </ul>

          {/* pe-36: room at the end for the phone menu button (staff-nav.tsx) */}
          {students.length > 0 && (
            <div className="sticky bottom-0 border-t bg-white/95 p-4 pe-36 backdrop-blur lg:pe-4">
              <SubmitButton
                className="w-full rounded-lg bg-brand px-4 py-2.5 text-sm font-semibold text-white disabled:opacity-50 sm:w-auto"
                pendingText={S.common.saving}
              >
                {S.attendance.save}
              </SubmitButton>
            </div>
          )}
        </form>
      )}
    </div>
  );
}
