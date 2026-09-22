import { notFound, redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { updateCircle, deleteCircle, setCircleAssistants } from '../actions';

const STATUS_OPTIONS = [
  { value: 'active', label: 'نشطة' },
  { value: 'archived', label: 'مؤرشفة' },
];

interface MemberRow {
  user_id: string;
  role: string;
  full_name: string | null;
  email: string | null;
}

export default async function EditCirclePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string; ok?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error, ok } = await searchParams;
  const org = await getOrgContext(slug);
  if (org.myRole !== 'admin') redirect('/circles' as never);
  const supabase = await createClient();

  const [{ data: circle }, { data: stages }, { data: members }] = await Promise.all([
    supabase
      .from('circles')
      .select('id, name, stage_id, teacher_id, capacity, status')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase.from('stages').select('id, name').eq('organization_id', org.id).order('sort_order'),
    supabase.rpc('list_org_members', { org_id: org.id }),
  ]);

  if (!circle) notFound();

  const teachers = ((members ?? []) as MemberRow[]).filter((m) => m.role === 'teacher');
  const { data: assistData } = org.myRole === 'admin' ? await supabase.rpc('circle_assistants_list', { p_org: org.id }) : { data: [] };
  const assistantIds = new Set(((assistData ?? []) as { circle_id: string; user_id: string }[]).filter((a) => a.circle_id === id).map((a) => a.user_id));

  return (
    <div className="max-w-lg">
      <h1 className="mb-6 text-2xl font-bold">تعديل حلقة</h1>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}

      <form action={updateCircle} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="id" value={circle.id} />

        <label className="text-sm font-medium text-gray-700">
          اسم الحلقة
          <input
            name="name"
            required
            defaultValue={circle.name}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          المرحلة
          <select
            name="stageId"
            defaultValue={circle.stage_id ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="">بدون مرحلة</option>
            {(stages ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          المعلم
          <select
            name="teacherId"
            defaultValue={circle.teacher_id ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            <option value="">بدون معلم</option>
            {teachers.map((t) => (
              <option key={t.user_id} value={t.user_id}>
                {t.full_name ?? t.email}
              </option>
            ))}
          </select>
        </label>

        <label className="text-sm font-medium text-gray-700">
          السعة (عدد الطلاب)
          <input
            type="number"
            name="capacity"
            min={1}
            defaultValue={circle.capacity ?? ''}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <label className="text-sm font-medium text-gray-700">
          الحالة
          <select
            name="status"
            defaultValue={circle.status}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          >
            {STATUS_OPTIONS.map((s) => (
              <option key={s.value} value={s.value}>
                {s.label}
              </option>
            ))}
          </select>
        </label>

        <SubmitButton
          className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
          pendingText="جاري الحفظ..."
        >
          حفظ التعديلات
        </SubmitButton>
      </form>

      {org.myRole === 'admin' && (
        <form action={setCircleAssistants} className="mt-6 flex flex-col gap-2 rounded-lg border bg-white p-6">
          <input type="hidden" name="id" value={circle.id} />
          <input type="hidden" name="orgId" value={org.id} />
          <h2 className="font-semibold">المعلمون المساعدون</h2>
          <p className="text-xs text-gray-500">
            المعلم المساعد حساب معلم عادي يرث كل صلاحيات معلم هذه الحلقة عليها فقط (التسميع، الحضور، الملاحظات، المراجعة...) ويظهر بوسم «معلم مساعد».
          </p>
          {teachers.filter((t) => t.user_id !== circle.teacher_id).map((t) => (
            <label key={t.user_id} className="flex items-center gap-2 text-sm">
              <input type="checkbox" name="assistant" value={t.user_id} defaultChecked={assistantIds.has(t.user_id)} />
              {t.full_name ?? t.email}
            </label>
          ))}
          {!teachers.length && <p className="text-sm text-gray-400">لا معلمون في المركز</p>}
          <SubmitButton className="self-start rounded border px-4 py-2 text-sm text-brand hover:bg-gray-50" pendingText="...">حفظ المساعدين</SubmitButton>
        </form>
      )}

      <form action={deleteCircle} className="mt-3">
        <input type="hidden" name="id" value={circle.id} />
        <ConfirmSubmitButton
          confirmMessage={`متأكد إنك بدك تحذف حلقة "${circle.name}"؟ لا يمكن التراجع.`}
          pendingText="جاري الحذف..."
          className="rounded border border-red-200 px-4 py-2 text-sm text-red-600 hover:bg-red-50"
        >
          حذف الحلقة
        </ConfirmSubmitButton>
      </form>
    </div>
  );
}
