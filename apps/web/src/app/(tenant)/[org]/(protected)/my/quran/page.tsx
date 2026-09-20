import { getOrgContext } from '@/lib/tenant/get-org-context';
import { QuranIndexView } from '@/components/quran-views';

export default async function MyQuranPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ q?: string }> }) {
  const { org: slug } = await params;
  const { q } = await searchParams;
  const org = await getOrgContext(slug);
  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        ← ملفي
      </a>
      <div className="mt-2">
        <QuranIndexView orgId={org.id} base="/my/quran" q={q} />
      </div>
    </div>
  );
}
