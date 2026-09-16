import { LegalPage } from '@/components/legal-page';
import { createClient } from '@/lib/supabase/server';

export default async function DeleteAccountPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const supabase = await createClient();
  const { data: orgRow } = await supabase.from('organizations').select('id').eq('slug', org).maybeSingle();
  // Only readable at all when the admin turned the public site on
  // (site_settings_select_public_or_member) - null otherwise, which the
  // fallback mailto handles.
  const { data: site } = orgRow
    ? await supabase.from('site_settings').select('contact_email').eq('organization_id', orgRow.id).maybeSingle()
    : { data: null };
  const contactEmail = site?.contact_email;

  return (
    <LegalPage orgSlug={org} title="طلب حذف الحساب والبيانات">
      <p>
        لطلب حذف حسابك أو بيانات ابنك المرتبطة بالمركز (الاسم، سجل الحضور، التقييم، الرسائل)، تواصل
        مع إدارة المركز مباشرة
        {contactEmail ? (
          <>
            {' '}
            عبر{' '}
            <a href={`mailto:${contactEmail}`} className="text-brand hover:underline" dir="ltr">
              {contactEmail}
            </a>
          </>
        ) : (
          ' عبر معلومات التواصل الظاهرة على صفحة المركز الرئيسية'
        )}
        .
      </p>
      <p>
        سيتم حذف البيانات خلال مدة معقولة بعد التحقق من الطلب، باستثناء ما يلزم الاحتفاظ به لأغراض
        قانونية أو مالية (كسجلات الاشتراك المدفوع).
      </p>
    </LegalPage>
  );
}
