import { redirect } from 'next/navigation';
import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { signOut } from '@/lib/auth/actions';
import { createClient } from '@/lib/supabase/server';
import { getPlatformContext } from '@/lib/platform/get-platform-context';
import { verifiedTotp } from '@/lib/platform/mfa';
import { continueWithoutMfa, verifyOwnerCode } from './actions';

/**
 * The owner's second factor (0094): the code from an authenticator app
 * (Google Authenticator, Microsoft Authenticator, 1Password...) after the password.
 * The first time, the factor is set up here: scan the code, enter the six digits.
 */
export default async function OwnerMfaPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;
  const platform = await getPlatformContext();
  if (!platform.isOwner) redirect('/login');
  if (platform.mfa === 'ok') redirect('/');

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) redirect('/login');

  const codeField = (factorId: string) => (
    <form action={verifyOwnerCode} className="flex flex-col gap-3">
      <input type="hidden" name="factorId" value={factorId} />
      <label className={authLabelClass}>
        الرمز من تطبيق المصادقة
        <input
          name="code"
          required
          inputMode="numeric"
          autoComplete="one-time-code"
          pattern="[0-9 ]{6,7}"
          maxLength={7}
          autoFocus
          dir="ltr"
          className={`mt-1 text-center text-lg tracking-[0.4em] ${authInputClass}`}
        />
      </label>
      <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText="جاري التحقق...">
        تحقّق
      </SubmitButton>
    </form>
  );
  const signOutForm = (
    <form action={signOut}>
      <SubmitButton className="text-gray-500 hover:text-red-600" pendingText="...">
        تسجيل خروج ({platform.email})
      </SubmitButton>
    </form>
  );

  // already set up: the code, every sign-in
  const factor = verifiedTotp(user)[0];
  if (factor) {
    return (
      <AuthCard title="التحقق بخطوتين" subtitle="افتح تطبيق المصادقة واكتب الرمز الحالي" error={error} languages={false} footer={signOutForm}>
        {codeField(factor.id)}
      </AuthCard>
    );
  }

  // first time: drop any setup left unfinished, then start a new one
  for (const f of user.factors ?? []) {
    if (f.status !== 'verified') await supabase.auth.mfa.unenroll({ factorId: f.id });
  }
  const { data: enrolled, error: enrollError } = await supabase.auth.mfa.enroll({
    factorType: 'totp',
    friendlyName: `بستان القرآن ${new Date().toISOString().slice(0, 16)}`,
    issuer: 'Bustan Al-Quran',
  });

  if (enrollError || !enrolled || enrolled.type !== 'totp') {
    return (
      <AuthCard title="التحقق بخطوتين" subtitle="لوحة مالك المنصة" error={error} languages={false} footer={signOutForm}>
        <p className="mb-4 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-800">
          تعذّر إعداد التحقق بخطوتين: {enrollError?.message ?? 'رد غير متوقع'}. إذا كان معطّلًا في مشروع Supabase فعّله من
          Authentication ← Multi-Factor (TOTP)، ثم أعد تحميل الصفحة.
        </p>
        <form action={continueWithoutMfa}>
          <SubmitButton className={authButtonClass} pendingText="...">
            متابعة بدونه الآن
          </SubmitButton>
        </form>
      </AuthCard>
    );
  }

  return (
    <AuthCard
      title="فعّل التحقق بخطوتين"
      subtitle="حساب المالك هو الأقوى في المنصة: بعد اليوم يلزم الرمز مع كلمة السر"
      error={error}
      languages={false}
      footer={signOutForm}
    >
      <ol className="mb-4 list-decimal space-y-1 ps-5 text-sm text-gray-600">
        <li>ثبّت تطبيق مصادقة على جوالك (Google Authenticator أو Microsoft Authenticator).</li>
        <li>امسح الرمز التالي من التطبيق.</li>
        <li>اكتب الرمز من ستة أرقام الذي يظهر فيه.</li>
      </ol>
      <img src={enrolled.totp.qr_code} alt="رمز QR للتحقق بخطوتين" width={180} height={180} className="mx-auto mb-3 rounded-lg border bg-white p-2" />
      <details className="mb-4 text-center text-xs text-gray-500">
        <summary className="cursor-pointer">لا أستطيع المسح</summary>
        <p className="mt-2">أدخل هذا المفتاح يدويًا في التطبيق:</p>
        <code dir="ltr" className="mt-1 block select-all break-all rounded bg-gray-100 px-2 py-1 font-mono text-sm text-gray-800">
          {enrolled.totp.secret}
        </code>
      </details>
      {codeField(enrolled.id)}
      <p className="mt-4 text-xs text-gray-500">
        إذا ضاع جوالك: احذف العامل من لوحة Supabase (Authentication ← Users ← حسابك) ثم ادخل وأعد الإعداد.
      </p>
    </AuthCard>
  );
}
