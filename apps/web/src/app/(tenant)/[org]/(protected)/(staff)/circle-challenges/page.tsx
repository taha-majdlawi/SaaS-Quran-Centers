import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { fmtDate } from '@/lib/engagement/format';
import { getI18n } from '@/lib/i18n/server';

interface Challenge {
  id: string;
  title: string;
  description: string | null;
  metric: string;
  starts_on: string;
  ends_on: string;
  status: string;
}

export default async function ChallengesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string }>;
}) {
  const { org: slug } = await params;
  const { ok } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();
  const { data } = await supabase.rpc('list_challenges', { p_org: org.id });
  const challenges = (data ?? []) as Challenge[];

  return (
    <div className="max-w-3xl">
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold">{S.challenges.heading}</h1>
        {org.myRole === 'admin' && (
          <a href="/circle-challenges/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
            {S.challenges.add}
          </a>
        )}
      </div>
      {ok === 'deleted' && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.challenges.deleted}</p>}
      <p className="mb-4 text-sm text-gray-500">{S.challenges.hint}</p>
      <div className="flex flex-col gap-2">
        {challenges.map((c) => (
          <a key={c.id} href={`/circle-challenges/${c.id}` as never} className="rounded-lg border bg-white p-4 text-sm hover:bg-gray-50">
            <div className="flex items-center justify-between">
              <b>{c.title}</b>
              <span className="rounded bg-gray-100 px-2 py-0.5 text-xs">{T.labels.challengeStatus[c.status]}</span>
            </div>
            <p className="mt-1 text-xs text-gray-500">
              {T.labels.metric[c.metric]} · {fmtDate(c.starts_on, T.labels.dateLocale)} — {fmtDate(c.ends_on, T.labels.dateLocale)}
            </p>
          </a>
        ))}
        {!challenges.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{S.challenges.empty}</p>}
      </div>
    </div>
  );
}
