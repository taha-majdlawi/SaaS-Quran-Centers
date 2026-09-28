import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { fmtDate, ruleText, type BadgeProgress } from '@/lib/engagement/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface Leaderboard {
  enabled: boolean;
  circle_name?: string;
  rows: { rank: number; name: string; points: number; is_me: boolean }[];
}

interface Challenge {
  id: string;
  title: string;
  metric: string;
  starts_on: string;
  ends_on: string;
  status: string;
}

interface Board {
  rows: { rank: number; circle_id: string; circle_name: string; students: number; average: number; mine: boolean }[];
}

// Badges (with progress toward each), the circle board (if the center enables
// it) and the running circle challenge.
export default async function MyBadgesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ s?: string }>;
}) {
  const { org: slug } = await params;
  const { s } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const { t } = await getI18n();
  const B = t.badges;
  const lang = t.labels.dateLocale;

  const { data: students } = await supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name');
  const list = (students ?? []) as { id: string; full_name: string }[];
  const current = list.find((x) => x.id === s) ?? list[0];

  const [{ data: badgesData }, { data: boardData }, { data: chData }, { data: grades }] = await Promise.all([
    current ? supabase.rpc('get_student_badges', { p_org: org.id, p_student: current.id }) : Promise.resolve({ data: [] }),
    supabase.rpc('get_circle_leaderboard', { p_org: org.id, p_circle: null }),
    supabase.rpc('list_challenges', { p_org: org.id }),
    supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id),
  ]);
  const badges = (badgesData ?? []) as BadgeProgress[];
  const lb = boardData as Leaderboard | null;
  const challenges = (chData ?? []) as Challenge[];
  const running = challenges.find((c) => c.status === 'active') ?? challenges[0];
  const { data: chBoard } = running ? await supabase.rpc('challenge_board', { p_org: org.id, p_challenge: running.id }) : { data: null };
  const board = chBoard as Board | null;
  const labels = new Map((grades ?? []).map((g) => [g.key as string, g.label as string]));

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{B.title}</h1>
      {list.length > 1 && (
        <div className="mb-4 flex flex-wrap gap-2 text-sm">
          {list.map((x) => (
            <a key={x.id} href={`/my/badges?s=${x.id}` as never} className={`rounded-full border px-3 py-1 ${x.id === current?.id ? 'bg-brand text-white' : 'bg-white'}`}>
              {x.full_name}
            </a>
          ))}
        </div>
      )}

      <h2 className="mb-2 font-semibold">{B.mine}</h2>
      <div className="mb-8 grid gap-3 sm:grid-cols-2">
        {badges.map((b) => {
          const pct = b.goal > 0 ? Math.min(100, Math.round((b.progress / b.goal) * 100)) : 0;
          return (
            <div key={b.id} className={`rounded-lg border bg-white p-4 text-sm ${b.earned ? '' : 'opacity-70'}`}>
              <div className="flex items-center gap-3">
                <span className={`flex h-12 w-12 items-center justify-center rounded-full text-2xl ${b.earned ? '' : 'grayscale'}`} style={{ backgroundColor: `${b.color}22`, border: `2px solid ${b.color}` }}>
                  {b.icon}
                </span>
                <div>
                  <b>{b.name}</b>
                  <p className="text-xs text-gray-500">{b.description ?? ruleText(b, labels, t.labels.rule)}</p>
                </div>
              </div>
              {b.earned ? (
                <p className="mt-2 text-xs text-green-700">
                  {fmt(B.earned, { date: fmtDate(b.awarded_at, lang) })}
                  {b.expires_at && fmt(B.expires, { date: fmtDate(b.expires_at, lang) })}
                </p>
              ) : b.rule_type === 'manual' ? (
                <p className="mt-2 text-xs text-gray-500">{B.manual}</p>
              ) : (
                <div className="mt-2">
                  <div className="h-2 overflow-hidden rounded bg-gray-100">
                    <div className="h-full" style={{ width: `${pct}%`, backgroundColor: b.color }} />
                  </div>
                  <p className="mt-1 text-xs text-gray-500">
                    {b.progress} / {b.goal}
                  </p>
                </div>
              )}
            </div>
          );
        })}
        {!badges.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{B.none}</p>}
      </div>

      {lb?.enabled && lb.rows.length > 0 && (
        <section className="mb-8">
          <h2 className="mb-2 font-semibold">{fmt(B.board, { circle: lb.circle_name ?? '' })}</h2>
          <ol className="overflow-hidden rounded-lg border bg-white text-sm">
            {lb.rows.map((r) => (
              <li key={r.rank + r.name} className={`flex items-center justify-between border-b px-4 py-2 last:border-0 ${r.is_me ? 'bg-green-50 font-semibold' : ''}`}>
                <span>
                  {r.rank === 1 ? '🥇' : r.rank === 2 ? '🥈' : r.rank === 3 ? '🥉' : `${r.rank}.`} {r.name}
                </span>
                <span className="text-brand">{fmt(B.points, { n: r.points })}</span>
              </li>
            ))}
          </ol>
        </section>
      )}

      {running && board && (
        <section>
          <h2 className="mb-1 font-semibold">{fmt(B.challenge, { title: running.title })}</h2>
          <p className="mb-2 text-xs text-gray-500">
            {t.labels.metric[running.metric]} · {fmtDate(running.starts_on, lang)} — {fmtDate(running.ends_on, lang)} · {t.labels.challengeStatus[running.status]}
          </p>
          <ol className="overflow-hidden rounded-lg border bg-white text-sm">
            {board.rows.map((r) => (
              <li key={r.circle_id} className={`flex items-center justify-between border-b px-4 py-2 last:border-0 ${r.mine ? 'bg-green-50 font-semibold' : ''}`}>
                <span>
                  {r.rank === 1 ? '🥇' : r.rank === 2 ? '🥈' : r.rank === 3 ? '🥉' : `${r.rank}.`} {r.circle_name}
                </span>
                <span className="text-brand">{r.average}</span>
              </li>
            ))}
          </ol>
        </section>
      )}
    </div>
  );
}
