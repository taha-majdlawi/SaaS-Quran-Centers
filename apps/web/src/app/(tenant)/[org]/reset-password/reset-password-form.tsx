'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';

type Status = 'checking' | 'ready' | 'invalid';

/**
 * The recovery link lands here with the session encoded in the URL hash -
 * the browser client parses it on init and fires PASSWORD_RECOVERY, there is
 * nothing to read server-side (see forgot-password/actions.ts for why).
 */
export function ResetPasswordForm() {
  const [status, setStatus] = useState<Status>('checking');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [done, setDone] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const supabase = createClient();
    let settled = false;

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'PASSWORD_RECOVERY' || (event === 'SIGNED_IN' && session)) {
        settled = true;
        setStatus('ready');
      }
    });

    const timeout = setTimeout(() => {
      if (!settled) setStatus('invalid');
    }, 4000);

    return () => {
      subscription.unsubscribe();
      clearTimeout(timeout);
    };
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    if (password.length < 8) {
      setError('كلمة السر يجب ألا تقل عن 8 خانات');
      return;
    }
    if (password !== confirm) {
      setError('كلمتا السر غير متطابقتين');
      return;
    }
    setSubmitting(true);
    const supabase = createClient();
    const { error: updateError } = await supabase.auth.updateUser({ password });
    setSubmitting(false);
    if (updateError) {
      setError('تعذّر تحديث كلمة السر، جرّب طلب رابط جديد');
      return;
    }
    await supabase.auth.signOut();
    setDone(true);
    setTimeout(() => router.push('/login'), 2000);
  }

  if (status === 'checking') {
    return <p className="py-6 text-center text-sm text-gray-500">جاري التحقق من الرابط...</p>;
  }

  if (status === 'invalid') {
    return (
      <div className="flex flex-col gap-3 text-center">
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
          هذا الرابط غير صالح أو انتهت صلاحيته، اطلب رابطًا جديدًا
        </p>
        <a href="/forgot-password" className="text-sm font-semibold text-brand">
          طلب رابط جديد
        </a>
      </div>
    );
  }

  if (done) {
    return (
      <p className="rounded-lg bg-green-50 px-3 py-3 text-center text-sm text-green-700">
        تم تحديث كلمة السر، جاري تحويلك لتسجيل الدخول...
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      {error && <p className="rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-600">{error}</p>}
      <label className={authLabelClass}>
        كلمة السر الجديدة
        <input
          type="password"
          required
          autoComplete="new-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className={`mt-1 ${authInputClass}`}
        />
      </label>
      <label className={authLabelClass}>
        تأكيد كلمة السر
        <input
          type="password"
          required
          autoComplete="new-password"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          className={`mt-1 ${authInputClass}`}
        />
      </label>
      <button type="submit" disabled={submitting} className={`mt-2 ${authButtonClass}`}>
        {submitting ? 'جاري الحفظ...' : 'حفظ كلمة السر'}
      </button>
    </form>
  );
}
