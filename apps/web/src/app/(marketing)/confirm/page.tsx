import { AuthCard } from '@/components/auth-card';
import { getI18n } from '@/lib/i18n/server';
import { ConfirmEmail } from './confirm-email';

// Where the confirmation email's link lands (supabase/templates/confirmation.html).
export default async function ConfirmPage() {
  const { t } = await getI18n();
  return (
    <AuthCard title={t.confirmEmail.title}>
      <ConfirmEmail t={t.confirmEmail} signUp={t.signup} />
    </AuthCard>
  );
}
