import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { hasRealEmail } from '@/lib/accounts/login-id';
import { EmailForm, PasswordForm } from './account-forms';

// The teacher's / admin's own sign-in details. Students and guardians never reach it (staff
// layout): their accounts are made and changed by the center.
export default async function AccountPage() {
  const { t } = await getI18n();
  const A = t.staff.myAccount;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const email = user?.email ?? '';
  const realEmail = hasRealEmail(email);
  const google = (user?.identities ?? []).some((i) => i.provider === 'google');

  return (
    <div className="flex max-w-xl flex-col gap-6">
      <div>
        <h1 className="mb-1 text-2xl font-bold">{A.title}</h1>
        <p className="text-sm text-gray-500">{A.subtitle}</p>
      </div>

      <section className="flex flex-col gap-3 rounded-xl border bg-white p-5">
        <h2 className="font-semibold">{A.emailSection}</h2>
        {realEmail ? (
          <>
            <p className="text-sm text-gray-600">{fmt(A.currentEmail, { email })}</p>
            <EmailForm A={A} />
          </>
        ) : (
          <p className="text-sm text-gray-600">{A.noEmail}</p>
        )}
      </section>

      <section className="flex flex-col gap-3 rounded-xl border bg-white p-5">
        <h2 className="font-semibold">{A.passwordSection}</h2>
        <PasswordForm A={A} />
      </section>

      {realEmail && (
        <section className="flex flex-col gap-2 rounded-xl border bg-white p-5">
          <h2 className="font-semibold">{A.google}</h2>
          <p className="text-sm text-gray-600">{google ? A.googleLinked : A.googleHint}</p>
        </section>
      )}
    </div>
  );
}
