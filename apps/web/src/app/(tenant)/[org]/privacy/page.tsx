import { LegalPage } from '@/components/legal-page';

export default async function PrivacyPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;

  return (
    <LegalPage orgSlug={org} title="سياسة الخصوصية">
      <p>
        نجمع فقط المعلومات اللازمة لإدارة تسجيل الطلاب ومتابعة تقدمهم بالحفظ والحضور: الاسم، معلومات
        التواصل، وسجلات الحضور والتقييم الخاصة بالمركز الذي تنتمي إليه.
      </p>
      <p>
        هذه البيانات مقصورة على مركزك فقط، ولا يمكن لأي مركز آخر على المنصة الوصول إليها - كل مركز
        معزول تمامًا عن باقي المراكز.
      </p>
      <p>
        لا نشارك بياناتك مع أي طرف ثالث لأغراض تسويقية. يمكن لولي الأمر أو الطالب طلب الاطلاع على
        البيانات المخزنة أو حذفها بالتواصل مع إدارة المركز مباشرة، أو عبر{' '}
        <a href="/delete-account" className="text-brand hover:underline">
          صفحة طلب حذف الحساب
        </a>
        .
      </p>
    </LegalPage>
  );
}
