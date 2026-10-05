import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { RecitationList, recitationAudio, type Recitation } from '@/components/recitation-list';
import { getI18n } from '@/lib/i18n/server';

/** What students recited to the system from the mushaf, waiting for (or decided by) their teacher. */
export default async function RecitationsInboxPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ tab?: string; done?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { tab, done, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t, locale } = await getI18n();
  const R = t.quran.recite;
  const reviewed = tab === 'reviewed';
  const supabase = await createClient();
  const [{ data }, { data: grades }] = await Promise.all([
    supabase.rpc('recitation_inbox', { p_org: org.id, p_status: reviewed ? '' : 'submitted', p_limit: 100 }),
    supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id).eq('is_active', true).order('sort_order'),
  ]);
  const items = ((data ?? []) as Recitation[]).filter((r) => (reviewed ? r.status !== 'submitted' : true));
  const audio = await recitationAudio(items);
  const tabCls = (on: boolean) => `rounded-full px-4 py-1.5 text-sm ${on ? 'bg-brand text-white' : 'border bg-white text-gray-600'}`;

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">{R.inboxTitle}</h1>
      <p className="mb-4 text-sm text-gray-500">{R.inboxHint}</p>
      <div className="mb-4 flex gap-2">
        <a href="/recitations" className={tabCls(!reviewed)}>
          {R.pending}
        </a>
        <a href="/recitations?tab=reviewed" className={tabCls(reviewed)}>
          {R.reviewed}
        </a>
      </div>
      {done && <p className="mb-3 rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{done === 'approved' ? R.statusApproved : R.statusRejected}</p>}
      {error && <p className="mb-3 rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <RecitationList
        items={items}
        audio={audio}
        mode="staff"
        grades={(grades ?? []) as { key: string; label: string }[]}
        typeLabels={t.labels.recitationType}
        locale={locale}
        R={R}
      />
      <p className="mt-4 text-xs text-gray-400">{R.autoNote}</p>
    </div>
  );
}
