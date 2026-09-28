import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { fmtDay, type CertificateRow } from '@/lib/reports/format';
import { issueCertificate, revokeCertificate, saveCertificateSettings } from '@/lib/certs/actions';
import { getI18n } from '@/lib/i18n/server';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

interface Settings {
  signer_name: string | null;
  signer_title: string | null;
  footer: string | null;
  serd_title: string;
  auto_serd: boolean;
}

export default async function CertificatesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (!org.myPermissions.includes('certificates')) notFound();
  const isAdmin = org.myRole === 'admin';
  const supabase = await createClient();

  const [{ data: list }, { data: students }, settingsRes] = await Promise.all([
    supabase.rpc('list_certificates', { p_org: org.id, p_limit: 100 }),
    supabase.from('students_profile').select('id, full_name, student_code').eq('organization_id', org.id).order('full_name'),
    isAdmin ? supabase.rpc('get_certificate_settings', { p_org: org.id }) : Promise.resolve({ data: null }),
  ]);
  const rows = ((list as { rows: CertificateRow[] } | null)?.rows ?? []) as CertificateRow[];
  const settings = settingsRes.data as Settings | null;

  return (
    <div className="max-w-4xl">
      <h1 className="mb-4 text-2xl font-bold">{S.certs.heading}</h1>
      {ok && S.certs.ok[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.certs.ok[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={issueCertificate} className="mb-6 grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-2">
        <input type="hidden" name="orgId" value={org.id} />
        <h2 className="text-sm font-semibold sm:col-span-2">{S.certs.issueTitle}</h2>
        <label className="text-sm text-gray-700">
          {S.certs.student}
          <select name="studentId" required defaultValue="" className={field}>
            <option value="" disabled>
              {S.certs.pickStudent}
            </option>
            {(students ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.full_name} — {s.student_code}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm text-gray-700">
          {S.certs.kind}
          <select name="kind" defaultValue="custom" className={field}>
            {Object.entries(T.labels.certKind)
              .filter(([k]) => k !== 'serd')
              .map(([k, label]) => (
                <option key={k} value={k}>
                  {label}
                </option>
              ))}
          </select>
        </label>
        <label className="text-sm text-gray-700 sm:col-span-2">
          {S.certs.title}
          <input name="title" required minLength={2} maxLength={120} placeholder={S.certs.titlePh} className={field} />
        </label>
        <label className="text-sm text-gray-700 sm:col-span-2">
          {S.certs.text}
          <textarea name="description" maxLength={500} rows={2} placeholder={S.certs.textPh} className={field} />
        </label>
        <div className="sm:col-span-2">
          <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.certs.issuing}>
            {S.certs.issueBtn}
          </SubmitButton>
          <span className="ms-3 text-xs text-gray-500">{S.certs.serdHint}</span>
        </div>
      </form>

      <div className="mb-8 overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-start">{S.certs.student}</th>
              <th className="px-3 py-2 text-start">{S.certs.certificate}</th>
              <th className="px-3 py-2 text-start">{S.certs.date}</th>
              <th className="px-3 py-2 text-start">{S.certs.serial}</th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((c) => (
              <tr key={c.id} className="border-t">
                <td className="px-3 py-2">{c.recipient_name}</td>
                <td className="px-3 py-2">
                  {c.title} <span className="text-xs text-gray-400">({T.labels.certKind[c.kind] ?? c.kind})</span>
                  {c.revoked_at && <span className="ms-2 rounded bg-red-50 px-2 py-0.5 text-xs text-red-600">{S.certs.revoked}</span>}
                </td>
                <td className="px-3 py-2">{fmtDay(c.issued_at, T.labels.dateLocale)}</td>
                <td className="px-3 py-2 font-mono text-xs" dir="ltr">
                  {c.serial}
                </td>
                <td className="flex items-center gap-3 px-3 py-2 text-end">
                  <a href={`/certificates/${c.id}` as never} className="text-brand hover:underline">
                    {S.certs.view}
                  </a>
                  {!c.revoked_at && (
                    <form action={revokeCertificate}>
                      <input type="hidden" name="orgId" value={org.id} />
                      <input type="hidden" name="id" value={c.id} />
                      <ConfirmSubmitButton
                        confirmMessage={S.certs.confirmRevoke}
                        pendingText="..."
                        className="text-xs text-red-600 hover:underline"
                      >
                        {S.certs.revoke}
                      </ConfirmSubmitButton>
                    </form>
                  )}
                </td>
              </tr>
            ))}
            {!rows.length && (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-center text-gray-400">
                  {S.certs.empty}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {isAdmin && settings && (
        <form action={saveCertificateSettings} className="grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-2">
          <input type="hidden" name="orgId" value={org.id} />
          <h2 className="text-sm font-semibold sm:col-span-2">{S.certs.customize}</h2>
          <label className="text-sm text-gray-700">
            {S.certs.signer}
            <input name="signerName" defaultValue={settings.signer_name ?? ''} maxLength={80} className={field} />
          </label>
          <label className="text-sm text-gray-700">
            {S.certs.signerTitle}
            <input name="signerTitle" defaultValue={settings.signer_title ?? ''} maxLength={80} placeholder={S.certs.signerTitlePh} className={field} />
          </label>
          <label className="text-sm text-gray-700 sm:col-span-2">
            {S.certs.footer}
            <input name="footer" defaultValue={settings.footer ?? ''} maxLength={200} placeholder={S.certs.footerPh} className={field} />
          </label>
          <label className="text-sm text-gray-700 sm:col-span-2">
            {S.certs.serdTitle}
            <input name="serdTitle" defaultValue={settings.serd_title} maxLength={120} className={field} />
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700 sm:col-span-2">
            <input type="checkbox" name="autoSerd" defaultChecked={settings.auto_serd} />
            {S.certs.autoSerd}
          </label>
          <p className="text-xs text-gray-500 sm:col-span-2">{S.certs.settingsHint}</p>
          <div className="sm:col-span-2">
            <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText={S.common.saving}>
              {S.certs.saveSettings}
            </SubmitButton>
          </div>
        </form>
      )}
    </div>
  );
}
