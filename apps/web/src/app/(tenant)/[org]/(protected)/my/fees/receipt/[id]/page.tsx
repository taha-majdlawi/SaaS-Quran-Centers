import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { FeeReceiptView } from '@/components/fee-receipt';
import { getI18n } from '@/lib/i18n/server';
import type { FeeReceipt } from '@/lib/fees/types';

/** The family's copy of a receipt (fee_receipt only answers for their own children). */
export default async function MyFeeReceiptPage({ params }: { params: Promise<{ org: string; id: string }> }) {
  const { org: slug, id } = await params;
  const org = await getOrgContext(slug);
  if (!org.feesEnabled) notFound();
  const supabase = await createClient();
  const { data } = await supabase.rpc('fee_receipt', { p_org: org.id, p_payment: id });
  if (!data) notFound();
  const { t } = await getI18n();
  return <FeeReceiptView r={data as FeeReceipt} back="/my/fees" backLabel={`← ${t.staff.fees.title}`} />;
}
