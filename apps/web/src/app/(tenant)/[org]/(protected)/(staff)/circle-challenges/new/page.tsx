import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChallengeForm } from '@/components/challenge-form';

export default async function NewChallengePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org: slug } = await params;
  const { error } = await searchParams;
  const org = await getOrgContext(slug);
  if (org.myRole !== 'admin') redirect('/circle-challenges' as never);

  return (
    <div>
      <a href="/circle-challenges" className="text-sm text-brand hover:underline">
        ← المنافسات
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">منافسة جديدة</h1>
      <ChallengeForm orgId={org.id} error={error} />
    </div>
  );
}
