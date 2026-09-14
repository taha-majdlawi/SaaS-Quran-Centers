import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

const TYPE_LABELS: Record<string, string> = { full: 'كامل', partial: 'جزئي' };
const STATUS_LABELS: Record<string, string> = {
  pending: 'قيد الانتظار',
  scheduled: 'مجدولة',
  in_progress: 'جارية',
  completed: 'مكتملة',
  cancelled: 'ملغاة',
};

interface SessionRow {
  id: string;
  session_type: string;
  status: string;
  scheduled_at: string | null;
  overall_grade: number | null;
  students_profile: { full_name: string } | null;
}

// Replaces wep-eqraa-center/admin/serd - scheduling + grading for full/
// partial Quran recitation exams (see actions.ts, new/, [id]/).
export default async function SerdPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const { data: sessions } = await supabase
    .from('serd_sessions')
    .select('id, session_type, status, scheduled_at, overall_grade, students_profile(full_name)')
    .eq('organization_id', org.id)
    .order('scheduled_at', { ascending: false, nullsFirst: false });

  return (
    <div>
      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-2xl font-bold">السرد القرآني</h1>
        <a href="/serd/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          + جدولة جلسة سرد
        </a>
      </div>
      <table className="w-full overflow-hidden rounded-lg border bg-white text-sm">
        <thead className="bg-gray-50 text-right">
          <tr>
            <th className="px-4 py-2">الطالب</th>
            <th className="px-4 py-2">النوع</th>
            <th className="px-4 py-2">الموعد</th>
            <th className="px-4 py-2">الحالة</th>
            <th className="px-4 py-2">التقدير</th>
            <th className="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody>
          {((sessions ?? []) as unknown as SessionRow[]).map((s) => (
            <tr key={s.id} className="border-t">
              <td className="px-4 py-2">{s.students_profile?.full_name ?? '—'}</td>
              <td className="px-4 py-2">{TYPE_LABELS[s.session_type] ?? s.session_type}</td>
              <td className="px-4 py-2">
                {s.scheduled_at ? new Date(s.scheduled_at).toLocaleString('ar') : '—'}
              </td>
              <td className="px-4 py-2">{STATUS_LABELS[s.status] ?? s.status}</td>
              <td className="px-4 py-2">{s.overall_grade ?? '—'}</td>
              <td className="px-4 py-2 text-left">
                <a href={`/serd/${s.id}`} className="text-brand hover:underline">
                  تعديل
                </a>
              </td>
            </tr>
          ))}
          {!sessions?.length && (
            <tr>
              <td colSpan={6} className="px-4 py-6 text-center text-gray-400">
                لا يوجد جلسات سرد بعد
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
