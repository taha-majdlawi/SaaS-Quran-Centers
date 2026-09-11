export default function PlatformFeatureFlagsPage() {
  return (
    <div>
      <h1 className="mb-2 text-2xl font-bold">أعلام الميزات</h1>
      <p className="text-sm text-gray-500">
        سكيلتون فقط - يدير جدول <code>feature_flags</code> (0007_platform_and_admin.sql)،
        سواء كإعداد افتراضي للمنصة (organization_id فارغ) أو مخصص لمركز معيّن.
      </p>
    </div>
  );
}
