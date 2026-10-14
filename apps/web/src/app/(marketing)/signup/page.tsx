import { GrowingTree } from '@/components/growing-tree';
import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { signUpAndCreateOrganization } from './actions';
import { signUpWithGoogle } from '@/lib/auth/google';
import { GoogleButton, OrLine } from '@/components/google-button';
import { googleEnabled } from '@/lib/auth/google-enabled';
import { Check } from 'lucide-react';

// Creates the auth user AND the organization + first admin membership in
// one step (see supabase/migrations/0010_self_serve_signup.sql), then sends
// the new admin straight to their own subdomain's dashboard.
export default async function SignupPage({ searchParams }: { searchParams: Promise<{ error?: string; sent?: string }> }) {
  const { error, sent } = await searchParams;
  const { t } = await getI18n();
  const google = await googleEnabled();

  return (
    <>
      <GrowingTree />
      <AuthCard
        title={t.common.registerCenter}
        subtitle={t.signup.subtitle}
        error={error}
        footer={
          <>
            {t.signup.haveCenter}{' '}
            <a href="/login" className="font-semibold text-brand">
              {t.signup.signIn}
            </a>
          </>
        }
      >
        {sent ? (
          // "Confirm email" is on: the rest happens from the link in the email
          <p className="rounded-lg bg-green-50 px-3 py-3 text-center text-sm text-green-700">{fmt(t.signup.checkEmail, { email: sent })}</p>
        ) : (
        <>
        <ul className="mb-6 flex flex-col gap-2 text-sm text-gray-600">
          {t.signup.benefits.map((b) => (
            <li key={b} className="flex items-start gap-2">
              <Check size={16} className="mt-0.5 shrink-0 text-brand" aria-hidden />
              <span>{b}</span>
            </li>
          ))}
        </ul>

        <form action={signUpAndCreateOrganization} className="flex flex-col gap-3">
          <label className={authLabelClass}>
            {t.signup.orgName}
            <input name="orgName" required placeholder={t.signup.orgNamePlaceholder} className={`mt-1 ${authInputClass}`} />
          </label>

          <label className={authLabelClass}>
            {t.common.centerLink}
            {/* a web address reads left-to-right in every language */}
            <div dir="ltr" className="mt-1 flex items-center overflow-hidden rounded-lg border border-gray-300 text-sm">
              <input name="slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" placeholder="alnoor" className="w-full px-3 py-2.5 outline-none" />
              <span className="whitespace-nowrap bg-gray-50 px-3 py-2.5 text-gray-500">.bustan-alquran.com</span>
            </div>
          </label>

          <label className={authLabelClass}>
            {t.common.email}
            <input type="email" name="email" required dir="ltr" className={`mt-1 ${authInputClass}`} />
          </label>

          <label className={authLabelClass}>
            {t.common.password}
            <input type="password" name="password" required minLength={8} className={`mt-1 ${authInputClass}`} />
          </label>

          <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText={t.signup.creating}>
            {t.signup.submit}
          </SubmitButton>
          {/* the same center name and link, with a Google account instead of email + password */}
          {google && (
            <>
              <OrLine text={t.login.or} />
              <GoogleButton label={t.signup.google} pendingText={t.signup.creating} formAction={signUpWithGoogle} />
            </>
          )}
        </form>
        </>
        )}
      </AuthCard>
    </>
  );
}
