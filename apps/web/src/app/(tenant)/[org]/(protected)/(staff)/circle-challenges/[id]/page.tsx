import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { saveScores, deleteChallenge } from '../actions';

export default async function ChallengeDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { org: slug, id } = await params;
  const { error, saved } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();

  const [{ data: challenge }, { data: circles }, { data: entries }] = await Promise.all([
    supabase
      .from('circle_challenges')
      .select('id, title, metric, starts_on, ends_on')
      .eq('organization_id', org.id)
      .eq('id', id)
      .maybeSingle(),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
    supabase.from('circle_challenge_entries').select('circle_id, score').eq('challenge_id', id),
  ]);

  if (!challenge) notFound();

  const scoreByCircle = new Map((entries ?? []).map((e) => [e.circle_id, e.score]));

  return (
    <div>
      <div className="mb-1 flex items-center justify-between">
        <h1 className="text-2xl font-bold">{challenge.title}</h1>
        <form action={deleteChallenge}>
          <input type="hidden" name="id" value={challenge.id} />
          <ConfirmSubmitButton
            confirmMessage={`متأكد إنك بدك تحذف منافسة "${challenge.title}"؟`}
            pendingText="جاري الحذف..."
            className="text-sm text-red-600 hover:underline"
          >
            حذف المنافسة
          </ConfirmSubmitButton>
        </form>
      </div>
      <p className="mb-6 text-sm text-gray-500">
        المعيار: {challenge.metric} — {challenge.starts_on} إلى {challenge.ends_on}
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم حفظ النتائج</p>}

      <form action={saveScores} className="rounded-lg border bg-white">
        <input type="hidden" name="challengeId" value={challenge.id} />
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right">
            <tr>
              <th className="px-4 py-2">الحلقة</th>
              <th className="px-4 py-2">النقاط</th>
            </tr>
          </thead>
          <tbody>
            {(circles ?? []).map((c) => (
              <tr key={c.id} className="border-t">
                <td className="px-4 py-2">{c.name}</td>
                <td className="px-4 py-2">
                  <input
                    type="number"
                    name={`score_${c.id}`}
                    defaultValue={scoreByCircle.get(c.id) ?? 0}
                    className="w-24 rounded border px-2 py-1"
                  />
                </td>
              </tr>
            ))}
            {!circles?.length && (
              <tr>
                <td colSpan={2} className="px-4 py-6 text-center text-gray-400">
                  لا يوجد حلقات بعد
                </td>
              </tr>
            )}
          </tbody>
        </table>
        {Boolean(circles?.length) && (
          <div className="p-4">
            <SubmitButton
              className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText="جاري الحفظ..."
            >
              حفظ النتائج
            </SubmitButton>
          </div>
        )}
      </form>
    </div>
  );
}
