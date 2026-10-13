'use client';

import { useEffect, useRef, useState } from 'react';
import type { EmailOtpType } from '@supabase/supabase-js';
import { createClient } from '@/lib/supabase/client';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';
import { fmt } from '@/lib/i18n/config';
import { finishSignup, type FinishResult } from './actions';

type Status = 'checking' | 'finishing' | 'invalid' | 'error' | 'slugTaken' | 'changed';

/**
 * The link in a confirmation email lands here. Our templates (supabase/templates) send a
 * one-time ?token_hash=, verified in the browser - so it works on any device, and a mail
 * scanner that only fetches the page uses nothing up. The default template's ?code= works
 * too, in the browser that signed up. Then finishSignup() creates the center or accepts
 * the invitation, and we go there.
 */
export function ConfirmEmail({ t, signUp, common }: { t: Dictionary['confirmEmail']; signUp: Dictionary['signup']; common: Dictionary['common'] }) {
  const [status, setStatus] = useState<Status>('checking');
  const [taken, setTaken] = useState<{ slug: string; orgName: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const [reason, setReason] = useState<string | null>(null);
  const [loginError, setLoginError] = useState<string | null>(null);
  const started = useRef(false);

  const follow = (r: FinishResult) => {
    if (r.to) {
      window.location.assign(r.to);
      return;
    }
    if (r.slugTaken) {
      setTaken(r.slugTaken);
      setStatus('slugTaken');
      return;
    }
    setStatus(r.error === 'session' ? 'invalid' : 'error');
  };

  useEffect(() => {
    if (started.current) return; // once, even in React's double-run
    started.current = true;
    const params = new URLSearchParams(window.location.search);
    // the default template comes back through Supabase with the session (or its error) after '#'
    const hash = new URLSearchParams(window.location.hash.slice(1));
    const tokenHash = params.get('token_hash');
    const type = (params.get('type') ?? 'email') as EmailOtpType;
    const code = params.get('code');
    const accessToken = hash.get('access_token');
    const refreshToken = hash.get('refresh_token');
    const linkError = params.get('error_description') ?? hash.get('error_description');
    // the token is single-use: out of the address bar and history once read (before the
    // client starts, so it does not also try to use it)
    window.history.replaceState(null, '', window.location.pathname);
    const supabase = createClient();
    (async () => {
      const { error } = tokenHash
        ? await supabase.auth.verifyOtp({ token_hash: tokenHash, type })
        : code
          ? await supabase.auth.exchangeCodeForSession(code)
          : accessToken && refreshToken
            ? await supabase.auth.setSession({ access_token: accessToken, refresh_token: refreshToken })
            : { error: new Error(linkError ?? 'no token in the link') };
      if (error) {
        setReason(error.message);
        return setStatus('invalid');
      }
      // a new email for an existing account (/account): nothing else to finish
      if (type === 'email_change' || hash.get('type') === 'email_change') return setStatus('changed');
      setStatus('finishing');
      follow(await finishSignup());
    })().catch((e: unknown) => {
      setReason(e instanceof Error ? e.message : String(e));
      setStatus('error');
    });
  }, []);

  // A link already used (often by the mail service opening it to scan it) still confirmed the
  // address: signing in here finishes the center or the invitation all the same.
  async function signIn(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setBusy(true);
    setLoginError(null);
    const { error } = await createClient().auth.signInWithPassword({
      email: String(form.get('email') ?? '').trim(),
      password: String(form.get('password') ?? ''),
    });
    if (error) {
      setBusy(false);
      setLoginError(/confirm/i.test(error.message) ? t.notConfirmed : t.wrongLogin);
      return;
    }
    setStatus('finishing');
    follow(await finishSignup());
    setBusy(false);
  }

  async function retry(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const form = new FormData(e.currentTarget);
    setBusy(true);
    follow(await finishSignup({ orgName: String(form.get('orgName') ?? ''), slug: String(form.get('slug') ?? '') }));
    setBusy(false);
  }

  if (status === 'checking' || status === 'finishing') {
    return <p className="py-6 text-center text-sm text-gray-500">{status === 'checking' ? t.checking : t.finishing}</p>;
  }

  if (status === 'changed') {
    return (
      <div className="flex flex-col gap-3 text-center">
        <p className="rounded-lg bg-green-50 px-3 py-3 text-sm text-green-700">{t.changed}</p>
        <a href="/login" className="text-sm font-semibold text-brand">
          {t.signIn}
        </a>
      </div>
    );
  }

  if (status === 'slugTaken' && taken) {
    return (
      <form onSubmit={retry} className="flex flex-col gap-3">
        <p className="rounded-lg bg-amber-50 px-3 py-2 text-center text-sm text-amber-800">{fmt(t.slugTaken, { slug: taken.slug })}</p>
        <label className={authLabelClass}>
          {signUp.orgName}
          <input name="orgName" required defaultValue={taken.orgName} className={`mt-1 ${authInputClass}`} />
        </label>
        <div dir="ltr" className="flex items-center overflow-hidden rounded-lg border border-gray-300 text-sm">
          <input name="slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" defaultValue={taken.slug} className="w-full px-3 py-2.5 outline-none" />
          <span className="whitespace-nowrap bg-gray-50 px-3 py-2.5 text-gray-500">.bustan-alquran.com</span>
        </div>
        <button type="submit" disabled={busy} className={authButtonClass}>
          {busy ? signUp.creating : t.finish}
        </button>
      </form>
    );
  }

  return (
    <div className="flex flex-col gap-3 text-center">
      <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{status === 'invalid' ? t.invalid : t.error}</p>
      {reason && (
        <p dir="ltr" className="text-xs text-gray-400">
          {reason}
        </p>
      )}
      <form onSubmit={signIn} className="mt-2 flex flex-col gap-3 border-t pt-4 text-start">
        <p className="text-sm text-gray-600">{t.finishSignIn}</p>
        {loginError && <p className="rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-600">{loginError}</p>}
        <label className={authLabelClass}>
          {common.email}
          <input type="email" name="email" required dir="ltr" autoComplete="email" className={`mt-1 ${authInputClass}`} />
        </label>
        <label className={authLabelClass}>
          {common.password}
          <input type="password" name="password" required autoComplete="current-password" className={`mt-1 ${authInputClass}`} />
        </label>
        <button type="submit" disabled={busy} className={authButtonClass}>
          {busy ? t.finishing : t.signInFinish}
        </button>
      </form>
    </div>
  );
}
