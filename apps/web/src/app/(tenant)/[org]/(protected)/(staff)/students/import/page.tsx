import { notFound } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { StudentsImportForm } from '@/components/students-import-form';
import { getI18n } from '@/lib/i18n/server';

export default async function ImportStudentsPage({ params }: { params: Promise<{ org: string }> }) {
  const { org: slug } = await params;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (!org.myPermissions.includes('students')) notFound();
  return (
    <div className="max-w-2xl">
      <a href="/students" className="text-sm text-brand hover:underline">
        {S.studentsImport.back}
      </a>
      <h1 className="mb-2 mt-2 text-2xl font-bold">{S.studentsImport.title}</h1>
      <p className="mb-4 text-sm text-gray-600">
        {S.studentsImport.intro}
      </p>
      <StudentsImportForm orgId={org.id} labels={S.studentsImport} />
    </div>
  );
}
