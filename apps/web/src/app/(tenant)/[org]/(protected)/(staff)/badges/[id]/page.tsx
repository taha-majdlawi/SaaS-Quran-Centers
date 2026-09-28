import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { BadgeForm, type BadgeRow } from '@/components/badge-form';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { fmtDate, ruleText } from '@/lib/engagement/format';
import { awardBadge, awardToCircle, deleteBadge } from '../actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface Holder {
  student_id: string;
  student_name: string;
  student_code: string;
  awarded_at: string;
  expires_at: string | null;
  manual: boolean;
}


export default async function BadgePage({
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
  const isAdmin = org.myRole === 'admin';
  const back = `/badges/${id}`;

  const [{ data: badge }, { data: grades }, { data: students }, { data: circles }, holdersRes] = await Promise.all([
    supabase.from('badges').select('*').eq('id', id).eq('organization_id', org.id).maybeSingle(),
    supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id).order('sort_order'),
    supabase.from('students_profile').select('id, full_name, student_code').eq('organization_id', org.id).order('full_name'),
    supabase.from('circles').select('id, name').eq('organization_id', org.id).order('name'),
    isAdmin ? supabase.rpc('badge_holders', { p_org: org.id, p_badge: id }) : Promise.resolve({ data: [] }),
  ]);
  if (!badge) notFound();
  const holders = (holdersRes.data ?? []) as Holder[];
  const labels = new Map((grades ?? []).map((g) => [g.key as string, g.label as string]));

  return (
    <div className="max-w-2xl">
      <a href="/badges" className="text-sm text-brand hover:underline">
        {S.badges.back}
      </a>
      <h1 className="mb-1 mt-2 flex items-center gap-2 text-2xl font-bold">
        <span>{badge.icon}</span> {badge.name}
      </h1>
      <p className="mb-4 text-sm text-gray-500">{ruleText(badge, labels, T.labels.rule)}</p>
      {ok && S.badges.okOne[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.badges.okOne[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      {isAdmin && <BadgeForm orgId={org.id} badge={badge as BadgeRow} grades={grades ?? []} />}

      <section className="mt-6 rounded-lg border bg-white p-5">
        <h2 className="mb-3 font-semibold">{S.badges.awardManual}</h2>
        <form action={awardBadge} className="mb-3 flex flex-wrap items-end gap-2">
          <input type="hidden" name="badgeId" value={id} />
          <input type="hidden" name="back" value={back} />
          <select name="studentId" required defaultValue="" className="min-w-56 rounded border px-3 py-2 text-sm">
            <option value="" disabled>
              {S.badges.pickStudent}
            </option>
            {(students ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.full_name} ({s.student_code})
              </option>
            ))}
          </select>
          <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText="...">
            {S.badges.award}
          </SubmitButton>
        </form>
        {isAdmin && (
          <form action={awardToCircle} className="flex flex-wrap items-end gap-2">
            <input type="hidden" name="badgeId" value={id} />
            <input type="hidden" name="back" value={back} />
            <select name="circleId" required defaultValue="" className="min-w-56 rounded border px-3 py-2 text-sm">
              <option value="" disabled>
                {S.badges.orCircle}
              </option>
              {(circles ?? []).map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
            <SubmitButton className="rounded border px-4 py-2 text-sm text-brand" pendingText="...">
              {S.badges.awardCircle}
            </SubmitButton>
          </form>
        )}
      </section>

      {isAdmin && (
        <section className="mt-6">
          <h2 className="mb-2 font-semibold">{fmt(S.badges.holders, { n: holders.length })}</h2>
          <div className="flex flex-col gap-2">
            {holders.map((h) => (
              <div key={h.student_id} className="flex items-center justify-between rounded-lg border bg-white p-3 text-sm">
                <span>
                  <b>{h.student_name}</b> <span className="text-xs text-gray-500">{h.student_code}</span>
                  <span className="text-xs text-gray-500">
                    {' '}
                    · {fmtDate(h.awarded_at, T.labels.dateLocale)} · {h.manual ? S.badges.manualTag : S.badges.autoTag}
                    {h.expires_at && fmt(S.badges.expiresOn, { date: fmtDate(h.expires_at, T.labels.dateLocale) })}
                  </span>
                </span>
                <form action={awardBadge}>
                  <input type="hidden" name="badgeId" value={id} />
                  <input type="hidden" name="studentId" value={h.student_id} />
                  <input type="hidden" name="revoke" value="1" />
                  <input type="hidden" name="back" value={back} />
                  <ConfirmSubmitButton confirmMessage={S.badges.revokeConfirm} pendingText="..." className="rounded border border-red-200 px-2 py-1 text-xs text-red-600">
                    {S.badges.revoke}
                  </ConfirmSubmitButton>
                </form>
              </div>
            ))}
            {!holders.length && <p className="rounded-lg border bg-white p-4 text-center text-sm text-gray-400">{S.badges.noHolders}</p>}
          </div>
          <form action={deleteBadge} className="mt-6">
            <input type="hidden" name="orgId" value={org.id} />
            <input type="hidden" name="id" value={id} />
            <ConfirmSubmitButton confirmMessage={S.badges.deleteConfirm} pendingText="..." className="rounded border border-red-200 px-4 py-2 text-sm text-red-600">
              {S.badges.delete}
            </ConfirmSubmitButton>
          </form>
        </section>
      )}
    </div>
  );
}
