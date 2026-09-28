import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { ChallengeForm } from '@/components/challenge-form';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { fmtDate } from '@/lib/engagement/format';
import { deleteChallenge } from '../actions';
import { getI18n } from '@/lib/i18n/server';

interface Board {
  id: string;
  title: string;
  metric: string;
  starts_on: string;
  ends_on: string;
  status: string;
  rows: { rank: number; circle_id: string; circle_name: string; students: number; total: number; average: number; mine: boolean }[];
}

export default async function ChallengePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; id: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug, id } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();

  const [{ data: boardData }, { data: raw }] = await Promise.all([
    supabase.rpc('challenge_board', { p_org: org.id, p_challenge: id }),
    supabase.from('circle_challenges').select('id, title, description, metric, starts_on, ends_on').eq('id', id).maybeSingle(),
  ]);
  const board = boardData as Board | null;
  if (!board || !raw) notFound();

  return (
    <div className="max-w-2xl">
      <a href="/circle-challenges" className="text-sm text-brand hover:underline">
        {S.challenges.back}
      </a>
      <h1 className="mb-1 mt-2 text-2xl font-bold">{board.title}</h1>
      <p className="mb-4 text-sm text-gray-500">
        {T.labels.metric[board.metric]} · {fmtDate(board.starts_on, T.labels.dateLocale)} — {fmtDate(board.ends_on, T.labels.dateLocale)} · {T.labels.challengeStatus[board.status]}
      </p>
      {ok === 'saved' && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.challenges.saved}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <div className="mb-8 overflow-hidden rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-start">
            <tr>
              <th className="px-4 py-2">#</th>
              <th className="px-4 py-2">{S.challenges.circle}</th>
              <th className="px-4 py-2">{S.challenges.students}</th>
              <th className="px-4 py-2">{S.challenges.total}</th>
              <th className="px-4 py-2">{S.challenges.average}</th>
            </tr>
          </thead>
          <tbody>
            {board.rows.map((r) => (
              <tr key={r.circle_id} className={`border-t ${r.mine ? 'bg-green-50' : ''}`}>
                <td className="px-4 py-2 font-bold">{r.rank === 1 ? '🥇' : r.rank === 2 ? '🥈' : r.rank === 3 ? '🥉' : r.rank}</td>
                <td className="px-4 py-2">{r.circle_name}</td>
                <td className="px-4 py-2">{r.students}</td>
                <td className="px-4 py-2">{r.total}</td>
                <td className="px-4 py-2 font-semibold text-brand">{r.average}</td>
              </tr>
            ))}
            {!board.rows.length && (
              <tr>
                <td colSpan={5} className="px-4 py-6 text-center text-gray-400">
                  {S.challenges.noRows}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {org.myRole === 'admin' && (
        <>
          <ChallengeForm orgId={org.id} challenge={raw} />
          <form action={deleteChallenge} className="mt-4">
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="id" value={id} />
            <ConfirmSubmitButton confirmMessage={S.challenges.confirmDelete} pendingText="..." className="rounded border border-red-200 px-4 py-2 text-sm text-red-600">
              {S.common.delete}
            </ConfirmSubmitButton>
          </form>
        </>
      )}
    </div>
  );
}
