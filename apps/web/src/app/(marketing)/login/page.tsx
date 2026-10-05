import { GrowingTree } from '@/components/growing-tree';
import { AuthCard } from '@/components/auth-card';
import { authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { getI18n } from '@/lib/i18n/server';
import { findOrgLogin } from './actions';

export default async function LoginLookupPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams;
  const { t } = await getI18n();

  return (
    <>
      <GrowingTree />
      <AuthCard
        title={t.common.login}
        subtitle={t.lookup.subtitle}
        error={error}
        footer={
          <>
            {t.lookup.noCenter}{' '}
            <a href="/signup" className="font-semibold text-brand">
              {t.common.registerCenterNow}
            </a>
          </>
        }
      >
        <form action={findOrgLogin} className="flex flex-col gap-3">
          <label className={authLabelClass}>
            {t.common.centerLink}
            {/* a web address reads left-to-right in every language */}
            <div dir="ltr" className="mt-1 flex items-center overflow-hidden rounded-lg border border-gray-300 text-sm">
              <input name="slug" required placeholder="alnoor" className="w-full px-3 py-2.5 outline-none" />
              <span className="whitespace-nowrap bg-gray-50 px-3 py-2.5 text-gray-500">.bustan-alquran.com</span>
            </div>
          </label>
          <SubmitButton className={authButtonClass} pendingText={t.lookup.searching}>
            {t.lookup.submit}
          </SubmitButton>
        </form>

        <p className="mt-5 text-center text-xs text-gray-400">
          {t.lookup.platformOwner}{' '}
          <a href="https://admin.bustan-alquran.com/login" className="underline">
            {t.lookup.platformOwnerLink}
          </a>
        </p>
      </AuthCard>
    </>
  );
}
