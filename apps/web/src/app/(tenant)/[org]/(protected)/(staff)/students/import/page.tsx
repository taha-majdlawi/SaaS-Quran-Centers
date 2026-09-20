import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { StudentsImportForm } from '@/components/students-import-form';

export default async function ImportStudentsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  if (!org.myPermissions.includes('students')) notFound();
  return (
    <div className="max-w-2xl">
      <a href="/students" className="text-sm text-brand hover:underline">
        ← الطلاب
      </a>
      <h1 className="mb-2 mt-2 text-2xl font-bold">استيراد طلاب من ملف</h1>
      <p className="mb-4 text-sm text-gray-600">
        السطر الأول عناوين الأعمدة: <b dir="ltr">name</b> (الاسم — مطلوب)، <b dir="ltr">circle</b> (اسم الحلقة كما هو — مطلوب)، ثم اختياريًا{' '}
        <b dir="ltr">code, birth_date, phone, whatsapp, address</b>. العناوين بالعربية مقبولة أيضًا (الاسم، الحلقة، الرقم، تاريخ الميلاد، الهاتف، واتساب، العنوان). إن تُرك رقم الطالب يُولَّد تلقائيًا. الحد 500 طالب في المرة.
        يُنشأ سجل الطالب فقط؛ حساب الدخول يُنشأ لاحقًا من صفحة الطالب.
      </p>
      <StudentsImportForm orgId={org.id} />
    </div>
  );
}
