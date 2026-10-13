'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

type Status = 'checking' | 'ready' | 'invalid';

/**
 * The recovery link lands here with ?token_hash= (our template, any device) or with
 * the session in the URL (the default template) - the browser client parses that on
 * init and fires PASSWORD_RECOVERY; there is nothing to read server-side.
 */
export function ResetPasswordForm({ t }: { t: Dictionary['reset'] }) {
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

    // The link from our email template (supabase/templates/recovery.html) carries a
    // one-time token_hash: verified here, so it works on any device - the older link
    // (?code=) only worked in the browser that asked for it.
    const params = new URLSearchParams(window.location.search);
    const tokenHash = params.get('token_hash');
    if (tokenHash && params.get('type') === 'recovery') {
      settled = true;
      // drop the token from the address bar and history once read
      window.history.replaceState(null, '', window.location.pathname);
      supabase.auth.verifyOtp({ token_hash: tokenHash, type: 'recovery' }).then(({ error }) => setStatus(error ? 'invalid' : 'ready'));
    }

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
      setError(t.errorShort);
      return;
    }
    if (password !== confirm) {
      setError(t.errorMismatch);
      return;
    }
    setSubmitting(true);
    const supabase = createClient();
    const { error: updateError } = await supabase.auth.updateUser({ password });
    setSubmitting(false);
    if (updateError) {
      setError(t.errorFailed);
      return;
    }
    await supabase.auth.signOut();
    setDone(true);
    setTimeout(() => router.push('/login'), 2000);
  }

  if (status === 'checking') {
    return <p className="py-6 text-center text-sm text-gray-500">{t.checking}</p>;
  }

  if (status === 'invalid') {
    return (
      <div className="flex flex-col gap-3 text-center">
        <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">
          {t.invalid}
        </p>
        <a href="/forgot-password" className="text-sm font-semibold text-brand">
          {t.requestNew}
        </a>
      </div>
    );
  }

  if (done) {
    return (
      <p className="rounded-lg bg-green-50 px-3 py-3 text-center text-sm text-green-700">
        {t.done}
      </p>
    );
  }

  return (
    <form onSubmit={handleSubmit} className="flex flex-col gap-3">
      {error && <p className="rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-600">{error}</p>}
      <label className={authLabelClass}>
        {t.newPassword}
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
        {t.confirm}
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
        {submitting ? t.saving : t.submit}
      </button>
    </form>
  );
}
