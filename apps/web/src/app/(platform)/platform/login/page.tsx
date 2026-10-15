import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { signInToPlatform } from './actions';
import { redirect } from 'next/navigation';
import { getPlatformContext } from '@/lib/platform/get-platform-context';
import { safeNext } from '@/lib/auth/next';

export default async function PlatformLoginPage({ searchParams }: { searchParams: Promise<{ error?: string; next?: string }> }) {
  const { error, next: nextParam } = await searchParams;
  const next = safeNext(nextParam);
  // already signed in as an owner: the console (its layout asks for the code if needed)
  if ((await getPlatformContext()).isOwner) redirect((next ?? '/') as never);

  return (
    <AuthCard title="لوحة مالك المنصة" subtitle="بستان القرآن" error={error} languages={false}>
      <form action={signInToPlatform} className="flex flex-col gap-3">
        {next && <input type="hidden" name="next" value={next} />}
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
