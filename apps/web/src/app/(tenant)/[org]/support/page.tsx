import { LegalPage } from '@/components/legal-page';
import { createClient } from '@/lib/supabase/server';

export default async function SupportPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const supabase = await createClient();
  const { data: orgRow } = await supabase.from('organizations').select('id').eq('slug', org).maybeSingle();
  const { data: site } = orgRow
    ? await supabase.from('site_settings').select('contact_email').eq('organization_id', orgRow.id).maybeSingle()
    : { data: null };
  const contactEmail = site?.contact_email;

  return (
    <LegalPage orgSlug={org} title="الدعم والمساعدة">
      <p>لأي استفسار عن استخدام التطبيق، تسجيل الدخول، أو بيانات طالب مرتبط بحسابك، تواصل مع إدارة المركز.</p>
      {contactEmail ? (
        <p>
          البريد الإلكتروني:{' '}
          <a href={`mailto:${contactEmail}`} className="text-brand hover:underline" dir="ltr">
            {contactEmail}
          </a>
        </p>
      ) : (
        <p>معلومات التواصل الخاصة بالمركز متاحة على صفحته الرئيسية.</p>
      )}
      <p>
        إذا نسيت رابط مركزك، يمكنك البحث عنه من{' '}
        <a href="https://bustan-alquran.com/login" className="text-brand hover:underline">
          صفحة تسجيل الدخول العامة
        </a>
        .
      </p>
    </LegalPage>
  );
}
