import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { Flash, btn, field } from '@/components/platform-flash';
import { deleteNotice, saveNotice } from '@/lib/platform/actions';
import { fmt } from '@/lib/platform/labels';

interface Notice {
  id: string;
  title: string;
  body: string | null;
  level: string;
  is_active: boolean;
  ends_at: string | null;
  created_at: string;
}

const LEVELS: [string, string][] = [
  ['info', 'معلومة'],
  ['warning', 'تنبيه'],
  ['critical', 'عاجل'],
];

function NoticeForm({ n }: { n?: Notice }) {
  return (
    <form action={saveNotice} className="grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-3">
      {n && <input type="hidden" name="id" value={n.id} />}
      <label className="text-sm sm:col-span-2">
        العنوان
        <input name="title" required minLength={2} maxLength={120} defaultValue={n?.title} className={field} />
      </label>
      <label className="text-sm">
        المستوى
        <select name="level" defaultValue={n?.level ?? 'info'} className={field}>
          {LEVELS.map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
      </label>
      <label className="text-sm sm:col-span-3">
        النص (اختياري)
        <textarea name="body" maxLength={600} rows={2} defaultValue={n?.body ?? ''} className={field} />
      </label>
      <label className="text-sm">
        ينتهي في (اختياري)
        <input type="datetime-local" name="endsAt" defaultValue={n?.ends_at?.slice(0, 16) ?? ''} className={field} />
      </label>
      <label className="flex items-center gap-2 self-end text-sm">
        <input type="checkbox" name="active" defaultChecked={n?.is_active ?? true} /> ظاهر الآن
      </label>
      <div className="self-end">
        <SubmitButton className={btn} pendingText="...">
          {n ? 'حفظ' : 'نشر الإشعار'}
        </SubmitButton>
      </div>
    </form>
  );
}

export default async function NoticesPage({ searchParams }: { searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { ok, error } = await searchParams;
  const supabase = await createClient();
  const { data } = await supabase.rpc('platform_list_notices');
  const notices = (data ?? []) as Notice[];

  return (
    <div className="max-w-4xl">
      <h1 className="mb-1 text-2xl font-bold">إشعارات للمراكز</h1>
      <p className="mb-4 text-sm text-gray-500">شريط يظهر أعلى الويب والجوال لكل مستخدمي كل المراكز (صيانة، تحديث، تنبيه).</p>
      <Flash ok={ok} error={error} />
      <div className="flex flex-col gap-4">
        {notices.map((n) => (
          <div key={n.id}>
            <p className="mb-1 text-xs text-gray-400">نُشر {fmt(n.created_at)}</p>
            <NoticeForm n={n} />
            <form action={deleteNotice} className="mt-1 text-left">
              <input type="hidden" name="id" value={n.id} />
              <ConfirmSubmitButton confirmMessage="حذف هذا الإشعار؟" pendingText="..." className="text-xs text-red-600 hover:underline">
                حذف
              </ConfirmSubmitButton>
            </form>
          </div>
        ))}
        <h2 className="mt-2 font-semibold">إشعار جديد</h2>
        <NoticeForm />
      </div>
    </div>
  );
}
