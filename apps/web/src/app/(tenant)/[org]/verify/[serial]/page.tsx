import { OrgLogo } from '@/components/org-logo';
import { createClient } from '@/lib/supabase/server';
import { getPublicSite } from '@/lib/tenant/public-site';
import { fmtDay } from '@/lib/reports/format';

interface Verified {
  valid: boolean;
  title: string;
  recipient_name: string;
  issued_at: string;
  center: { name: string; logo_url: string | null; primary_color: string };
}

/** Public: anyone holding a certificate's serial can confirm it is genuine. */
export default async function VerifyPage({ params }: { params: Promise<{ org: string; serial: string }> }) {
  const { org: slug, serial } = await params;
  const site = await getPublicSite(slug);
  const supabase = await createClient();
  const { data } = await supabase.rpc('verify_certificate', { p_slug: slug, p_serial: decodeURIComponent(serial).slice(0, 40) });
  const c = data as Verified | null;
  const name = site?.name ?? 'بستان القرآن';

  return (
    <div
      className="flex min-h-screen flex-col"
      style={{ '--brand-primary': site?.primary_color, '--brand-secondary': site?.secondary_color } as React.CSSProperties}
    >
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <span className="flex items-center gap-2 font-bold text-brand">
          <OrgLogo name={name} logoUrl={site?.logo_url} size={32} />
          {name}
        </span>
      </header>
      <main className="mx-auto w-full max-w-lg flex-1 px-6 py-12 text-center">
        <h1 className="mb-6 text-2xl font-bold">التحقق من شهادة</h1>
        {!c ? (
          <div className="rounded-lg border border-red-200 bg-red-50 p-6 text-red-700">
            <p className="text-lg font-bold">لم نجد شهادة بهذا الرقم</p>
            <p className="mt-1 text-sm">تأكد من الرقم المكتوب على الشهادة.</p>
          </div>
        ) : c.valid ? (
          <div className="rounded-lg border border-green-200 bg-green-50 p-6">
            <p className="text-lg font-bold text-green-700">✓ شهادة صحيحة</p>
            <p className="mt-3 text-xl font-bold">{c.recipient_name}</p>
            <p className="mt-1 text-gray-700">{c.title}</p>
            <p className="mt-1 text-sm text-gray-500">
              صادرة عن {c.center.name} بتاريخ {fmtDay(c.issued_at)}
            </p>
          </div>
        ) : (
          <div className="rounded-lg border border-amber-200 bg-amber-50 p-6 text-amber-800">
            <p className="text-lg font-bold">هذه الشهادة أُلغيت</p>
            <p className="mt-1 text-sm">{c.title} — {c.recipient_name}</p>
          </div>
        )}
      </main>
    </div>
  );
}
