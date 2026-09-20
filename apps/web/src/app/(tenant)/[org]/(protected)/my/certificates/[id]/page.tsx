import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { CertificateView } from '@/components/certificate-view';
import type { CertificateFull } from '@/lib/reports/format';

export default async function MyCertificatePage({ params }: { params: Promise<{ org: string; id: string }> }) {
  const { org: slug, id } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const { data } = await supabase.rpc('get_certificate', { p_org: org.id, p_id: id });
  if (!data) notFound();
  return (
    <div className="p-6">
      <CertificateView cert={data as CertificateFull} back="/my/certificates" />
    </div>
  );
}
