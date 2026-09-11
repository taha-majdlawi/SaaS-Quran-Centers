import { signInToTenant } from './actions';

// Replaces wep-eqraa-center/admin/login - now scoped to one organization by
// slug (via the hidden orgSlug field) instead of "the one admin account on
// this project".
export default async function TenantLoginPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string }>;
}) {
  const { org } = await params;
  const { error } = await searchParams;

  return (
    <main className="mx-auto flex min-h-screen max-w-sm flex-col justify-center p-8">
      <h1 className="mb-1 text-2xl font-bold text-brand">تسجيل الدخول</h1>
      <p className="mb-6 text-sm text-gray-500">{org}</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={signInToTenant} className="flex flex-col gap-3">
        <input type="hidden" name="orgSlug" value={org} />
        <input
          type="email"
          name="email"
          placeholder="البريد الإلكتروني"
          required
          className="rounded border px-3 py-2 text-sm"
        />
        <input
          type="password"
          name="password"
          placeholder="كلمة السر"
          required
          className="rounded border px-3 py-2 text-sm"
        />
        <button type="submit" className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          دخول
        </button>
      </form>
    </main>
  );
}
