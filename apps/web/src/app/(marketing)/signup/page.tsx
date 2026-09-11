import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { signUpAndCreateOrganization } from './actions';

const BENEFITS = [
  'صفحة إدارة خاصة بمركزك على رابط مستقل',
  'أضف معلمين وطلابًا وحلقات، وتحكم بصلاحيات كل واحد',
  'سجّل الحضور، التسميع، النقاط والشارات من مكان واحد',
];

// Creates the auth user AND the organization + first admin membership in
// one step (see supabase/migrations/0010_self_serve_signup.sql), then sends
// the new admin straight to their own subdomain's dashboard.
export default async function SignupPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;

  return (
    <AuthCard
      title="سجّل مركزك"
      subtitle="دقيقة واحدة، وتقدر تبدأ فورًا بلوحة إدارة كاملة لمركزك"
      error={error}
      footer={
        <>
          عندك مركز مسجّل من قبل؟{' '}
          <a href="/login" className="font-semibold text-brand">
            سجّل دخولك
          </a>
        </>
      }
    >
      <ul className="mb-6 flex flex-col gap-2 text-sm text-gray-600">
        {BENEFITS.map((b) => (
          <li key={b} className="flex items-start gap-2">
            <span className="mt-0.5 text-brand">✓</span>
            <span>{b}</span>
          </li>
        ))}
      </ul>

      <form action={signUpAndCreateOrganization} className="flex flex-col gap-3">
        <label className={authLabelClass}>
          اسم المركز
          <input
            name="orgName"
            required
            placeholder="مركز النور لتحفيظ القرآن"
            className={`mt-1 ${authInputClass}`}
          />
        </label>

        <label className={authLabelClass}>
          رابط المركز
          <div className="mt-1 flex items-center overflow-hidden rounded-lg border border-gray-300 text-sm">
            <input
              name="slug"
              required
              pattern="[a-z0-9]+(-[a-z0-9]+)*"
              placeholder="alnoor"
              className="w-full px-3 py-2.5 outline-none"
            />
            <span className="whitespace-nowrap bg-gray-50 px-3 py-2.5 text-gray-500">.bustan-alquran.com</span>
          </div>
        </label>

        <label className={authLabelClass}>
          البريد الإلكتروني
          <input type="email" name="email" required className={`mt-1 ${authInputClass}`} />
        </label>

        <label className={authLabelClass}>
          كلمة السر
          <input type="password" name="password" required minLength={6} className={`mt-1 ${authInputClass}`} />
        </label>

        <button type="submit" className={`mt-2 ${authButtonClass}`}>
          إنشاء المركز
        </button>
      </form>
    </AuthCard>
  );
}
