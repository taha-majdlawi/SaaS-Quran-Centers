import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { fmtDay, type CertificateRow } from '@/lib/reports/format';
import { getI18n } from '@/lib/i18n/server';

export default async function MyCertificatesPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const { t } = await getI18n();
  const { data } = await supabase.rpc('list_certificates', { p_org: org.id, p_limit: 100 });
  const rows = ((data as { rows: CertificateRow[] } | null)?.rows ?? []) as CertificateRow[];

  return (
    <div className="mx-auto max-w-2xl p-6">
      <a href="/my" className="text-sm text-brand hover:underline">
        {t.portal.backHome}
      </a>
      <h1 className="mb-4 mt-2 text-2xl font-bold">{t.certificates.title}</h1>
      {rows.length ? (
        <div className="flex flex-col gap-3">
          {rows.map((c) => (
            <a key={c.id} href={`/my/certificates/${c.id}` as never} className="rounded-lg border bg-white p-4 hover:bg-gray-50">
              <p className="font-semibold">{c.title}</p>
              <p className="text-sm text-gray-500">
                {c.recipient_name} · {t.labels.certKind[c.kind] ?? c.kind} · {fmtDay(c.issued_at, t.labels.dateLocale)}
              </p>
            </a>
          ))}
        </div>
      ) : (
        <p className="rounded-lg border bg-white p-8 text-center text-gray-500">{t.certificates.none}</p>
      )}
    </div>
  );
}
