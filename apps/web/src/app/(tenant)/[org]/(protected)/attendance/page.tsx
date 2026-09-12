import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveAttendance } from './actions';

const STATUS_OPTIONS = [
  { value: 'present', label: 'حاضر' },
  { value: 'absent', label: 'غائب' },
  { value: 'excused', label: 'مستأذن' },
  { value: 'late', label: 'متأخر' },
];

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
  const { circleId, date, saved, error } = await searchParams;
  const sessionDate = date || today();
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: circles } = await supabase
    .from('circles')
    .select('id, name')
    .eq('organization_id', org.id)
    .order('name');

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
      <h1 className="mb-6 text-2xl font-bold">الحضور</h1>

      <form method="get" className="mb-6 flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4 text-sm">
        <label>
          الحلقة
          <select name="circleId" defaultValue={circleId ?? ''} className="mt-1 block rounded border px-3 py-2">
            <option value="" disabled>
              اختر الحلقة
            </option>
            {(circles ?? []).map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
        <label>
          التاريخ
          <input type="date" name="date" defaultValue={sessionDate} className="mt-1 block rounded border px-3 py-2" />
        </label>
        <button type="submit" className="rounded bg-brand px-4 py-2 font-semibold text-white">
          عرض
        </button>
      </form>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ الحضور بنجاح</p>}

      {circleId && (
        <form action={saveAttendance} className="rounded-lg border bg-white">
          <input type="hidden" name="orgId" value={org.id} />
          <input type="hidden" name="circleId" value={circleId} />
          <input type="hidden" name="sessionDate" value={sessionDate} />

          <div className="border-b p-4">
            <span className="font-semibold text-brand">{circleName}</span>
            <span className="text-sm text-gray-500"> — {sessionDate}</span>
          </div>

          <table className="w-full text-sm">
            <thead className="bg-gray-50 text-right">
              <tr>
                <th className="px-4 py-2">الرقم</th>
                <th className="px-4 py-2">الاسم</th>
                <th className="px-4 py-2">الحالة</th>
              </tr>
            </thead>
            <tbody>
              {students.map((s) => (
                <tr key={s.id} className="border-t">
                  <td className="px-4 py-2">{s.student_code}</td>
                  <td className="px-4 py-2">{s.full_name}</td>
                  <td className="px-4 py-2">
                    <div className="flex gap-4">
                      {STATUS_OPTIONS.map((opt) => (
                        <label key={opt.value} className="flex items-center gap-1">
                          <input
                            type="radio"
                            name={`status_${s.id}`}
                            value={opt.value}
                            defaultChecked={(existingByStudent.get(s.id) ?? 'present') === opt.value}
                          />
                          {opt.label}
                        </label>
                      ))}
                    </div>
                  </td>
                </tr>
              ))}
              {!students.length && (
                <tr>
                  <td colSpan={3} className="px-4 py-6 text-center text-gray-400">
                    لا يوجد طلاب بهذي الحلقة
                  </td>
                </tr>
              )}
            </tbody>
          </table>

          {students.length > 0 && (
            <div className="p-4">
              <SubmitButton
                className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
                pendingText="جاري الحفظ..."
              >
                حفظ الحضور
              </SubmitButton>
            </div>
          )}
        </form>
      )}
    </div>
  );
}
