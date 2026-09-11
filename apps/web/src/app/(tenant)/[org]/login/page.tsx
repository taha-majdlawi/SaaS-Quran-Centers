// Replaces wep-eqraa-center/admin/login - Supabase-auth gate, now scoped to
// one organization by slug instead of "the one admin account on this project".
export default async function TenantLoginPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  return (
    <main className="mx-auto max-w-md p-8">
      <h1 className="mb-4 text-2xl font-bold">تسجيل الدخول - {org}</h1>
      <p className="text-gray-500">نموذج الدخول - سكيلتون فقط.</p>
    </main>
  );
}
