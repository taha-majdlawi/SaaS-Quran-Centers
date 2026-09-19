import { LegalPage } from '@/components/legal-page';

export default async function SupportPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  return (
    <LegalPage orgSlug={org} title="الدعم والمساعدة">
      {({ name, contactEmail }) => (
        <>
          <p>
            إن واجهتك مشكلة في الدخول أو في استخدام التطبيق، تواصل مع إدارة {name}
            {contactEmail ? (
              <>
                {' '}
                عبر{' '}
                <a href={`mailto:${contactEmail}`} className="text-brand hover:underline" dir="ltr">
                  {contactEmail}
                </a>
              </>
            ) : (
              ' مباشرة'
            )}
            .
          </p>
          <p>
            للدخول تحتاج: <b>رمز المركز</b> + <b>رقم الدخول أو البريد</b> + <b>كلمة السر</b> التي سلّمتها لك الإدارة. إن نسيتَ
            كلمة السر تطلب الإدارة تغييرها لك.
          </p>
        </>
      )}
    </LegalPage>
  );
}
