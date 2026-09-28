import { getOrgContext } from '@/lib/tenant/get-org-context';
import { QuranIndexView } from '@/components/quran-views';
import { getI18n } from '@/lib/i18n/server';

export default async function MyQuranPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ q?: string }> }) {
  const { org: slug } = await params;
  const { q } = await searchParams;
  const org = await getOrgContext(slug);
  const { t } = await getI18n();
  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backToProfile}
      </a>
      <div className="mt-2">
        <QuranIndexView orgId={org.id} base="/my/quran" q={q} />
      </div>
    </div>
  );
}
