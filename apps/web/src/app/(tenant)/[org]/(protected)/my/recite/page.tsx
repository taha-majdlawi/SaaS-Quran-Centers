import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { QuranFont } from '@/components/quran-font';
import { LiveRecite } from '@/components/live-recite';
import { getI18n } from '@/lib/i18n/server';

/** Reciting from memory, followed live word by word (components/live-recite.tsx). Opened from the button, the daily portion or "my recitations". */
export default async function MyRecitePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ s?: string; surah?: string; from?: string; to?: string; type?: string }>;
}) {
  const { org: slug } = await params;
  const q = await searchParams;
  const org = await getOrgContext(slug);
  const { t, locale } = await getI18n();
  const supabase = await createClient();
  // RLS shows a student only their own row and a guardian only their children
  const { data } = await supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name');
  const students = ((data ?? []) as { id: string; full_name: string }[]).map((s) => ({ id: s.id, name: s.full_name }));
  const num = (v?: string) => (v && /^\d+$/.test(v) ? Number(v) : undefined);

  return (
    <QuranFont>
      <div className="mx-auto max-w-3xl p-4 sm:p-6">
        <div className="mb-3 flex items-center justify-between">
          <h1 className="text-2xl font-bold">{t.live.title}</h1>
          <a href="/my/recitations" className="text-sm text-brand hover:underline">
            {t.live.mine}
          </a>
        </div>
        {students.length === 0 ? (
          <p className="text-gray-500">{t.portal.noStudent}</p>
        ) : (
          <LiveRecite
            orgId={org.id}
            students={students}
            initial={{ student: q.s, surah: num(q.surah), from: num(q.from), to: num(q.to), type: q.type }}
            typeLabels={t.labels.recitationType}
            locale={locale}
            L={t.live}
          />
        )}
      </div>
    </QuranFont>
  );
}
