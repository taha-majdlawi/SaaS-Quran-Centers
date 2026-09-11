export function ModulePlaceholder({ title, legacyPath }: { title: string; legacyPath: string }) {
  return (
    <div>
      <h1 className="mb-2 text-2xl font-bold">{title}</h1>
      <p className="text-sm text-gray-500">
        سكيلتون فقط - المنطق ينتقل من{' '}
        <code className="rounded bg-gray-100 px-1.5 py-0.5">wep-eqraa-center/{legacyPath}</code>، مع
        إضافة فلترة <code className="rounded bg-gray-100 px-1.5 py-0.5">organization_id</code> (تأتي
        تلقائيًا عبر RLS - لا حاجة لتعديل شكل الاستعلامات).
      </p>
    </div>
  );
}
