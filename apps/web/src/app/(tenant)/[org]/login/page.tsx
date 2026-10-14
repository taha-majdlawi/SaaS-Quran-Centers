import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { getPublicSite } from '@/lib/tenant/public-site';
import { signInToTenant } from './actions';
import { signInWithGoogle } from '@/lib/auth/google';
import { GoogleButton, OrLine } from '@/components/google-button';
import { googleEnabled } from '@/lib/auth/google-enabled';
import { getI18n } from '@/lib/i18n/server';

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
  const site = await getPublicSite(org);
  const { t } = await getI18n();
  const google = await googleEnabled();

  return (
    <AuthCard
      title={t.common.login}
      brand={site ? { name: site.name, logoUrl: site.logo_url } : undefined}
      subtitle={t.login.subtitle}
      error={error}
      footer={
        <div className="flex flex-col gap-1">
          <span>
            {t.login.forgotCenter}{' '}
            <a href={`https://bustan-alquran.com/login`} className="font-semibold text-brand">
              {t.login.findIt}
            </a>
          </span>
          <span>
            {t.login.noCenter}{' '}
            <a href="https://bustan-alquran.com/signup" className="font-semibold text-brand">
              {t.common.registerCenterNow}
            </a>
          </span>
        </div>
      }
    >
      <form action={signInToTenant} className="flex flex-col gap-3">
        <input type="hidden" name="orgSlug" value={org} />
        <label className={authLabelClass}>
          {t.common.identifier}
          <input name="identifier" required dir="ltr" autoComplete="username" className={`mt-1 ${authInputClass}`} />
        </label>
        <label className={authLabelClass}>
          {t.common.password}
          <input type="password" name="password" required className={`mt-1 ${authInputClass}`} />
        </label>
        <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText={t.login.signingIn}>
          {t.login.submit}
        </SubmitButton>
        <a href="/forgot-password" className="text-center text-sm font-semibold text-brand">
          {t.login.forgotPassword}
        </a>
      </form>
      {/* teachers and admins with an email: their Google account is the same account */}
      {google && (
        <form action={signInWithGoogle} className="mt-3 flex flex-col gap-2">
          <input type="hidden" name="orgSlug" value={org} />
          <OrLine text={t.login.or} />
          <GoogleButton label={t.login.google} pendingText={t.login.signingIn} />
          <p className="text-center text-xs text-gray-400">{t.login.googleHint}</p>
        </form>
      )}
    </AuthCard>
  );
}
