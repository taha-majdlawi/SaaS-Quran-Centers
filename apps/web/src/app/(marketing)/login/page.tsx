import { AuthCard } from '@/components/auth-card';
import { authLabelClass, authButtonClass } from '@/components/auth-styles';
import { findOrgLogin } from './actions';

export default async function LoginLookupPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;

  return (
    <AuthCard
      title="تسجيل الدخول"
      subtitle="اكتب رابط مركزك للانتقال لصفحة دخوله"
      error={error}
      footer={
        <>
          ليس لديك مركز بعد؟{' '}
          <a href="/signup" className="font-semibold text-brand">
            سجّل مركزك الآن
          </a>
        </>
      }
    >
      <form action={findOrgLogin} className="flex flex-col gap-3">
        <label className={authLabelClass}>
          رابط المركز
          <div className="mt-1 flex items-center overflow-hidden rounded-lg border border-gray-300 text-sm">
            <input name="slug" required placeholder="alnoor" className="w-full px-3 py-2.5 outline-none" />
            <span className="whitespace-nowrap bg-gray-50 px-3 py-2.5 text-gray-500">.bustan-alquran.com</span>
          </div>
        </label>
        <button type="submit" className={authButtonClass}>
          متابعة لتسجيل الدخول
        </button>
      </form>

      <p className="mt-5 text-center text-xs text-gray-400">
        مالك المنصة؟{' '}
        <a href="https://admin.bustan-alquran.com/login" className="underline">
          سجّل دخولك من هنا
        </a>
      </p>
    </AuthCard>
  );
}
