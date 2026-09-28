import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { BadgeForm } from '@/components/badge-form';
import { getI18n } from '@/lib/i18n/server';

export default async function NewBadgePage({
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
  if (org.myRole !== 'admin') redirect('/badges' as never);
  const supabase = await createClient();
  const { data: grades } = await supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id).order('sort_order');

  return (
    <div>
      <a href="/badges" className="text-sm text-brand hover:underline">
        {S.badges.back}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{S.badges.newTitle}</h1>
      <BadgeForm orgId={org.id} grades={grades ?? []} error={error} />
    </div>
  );
}
