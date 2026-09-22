'use client';

import { useActionState } from 'react';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import { SubmitButton } from '@/components/submit-button';
import { requestPasswordReset, type ForgotPasswordState } from './actions';

const initialState: ForgotPasswordState = {};

export function ForgotPasswordForm({ orgSlug }: { orgSlug: string }) {
  const [state, formAction] = useActionState(requestPasswordReset, initialState);

  if (state.sent) {
    return (
      <p className="rounded-lg bg-green-50 px-3 py-3 text-center text-sm text-green-700">
        إذا كان هذا الحساب مسجّلاً ببريد إلكتروني حقيقي، وصله الآن رابط لإعادة تعيين كلمة السر. تحقق من بريدك
        (وصندوق الرسائل غير المرغوبة).
      </p>
    );
  }

  return (
    <form action={formAction} className="flex flex-col gap-3">
      <input type="hidden" name="orgSlug" value={orgSlug} />
      {state.error && <p className="rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-600">{state.error}</p>}
      <label className={authLabelClass}>
        رقم الهوية / رقم الطالب أو البريد الإلكتروني
        <input name="identifier" required dir="ltr" autoComplete="username" className={`mt-1 ${authInputClass}`} />
      </label>
      <SubmitButton className={`mt-2 ${authButtonClass}`} pendingText="جاري الإرسال...">
        إرسال رابط إعادة التعيين
      </SubmitButton>
    </form>
  );
}
