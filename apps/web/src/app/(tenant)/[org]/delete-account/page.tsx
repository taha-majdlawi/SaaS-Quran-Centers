import { LegalPage } from '@/components/legal-page';

export default async function DeleteAccountPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  return (
    <LegalPage orgSlug={org} title="طلب حذف الحساب والبيانات">
      {({ name, contactEmail }) => (
        <>
          <p>
            لطلب حذف حسابك أو بيانات ابنك المرتبطة بـ{name} (الاسم، وسجل الحضور والتسميع والسرد، والرسائل)، تواصل مع الإدارة
            {contactEmail ? (
              <>
                {' '}
                عبر{' '}
                <a href={`mailto:${contactEmail}`} className="text-brand hover:underline" dir="ltr">
                  {contactEmail}
                </a>
              </>
            ) : (
              ' عبر وسائل التواصل المعلنة للمركز'
            )}
            .
          </p>
          <p>تُحذف البيانات بعد التحقق من الطلب، عدا ما يلزم الاحتفاظ به لأغراض قانونية أو مالية.</p>
        </>
      )}
    </LegalPage>
  );
}
