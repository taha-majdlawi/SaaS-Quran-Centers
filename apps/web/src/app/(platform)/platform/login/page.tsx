import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { signInToPlatform } from './actions';

export default async function PlatformLoginPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;

  return (
    <AuthCard title="لوحة مالك المنصة" subtitle="بستان القرآن" error={error}>
      <form action={signInToPlatform} className="flex flex-col gap-3">
        <label className={authLabelClass}>
          البريد الإلكتروني
          <input type="email" name="email" required className={`mt-1 ${authInputClass}`} />
        </label>
        <label className={authLabelClass}>
          كلمة السر
          <input type="password" name="password" required className={`mt-1 ${authInputClass}`} />
        </label>
        <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText="جاري تسجيل الدخول...">
          دخول
        </SubmitButton>
      </form>
    </AuthCard>
  );
}
