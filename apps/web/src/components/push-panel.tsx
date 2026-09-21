import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { sendTestPush } from '@/lib/privacy/push-actions';

const ROLES: Record<string, string> = { admin: 'مدير', teacher: 'معلم', guardian: 'ولي أمر', student: 'طالب' };

interface PushStatus {
  configured: boolean;
  my_id: string;
  members: number;
  registered: { user_id: string; name: string | null; role: string; devices: number }[];
}

/** Admin's view of push delivery: who has a registered phone, and a test message to any of them. */
export async function PushPanel({ orgId, sent, error }: { orgId: string; sent?: string; error?: string }) {
  const supabase = await createClient();
  const { data } = await supabase.rpc('push_status', { p_org: orgId });
  const s = data as PushStatus | null;
  if (!s) return null;

  return (
    <section className="mb-6 max-w-2xl rounded-lg border bg-white p-5">
      <h2 className="mb-1 font-semibold">الإشعارات الفورية على الهاتف</h2>
      <p className="mb-3 text-xs text-gray-500">
        تصل للجميع على هواتفهم حتى والتطبيق مغلق: الرسائل، الإعلانات، تذكير الفعاليات، الملخص الأسبوعي، اعتماد السرد، طلبات السوق. يُسجَّل الهاتف عند أول دخول للتطبيق ومنح إذن الإشعارات، ويستطيع كل شخص كتم أي نوع من إعدادات الإشعارات.
      </p>
      {sent && <p className="mb-3 rounded bg-green-50 px-3 py-2 text-sm text-green-700">أُرسل إشعار تجريبي إلى {sent} جهاز — راقب الهاتف خلال ثوانٍ</p>}
      {error && <p className="mb-3 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <p className={`mb-3 rounded px-3 py-2 text-sm ${s.configured ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-800'}`}>
        {s.configured ? 'الخدمة مفعّلة على المنصة' : 'الخدمة غير مفعّلة على المنصة بعد'} · سجّلت هواتفها {s.registered.length} من {s.members} عضو
      </p>
      {s.registered.length ? (
        <ul className="divide-y rounded border text-sm">
          {s.registered.map((r) => (
            <li key={r.user_id} className="flex items-center justify-between gap-2 px-3 py-2">
              <span>
                {r.name ?? '—'} <span className="text-xs text-gray-400">({ROLES[r.role] ?? r.role}{r.user_id === s.my_id ? ' — أنت' : ''}) · {r.devices} جهاز</span>
              </span>
              <form action={sendTestPush}>
                <input type="hidden" name="orgId" value={orgId} />
                <input type="hidden" name="userId" value={r.user_id} />
                <SubmitButton className="rounded border px-3 py-1 text-xs text-brand hover:bg-gray-50" pendingText="...">
                  إرسال تجريبي
                </SubmitButton>
              </form>
            </li>
          ))}
        </ul>
      ) : (
        <p className="rounded border border-dashed px-3 py-4 text-center text-sm text-gray-400">لا هاتف مسجّلًا بعد — افتح التطبيق على هاتفك وسجّل الدخول ووافق على الإشعارات</p>
      )}
    </section>
  );
}
