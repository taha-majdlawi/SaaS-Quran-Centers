import { LegalPage } from '@/components/legal-page';

export default async function PrivacyPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  return (
    <LegalPage orgSlug={org} title="سياسة الخصوصية">
      {({ name }) => (
        <>
          <p>
            يجمع {name} المعلومات اللازمة فقط لإدارة تسجيل الطلاب ومتابعة تقدمهم: الاسم، وبيانات التواصل، وسجلات التسميع
            والسرد والحضور الخاصة بهذا المركز.
          </p>
          <p>
            هذه البيانات مقصورة على مركزك، ولا يصل إليها أي مركز آخر على المنصة؛ فكل مركز معزول عن غيره تمامًا. ولا يرى
            الطالب أو ولي الأمر إلا بيانات ابنه هو.
          </p>
          <p>
            لا تُشارَك بياناتك مع أي جهة لأغراض تسويقية. ويمكن لولي الأمر أو الطالب طلب الاطلاع على بياناته أو حذفها عبر{' '}
            <a href="/delete-account" className="text-brand hover:underline">
              صفحة طلب الحذف
            </a>{' '}
            أو بالتواصل مع إدارة المركز.
          </p>
        </>
      )}
    </LegalPage>
  );
}
