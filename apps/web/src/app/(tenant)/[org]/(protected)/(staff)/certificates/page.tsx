import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { CERT_KIND_LABELS, fmtDay, type CertificateRow } from '@/lib/reports/format';
import { issueCertificate, revokeCertificate, saveCertificateSettings } from '@/lib/certs/actions';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

interface Settings {
  signer_name: string | null;
  signer_title: string | null;
  footer: string | null;
  serd_title: string;
  auto_serd: boolean;
}

const OK: Record<string, string> = { issued: 'صدرت الشهادة', revoked: 'سُحبت الشهادة', settings: 'حُفظت الإعدادات' };

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
      <h1 className="mb-4 text-2xl font-bold">الشهادات</h1>
      {ok && OK[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={issueCertificate} className="mb-6 grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-2">
        <input type="hidden" name="orgId" value={org.id} />
        <h2 className="text-sm font-semibold sm:col-span-2">إصدار شهادة</h2>
        <label className="text-sm text-gray-700">
          الطالب
          <select name="studentId" required defaultValue="" className={field}>
            <option value="" disabled>
              اختر الطالب
            </option>
            {(students ?? []).map((s) => (
              <option key={s.id} value={s.id}>
                {s.full_name} — {s.student_code}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm text-gray-700">
          النوع
          <select name="kind" defaultValue="custom" className={field}>
            {Object.entries(CERT_KIND_LABELS)
              .filter(([k]) => k !== 'serd')
              .map(([k, label]) => (
                <option key={k} value={k}>
                  {label}
                </option>
              ))}
          </select>
        </label>
        <label className="text-sm text-gray-700 sm:col-span-2">
          عنوان الشهادة
          <input name="title" required minLength={2} maxLength={120} placeholder="شهادة تفوّق" className={field} />
        </label>
        <label className="text-sm text-gray-700 sm:col-span-2">
          النص (اختياري)
          <textarea name="description" maxLength={500} rows={2} placeholder="لتفوّقه في حفظ سورة ..." className={field} />
        </label>
        <div className="sm:col-span-2">
          <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText="جاري الإصدار...">
            إصدار الشهادة
          </SubmitButton>
          <span className="mr-3 text-xs text-gray-500">شهادة السرد تُصدر من صفحة السرد بعد الاعتماد.</span>
        </div>
      </form>

      <div className="mb-8 overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-3 py-2 text-right">الطالب</th>
              <th className="px-3 py-2 text-right">الشهادة</th>
              <th className="px-3 py-2 text-right">التاريخ</th>
              <th className="px-3 py-2 text-right">الرقم</th>
              <th className="px-3 py-2"></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((c) => (
              <tr key={c.id} className="border-t">
                <td className="px-3 py-2">{c.recipient_name}</td>
                <td className="px-3 py-2">
                  {c.title} <span className="text-xs text-gray-400">({CERT_KIND_LABELS[c.kind] ?? c.kind})</span>
                  {c.revoked_at && <span className="mr-2 rounded bg-red-50 px-2 py-0.5 text-xs text-red-600">ملغاة</span>}
                </td>
                <td className="px-3 py-2">{fmtDay(c.issued_at)}</td>
                <td className="px-3 py-2 font-mono text-xs" dir="ltr">
                  {c.serial}
                </td>
                <td className="flex items-center gap-3 px-3 py-2 text-left">
                  <a href={`/certificates/${c.id}` as never} className="text-brand hover:underline">
                    عرض / طباعة
                  </a>
                  {!c.revoked_at && (
                    <form action={revokeCertificate}>
                      <input type="hidden" name="orgId" value={org.id} />
                      <input type="hidden" name="id" value={c.id} />
                      <ConfirmSubmitButton
                        confirmMessage="سحب هذه الشهادة؟ ستظهر كملغاة عند التحقق منها."
                        pendingText="..."
                        className="text-xs text-red-600 hover:underline"
                      >
                        سحب
                      </ConfirmSubmitButton>
                    </form>
                  )}
                </td>
              </tr>
            ))}
            {!rows.length && (
              <tr>
                <td colSpan={5} className="px-3 py-6 text-center text-gray-400">
                  لم تصدر شهادات بعد
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {isAdmin && settings && (
        <form action={saveCertificateSettings} className="grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-2">
          <input type="hidden" name="orgId" value={org.id} />
          <h2 className="text-sm font-semibold sm:col-span-2">تخصيص الشهادة لمركزك</h2>
          <label className="text-sm text-gray-700">
            اسم الموقِّع
            <input name="signerName" defaultValue={settings.signer_name ?? ''} maxLength={80} className={field} />
          </label>
          <label className="text-sm text-gray-700">
            صفته
            <input name="signerTitle" defaultValue={settings.signer_title ?? ''} maxLength={80} placeholder="مدير المركز" className={field} />
          </label>
          <label className="text-sm text-gray-700 sm:col-span-2">
            عبارة أسفل الشهادة
            <input name="footer" defaultValue={settings.footer ?? ''} maxLength={200} placeholder="بارك الله فيه ونفع به" className={field} />
          </label>
          <label className="text-sm text-gray-700 sm:col-span-2">
            عنوان شهادة السرد
            <input name="serdTitle" defaultValue={settings.serd_title} maxLength={120} className={field} />
          </label>
          <label className="flex items-center gap-2 text-sm text-gray-700 sm:col-span-2">
            <input type="checkbox" name="autoSerd" defaultChecked={settings.auto_serd} />
            إصدار شهادة السرد تلقائيًا عند اعتماد جلسة ناجحة
          </label>
          <p className="text-xs text-gray-500 sm:col-span-2">التغييرات تسري على الشهادات القادمة فقط؛ ما صدر سابقًا يبقى كما هو.</p>
          <div className="sm:col-span-2">
            <SubmitButton className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50" pendingText="جاري الحفظ...">
              حفظ الإعدادات
            </SubmitButton>
          </div>
        </form>
      )}
    </div>
  );
}
