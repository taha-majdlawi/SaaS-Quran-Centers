import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { RecitationList, recitationAudio, type Recitation } from '@/components/recitation-list';
import { getI18n } from '@/lib/i18n/server';

/** The student's recorded recitations and teacher tests, with the teacher's decision. */
export default async function MyRecitationsPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ s?: string }> }) {
  const { org: slug } = await params;
  const { s } = await searchParams;
  const org = await getOrgContext(slug);
  const { t, locale } = await getI18n();
  const R = t.quran.recite;
  const supabase = await createClient();
  // RLS shows a student only their own row and a guardian only their children
  const [{ data: students }, { data: grades }] = await Promise.all([
    supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name'),
    supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id),
  ]);
  const list = (students ?? []) as { id: string; full_name: string }[];
  const current = list.find((x) => x.id === s) ?? list[0];
  const { data } = current ? await supabase.rpc('student_recitations', { p_org: org.id, p_student: current.id, p_limit: 50 }) : { data: [] };
  const items = (data ?? []) as Recitation[];
  const audio = await recitationAudio(items);

  return (
    <div className="mx-auto max-w-3xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <div className="mb-4 mt-2 flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-2xl font-bold">{R.myTitle}</h1>
        <a href="/my/quran" className="rounded border px-4 py-2 text-sm text-brand">
          {R.openMushaf}
        </a>
      </div>
      {list.length > 1 && (
        <div className="mb-4 flex flex-wrap gap-2">
          {list.map((x) => (
            <a key={x.id} href={`/my/recitations?s=${x.id}` as never} className={`rounded-full px-3 py-1 text-sm ${x.id === current?.id ? 'bg-brand text-white' : 'border bg-white'}`}>
              {x.full_name}
            </a>
          ))}
        </div>
      )}
      <RecitationList
        items={items}
        audio={audio}
        mode="family"
        grades={(grades ?? []) as { key: string; label: string }[]}
        typeLabels={t.labels.recitationType}
        locale={locale}
        R={R}
      />
      <p className="mt-4 text-xs text-gray-400">{R.autoNote}</p>
    </div>
  );
}
