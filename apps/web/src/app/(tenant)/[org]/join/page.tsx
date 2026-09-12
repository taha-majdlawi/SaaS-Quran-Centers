import { AuthCard } from '@/components/auth-card';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { createClient } from '@/lib/supabase/server';
import { signUpAndAcceptInvitation, acceptInvitationForCurrentUser } from './actions';

const ROLE_LABELS: Record<string, string> = {
  admin: 'مدير',
  teacher: 'معلم',
  guardian: 'ولي أمر',
  student: 'طالب',
};

export default async function JoinPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ token?: string; error?: string }>;
}) {
  const { org } = await params;
  const { token, error } = await searchParams;

  if (!token) {
    return (
      <AuthCard title="رابط الدعوة غير مكتمل" subtitle={org}>
        <p className="text-center text-sm text-gray-500">تأكد إنك استخدمت الرابط كامل من الشخص اللي دعاك.</p>
      </AuthCard>
    );
  }

  const supabase = await createClient();
  const { data } = await supabase.rpc('get_invitation', { invite_token: token });
  const invitation = data?.[0];

  if (!invitation || !invitation.valid) {
    return (
      <AuthCard title="دعوة غير صالحة" subtitle={org}>
        <p className="text-center text-sm text-gray-500">
          هذي الدعوة منتهية أو تم استخدامها من قبل. اطلب من مدير المركز يرسلّك دعوة جديدة.
        </p>
      </AuthCard>
    );
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const roleLabel = ROLE_LABELS[invitation.role] ?? invitation.role;

  if (user) {
    return (
      <AuthCard title={`دعوة من ${invitation.organization_name}`} subtitle={`كـ ${roleLabel}`} error={error}>
        <p className="mb-4 text-center text-sm text-gray-500">مسجّل دخول بـ {user.email}. اضغط تأكيد للانضمام.</p>
        <form action={acceptInvitationForCurrentUser}>
          <input type="hidden" name="token" value={token} />
          <SubmitButton className={authButtonClass} pendingText="جاري الانضمام...">
            تأكيد الانضمام
          </SubmitButton>
        </form>
      </AuthCard>
    );
  }

  return (
    <AuthCard
      title={`دعوة من ${invitation.organization_name}`}
      subtitle={`كـ ${roleLabel} - أنشئ كلمة سر لحسابك`}
      error={error}
    >
      <form action={signUpAndAcceptInvitation} className="flex flex-col gap-3">
        <input type="hidden" name="token" value={token} />
        <label className={authLabelClass}>
          البريد الإلكتروني
          <input
            type="email"
            name="email"
            required
            defaultValue={invitation.email}
            readOnly
            className={`mt-1 ${authInputClass} bg-gray-50`}
          />
        </label>
        <label className={authLabelClass}>
          كلمة السر
          <input type="password" name="password" required minLength={6} className={`mt-1 ${authInputClass}`} />
        </label>
        <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText="جاري الإنشاء والانضمام...">
          إنشاء الحساب والانضمام
        </SubmitButton>
      </form>
    </AuthCard>
  );
}
