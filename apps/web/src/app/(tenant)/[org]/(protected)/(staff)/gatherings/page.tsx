import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { submitGathering, deleteGathering } from '@/lib/gatherings/actions';

interface Row {
  id: string;
  title: string;
  activity_type_label: string | null;
  session_date: string;
  status: string;
  teacher_name?: string | null;
  total: number;
  pending?: number;
  matched: number;
  skipped: number;
}

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

/** Shared activities (trips, dhikr circles, camps): upload the attendees' names, the admin links each to a student. */
export default async function GatheringsPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const [{ data: listData }, { data: types }] = await Promise.all([
    isAdmin ? supabase.rpc('admin_list_gatherings', { p_org: org.id, p_status: null }) : supabase.rpc('my_gatherings', { p_org: org.id }),
    supabase.from('activity_types').select('id, name').eq('organization_id', org.id).order('name'),
  ]);
  const rows = (listData ?? []) as Row[];
  const today = new Date().toISOString().slice(0, 10);

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">المجالس والأنشطة المشتركة</h1>
      <p className="mb-5 text-sm text-gray-500">
        نشاط يجمع طلابًا من عدة حلقات (حلقة ذكر، مخيم، زيارة). ارفع أسماء الحاضرين كما تعرفها، ثم يربط المشرف كل اسم بملف الطالب فيُسجَّل حضوره ذلك اليوم.
      </p>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{ok}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <details className="mb-6 rounded-lg border bg-white" open={!rows.length}>
        <summary className="cursor-pointer px-4 py-3 font-semibold">رفع نشاط جديد</summary>
        <form action={submitGathering} className="flex flex-col gap-3 border-t p-4">
          <input type="hidden" name="orgId" value={org.id} />
          <label className="text-sm font-medium text-gray-700">
            اسم النشاط
            <input name="title" required maxLength={120} className={field} placeholder="مثال: رحلة الحديقة" />
          </label>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="text-sm font-medium text-gray-700">
              نوع النشاط
              <select name="type" defaultValue="" className={field}>
                <option value="">— بدون —</option>
                {(types ?? []).map((t) => (
                  <option key={t.id as string} value={t.id as string}>{t.name as string}</option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              التاريخ
              <input type="date" name="date" defaultValue={today} max={today} required className={field} />
            </label>
          </div>
          <label className="text-sm font-medium text-gray-700">
            المكان (اختياري)
            <input name="location" className={field} />
          </label>
          <label className="text-sm font-medium text-gray-700">
            الحاضرون — اسم في كل سطر
            <textarea name="names" required rows={6} className={field} placeholder={'أحمد محمد\nعمر خالد\n...'} />
          </label>
          <label className="text-sm font-medium text-gray-700">
            ملاحظات (اختياري)
            <input name="notes" className={field} />
          </label>
          <SubmitButton className="self-start rounded bg-brand px-5 py-2 text-sm text-white" pendingText="جاري الرفع...">رفع النشاط</SubmitButton>
        </form>
      </details>

      <div className="flex flex-col gap-2">
        {rows.map((g) => (
          <div key={g.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-white p-4">
            <a href={`/gatherings/${g.id}` as never} className="min-w-0 flex-1">
              <p className="font-semibold text-brand">{g.title}</p>
              <p className="text-xs text-gray-500">
                {new Date(g.session_date).toLocaleDateString('ar')}
                {g.activity_type_label ? ` · ${g.activity_type_label}` : ''}
                {g.teacher_name ? ` · ${g.teacher_name}` : ''} · {g.total} اسم · رُبط {g.matched}
                {g.skipped ? ` · تُجوهل ${g.skipped}` : ''}
              </p>
            </a>
            <span className={`rounded px-2 py-0.5 text-xs ${g.status === 'reviewed' ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-800'}`}>
              {g.status === 'reviewed' ? 'تمت المراجعة' : g.pending !== undefined ? `بانتظار الربط (${g.pending})` : 'بانتظار المشرف'}
            </span>
            {(isAdmin || g.matched + g.skipped === 0) && (
              <form action={deleteGathering}>
                <input type="hidden" name="id" value={g.id} />
                <ConfirmSubmitButton confirmMessage="حذف هذا النشاط بأسمائه؟" pendingText="..." className="rounded border border-red-200 px-3 py-1 text-xs text-red-600 hover:bg-red-50">
                  حذف
                </ConfirmSubmitButton>
              </form>
            )}
          </div>
        ))}
        {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا أنشطة مرفوعة بعد</p>}
      </div>
    </div>
  );
}
