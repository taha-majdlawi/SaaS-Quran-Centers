import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
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
    <AuthCard
      title="تسجيل الدخول"
      subtitle={`لوحة إدارة "${org}" - للمعلمين والإدارة وأولياء الأمور`}
      error={error}
      footer={
        <div className="flex flex-col gap-1">
          <span>
            نسيت رابط مركزك؟{' '}
            <a href={`https://bustan-alquran.com/login`} className="font-semibold text-brand">
              دوّر عليه من هنا
            </a>
          </span>
          <span>
            ليس لديك مركز؟{' '}
            <a href="https://bustan-alquran.com/signup" className="font-semibold text-brand">
              سجّل مركزك الآن
            </a>
          </span>
        </div>
      }
    >
      <form action={signInToTenant} className="flex flex-col gap-3">
        <input type="hidden" name="orgSlug" value={org} />
        <label className={authLabelClass}>
          البريد الإلكتروني
          <input type="email" name="email" required className={`mt-1 ${authInputClass}`} />
        </label>
        <label className={authLabelClass}>
          كلمة السر
          <input type="password" name="password" required className={`mt-1 ${authInputClass}`} />
        </label>
        <button type="submit" className={`mt-2 ${authButtonClass}`}>
          دخول
        </button>
      </form>
    </AuthCard>
  );
}
