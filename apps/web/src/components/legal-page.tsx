import { createClient } from '@/lib/supabase/server';

/**
 * Shared chrome for the static legal/consent pages (privacy, parent-consent,
 * trip-consent, delete-account, support) - all public, unauthenticated,
 * reachable pre-login (see middleware.ts's PUBLIC_TENANT_PATHS). Looks up
 * just the org's name for the header - `organizations_select_public`
 * (migration 0008) already permits this for an anon caller, same as the
 * tenant root page's public site.
 */
export async function LegalPage({
  orgSlug,
  title,
  children,
}: {
  orgSlug: string;
  title: string;
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const { data: org } = await supabase.from('organizations').select('name').eq('slug', orgSlug).maybeSingle();

  return (
    <div className="flex min-h-screen flex-col">
      <header className="flex items-center justify-between border-b bg-white px-6 py-4">
        <a href="/" className="font-bold text-brand">
          {org?.name ?? 'بستان القرآن'}
        </a>
        <a href="/login" className="text-sm text-brand hover:underline">
          تسجيل الدخول
        </a>
      </header>

      <main className="mx-auto flex w-full max-w-2xl flex-1 flex-col gap-4 px-6 py-12">
        <h1 className="text-2xl font-bold">{title}</h1>
        <div className="flex flex-col gap-3 text-sm leading-7 text-gray-700">{children}</div>
      </main>
    </div>
  );
}
