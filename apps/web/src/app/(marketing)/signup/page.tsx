import { signUpAndCreateOrganization } from './actions';

// Creates the auth user AND the organization + first admin membership in
// one step (see supabase/migrations/0010_self_serve_signup.sql), then sends
// the new admin straight to their own subdomain's dashboard.
export default async function SignupPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;

  return (
    <main className="mx-auto flex min-h-screen max-w-md flex-col justify-center p-8">
      <h1 className="mb-1 text-2xl font-bold text-brand">سجّل مركزك</h1>
      <p className="mb-6 text-sm text-gray-500">دقيقة واحدة، وتقدر تبدأ فورًا</p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}

      <form action={signUpAndCreateOrganization} className="flex flex-col gap-3">
        <label className="text-sm font-medium text-gray-700">
          اسم المركز
          <input name="orgName" required placeholder="مركز النور لتحفيظ القرآن" className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          رابط المركز
          <div className="mt-1 flex items-center overflow-hidden rounded border text-sm">
            <input
              name="slug"
              required
              pattern="[a-z0-9]+(-[a-z0-9]+)*"
              placeholder="alnoor"
              className="w-full px-3 py-2 outline-none"
            />
            <span className="whitespace-nowrap bg-gray-50 px-3 py-2 text-gray-500">.bustan-alquran.com</span>
          </div>
        </label>

        <label className="text-sm font-medium text-gray-700">
          البريد الإلكتروني
          <input type="email" name="email" required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <label className="text-sm font-medium text-gray-700">
          كلمة السر
          <input
            type="password"
            name="password"
            required
            minLength={6}
            className="mt-1 w-full rounded border px-3 py-2 text-sm"
          />
        </label>

        <button type="submit" className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
          إنشاء المركز
        </button>
      </form>
    </main>
  );
}
