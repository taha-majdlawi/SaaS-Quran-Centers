import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateEvent, deleteEvent, registerStudent, cancelRegistration } from '../actions';

function toDatetimeLocal(iso: string) {
  return iso.slice(0, 16);
}

export default async function EditEventPage({
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

  const [{ data: event }, { data: registrations }, { data: students }] = await Promise.all([
    supabase
      .from('center_calendar')
      .select('id, title, description, starts_at, location, requires_guardian_consent')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase
      .from('calendar_registrations')
      .select('id, status, students_profile(full_name)')
      .eq('event_id', id),
    supabase
      .from('students_profile')
      .select('id, full_name')
      .eq('organization_id', org.id)
      .eq('status', 'active')
      .order('full_name'),
  ]);

  if (!event) notFound();

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">تعديل فعالية</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={updateEvent} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={event.id} />

        <label className="text-sm font-medium text-gray-700">
          العنوان
          <input
            name="title"
            required
            defaultValue={event.title}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الوصف
          <textarea
            name="description"
            rows={3}
            defaultValue={event.description ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          التاريخ والوقت
          <input
            type="datetime-local"
            name="startsAt"
            required
            defaultValue={toDatetimeLocal(event.starts_at)}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          المكان
          <input
            name="location"
            defaultValue={event.location ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
          <input type="checkbox" name="requiresConsent" defaultChecked={event.requires_guardian_consent} />
          تحتاج موافقة ولي الأمر (رحلة مثلًا)
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      <form action={deleteEvent} className="mt-3">
        <input type="hidden" name="id" value={event.id} />
        <ConfirmSubmitButton
          confirmMessage={`متأكد إنك بدك تحذف فعالية "${event.title}"؟`}
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف الفعالية
        </ConfirmSubmitButton>
      </form>

      <div className="mt-8">
        <h2 className="mb-4 text-lg font-bold">المسجّلون ({registrations?.length ?? 0})</h2>
        <ul className="mb-4 flex flex-col gap-2 text-sm">
          {(registrations ?? []).map((r) => (
            <li key={r.id} className="flex items-center justify-between rounded border bg-white px-3 py-2">
              <span>{(r.students_profile as unknown as { full_name: string } | null)?.full_name}</span>
              <form action={cancelRegistration}>
                <input type="hidden" name="id" value={r.id} />
                <input type="hidden" name="eventId" value={event.id} />
                <SubmitButton className="text-red-600 hover:underline" pendingText="جاري الإلغاء...">
                  إلغاء
                </SubmitButton>
              </form>
            </li>
          ))}
          {!registrations?.length && <li className="text-gray-400">ما في تسجيلات بعد</li>}
        </ul>

        {Boolean(students?.length) && (
          <form action={registerStudent} className="flex flex-wrap items-end gap-3 rounded-lg border bg-white p-4 text-sm">
            <input type="hidden" name="eventId" value={event.id} />
            <label>
              تسجيل طالب
              <select name="studentId" required className="mt-1 block rounded border px-3 py-2">
                <option value="" disabled>
                  اختر الطالب
                </option>
                {(students ?? []).map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name}
                  </option>
                ))}
              </select>
            </label>
            <SubmitButton
              className="rounded bg-brand px-4 py-2 font-semibold text-white disabled:opacity-50"
              pendingText="جاري التسجيل..."
            >
              تسجيل
            </SubmitButton>
          </form>
        )}
      </div>
    </div>
  );
}
