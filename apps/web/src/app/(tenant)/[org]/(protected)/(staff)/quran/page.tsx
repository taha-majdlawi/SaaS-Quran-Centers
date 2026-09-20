import { getOrgContext } from '@/lib/tenant/get-org-context';
import { QuranIndexView } from '@/components/quran-views';

export default async function QuranPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ q?: string }> }) {
  const { org: slug } = await params;
  const { q } = await searchParams;
  const org = await getOrgContext(slug);
  return <QuranIndexView orgId={org.id} base="/quran" q={q} />;
}
