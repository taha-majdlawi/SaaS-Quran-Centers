import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateSerdSession, deleteSerdSession } from '../actions';

const STATUS_OPTIONS = [
  { value: 'pending', label: 'قيد الانتظار' },
  { value: 'scheduled', label: 'مجدولة' },
  { value: 'in_progress', label: 'جارية' },
  { value: 'completed', label: 'مكتملة' },
  { value: 'cancelled', label: 'ملغاة' },
];

interface MemberRow {
  user_id: string;
  role: string;
  full_name: string | null;
  email: string | null;
}

function toLocalInputValue(iso: string | null) {
  if (!iso) return '';
  return new Date(iso).toISOString().slice(0, 16);
}

export default async function EditSerdSessionPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: session }, { data: members }] = await Promise.all([
    supabase
      .from('serd_sessions')
      .select('id, session_type, status, scheduled_at, examiner_id, overall_grade, notes, students_profile(full_name)')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  if (!session) notFound();

  const staff = ((members ?? []) as MemberRow[]).filter((m) => m.role === 'teacher' || m.role === 'admin');
  const studentName = (session.students_profile as unknown as { full_name: string } | null)?.full_name ?? '—';

  return (
    <div className="max-w-lg">
      <h1 className="mb-1 text-2xl font-bold">جلسة سرد - {studentName}</h1>
      <p className="mb-6 text-sm text-gray-500">
        {session.session_type === 'full' ? 'سرد كامل' : 'سرد جزئي'}
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateSerdSession} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={session.id} />

        <label className="text-sm font-medium text-gray-700">
          الحالة
          <select name="status" defaultValue={session.status} className="mt-1 w-full rounded border px-3 py-2 text-sm">
            {STATUS_OPTIONS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          الممتحن
          <select
            name="examinerId"
            defaultValue={session.examiner_id ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="">بدون تحديد</option>
            {staff.map((m) => (
              <option key={m.user_id} value={m.user_id}>
                {m.full_name ?? m.email}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          الموعد
          <input
            type="datetime-local"
            name="scheduledAt"
            defaultValue={toLocalInputValue(session.scheduled_at)}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          التقدير (من 10)
          <input
            type="number"
            name="overallGrade"
            min={0}
            max={10}
            step={0.5}
            defaultValue={session.overall_grade ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          ملاحظات
          <textarea
            name="notes"
            defaultValue={session.notes ?? ''}
            rows={3}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ
        </SubmitButton>
      </form>

      <form action={deleteSerdSession} className="mt-3">
        <input type="hidden" name="id" value={session.id} />
        <ConfirmSubmitButton
          confirmMessage="متأكد إنك بدك تحذف جلسة السرد هذي؟ لا يمكن التراجع."
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف الجلسة
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
