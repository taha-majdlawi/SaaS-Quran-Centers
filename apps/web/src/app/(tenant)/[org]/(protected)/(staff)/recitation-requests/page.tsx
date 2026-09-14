import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { rejectRecitationRequest } from './actions';

const TYPE_LABELS: Record<string, string> = { full: 'كامل', partial: 'جزئي' };

interface RequestRow {
  id: string;
  session_type: string;
  created_at: string;
  students_profile: { full_name: string } | null;
}

// Replaces wep-eqraa-center/admin/recitation-requests - a queue of
// not-yet-scheduled serd_sessions (status='pending'). Scheduling a request
// (giving it a date) or grading it happens on serd/[id] - this page is
// just the "needs attention" view, reject sets status='cancelled'.
export default async function RecitationRequestsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: requests } = await supabase
    .from('serd_sessions')
    .select('id, session_type, created_at, students_profile(full_name)')
    .eq('organization_id', org.id)
    .eq('status', 'pending')
    .order('created_at');

  return (
    <div>
      <h1 className="mb-1 text-2xl font-bold">طلبات التسميع</h1>
      <p className="mb-6 text-sm text-gray-500">جلسات سرد لسه ما جدولنالها موعد - جدولها من صفحة السرد أو رفضها من هنا.</p>

      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الطالب</th>
            <th className="px-4 py-2">النوع</th>
            <th className="px-4 py-2">تاريخ الطلب</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {((requests ?? []) as unknown as RequestRow[]).map((r) => (
            <tr key={r.id} className="border-t">
              <td className="px-4 py-2">{r.students_profile?.full_name ?? '—'}</td>
              <td className="px-4 py-2">{TYPE_LABELS[r.session_type] ?? r.session_type}</td>
              <td className="px-4 py-2">{new Date(r.created_at).toLocaleDateString('ar')}</td>
              <td className="px-4 py-2 text-left">
                <div className="flex items-center justify-end gap-3">
                  <a href={`/serd/${r.id}`} className="text-brand hover:underline">
                    جدولة
                  </a>
                  <form action={rejectRecitationRequest}>
                    <input type="hidden" name="id" value={r.id} />
                    <ConfirmSubmitButton
                      confirmMessage="متأكد إنك بدك ترفض هذا الطلب؟"
                      pendingText="جاري الرفض..."
                      className="text-red-600 hover:underline"
                    >
                      رفض
                    </ConfirmSubmitButton>
                  </form>
                </div>
              </td>
            </tr>
          ))}
          {!requests?.length && (
            <tr>
              <td colSpan={4} className="px-4 py-6 text-center text-gray-400">
                لا يوجد طلبات معلّقة
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
