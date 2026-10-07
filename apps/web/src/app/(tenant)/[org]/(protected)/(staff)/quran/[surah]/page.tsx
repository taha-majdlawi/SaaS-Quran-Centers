import { getOrgContext } from '@/lib/tenant/get-org-context';
import { QuranReaderView } from '@/components/quran-views';

export default async function SurahPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string; surah: string }>;
  searchParams: Promise<{ ayah?: string; to?: string; recite?: string }>;
}) {
  const { org: slug, surah } = await params;
  const { ayah, to, recite } = await searchParams;
  const org = await getOrgContext(slug);
  return <QuranReaderView orgId={org.id} base="/quran" surah={Number(surah)} ayah={ayah ? Number(ayah) : undefined} reciteTo={to ? Number(to) : undefined} reciteType={recite} recitations={!org.disabledModules.includes('recitations')} />;
}
