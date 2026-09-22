import { headers } from 'next/headers';
import { OrgLogo } from '@/components/org-logo';
import { QuranFont } from '@/components/quran-font';
import { PrintButton } from '@/components/print-button';
import { fmtDay, type CertificateFull } from '@/lib/reports/format';

/**
 * The certificate as printed: landscape A4, the center's colour and logo,
 * the wording frozen at issue time, and a serial anyone can check at /verify.
 * Colours are inline (the brand colour is a runtime value, not a Tailwind token).
 */
export async function CertificateView({ cert, back }: { cert: CertificateFull; back: string }) {
  const host = (await headers()).get('host') ?? '';
  const color = cert.center.primary_color || '#1E7A54';

  return (
    <QuranFont>
      <style>{`@media print { @page { size: A4 landscape; margin: 0 } body { background: #fff } }`}</style>
      <div className="mb-4 flex items-center justify-between print:hidden">
        <a href={back as never} className="text-sm text-brand hover:underline">
          ← رجوع
        </a>
        <PrintButton />
      </div>

      <div
        className="relative mx-auto flex aspect-[297/210] w-full max-w-4xl flex-col items-center justify-between bg-white p-10 text-center shadow print:max-w-none print:shadow-none"
        style={{ border: `10px double ${color}` }}
      >
        {cert.revoked_at && (
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="-rotate-12 rounded border-4 border-red-600 px-6 py-2 text-5xl font-bold text-red-600 opacity-40">ملغاة</span>
          </div>
        )}

        <div className="flex flex-col items-center gap-2">
          <OrgLogo name={cert.center.name} logoUrl={cert.center.logo_url} size={64} />
          <p className="text-lg font-bold" style={{ color }}>
            {cert.center.name}
          </p>
        </div>

        <div className="flex flex-col items-center gap-3">
          <h1 className="font-quran text-4xl font-bold" style={{ color }}>
            {cert.title}
          </h1>
          <p className="text-sm text-gray-500">تشهد إدارة المركز بأن</p>
          <p className="font-quran text-3xl font-bold">{cert.recipient_name}</p>
          {cert.description && <p className="max-w-2xl text-lg leading-8 text-gray-700">{cert.description}</p>}
          {cert.footer && <p className="text-sm text-gray-500">{cert.footer}</p>}
        </div>

        <div className="flex w-full items-end justify-between text-sm text-gray-600">
          <div className="text-right">
            <p>{fmtDay(cert.issued_at)}</p>
            <p className="font-mono text-xs text-gray-400" dir="ltr">
              {cert.serial}
            </p>
          </div>
          <div className="text-left" dir="ltr">
            <p className="text-xs text-gray-400">للتحقق من الشهادة:</p>
            <p className="font-mono text-xs text-gray-500">
              {host}/verify/{cert.serial}
            </p>
          </div>
          {(cert.signer_name || cert.signer_title) && (
            <div className="min-w-40 border-t border-gray-400 pt-1 text-center">
              <p className="font-semibold text-gray-800">{cert.signer_name}</p>
              <p className="text-xs">{cert.signer_title}</p>
            </div>
          )}
        </div>
      </div>
    </QuranFont>
  );
}
