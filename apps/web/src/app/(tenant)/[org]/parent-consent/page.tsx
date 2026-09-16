import { LegalPage } from '@/components/legal-page';

export default async function ParentConsentPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;

  return (
    <LegalPage orgSlug={org} title="موافقة ولي الأمر">
      <p>
        عند تسجيل ابنك/ابنتك بالمركز، يقوم حساب ولي الأمر بمتابعة سجل الحفظ والحضور والتقييم الخاص به
        داخل التطبيق. هذه المتابعة تتم بموافقتك كولي أمر عند إتمام التسجيل مع إدارة المركز.
      </p>
      <p>
        يمكن لولي الأمر أي وقت مراجعة بيانات ابنه من داخل حسابه بالتطبيق، أو طلب توضيح أو تعديل من
        إدارة المركز مباشرة.
      </p>
      <p>
        بعض فعاليات المركز (كالرحلات) تتطلب موافقة صريحة إضافية لكل فعالية على حدة - راجع{' '}
        <a href="/trip-consent" className="text-brand hover:underline">
          صفحة موافقة الفعاليات
        </a>{' '}
        للتفاصيل.
      </p>
    </LegalPage>
  );
}
