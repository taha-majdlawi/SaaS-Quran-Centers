import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { ChallengeForm } from '@/components/challenge-form';
import { getI18n } from '@/lib/i18n/server';

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
  const { t: T } = await getI18n();
  const S = T.staff;
  if (org.myRole !== 'admin') redirect('/circle-challenges' as never);

  return (
    <div>
      <a href="/circle-challenges" className="text-sm text-brand hover:underline">
        {S.challenges.back}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{S.challenges.newTitle}</h1>
      <ChallengeForm orgId={org.id} error={error} />
    </div>
  );
}
