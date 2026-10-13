'use client';

import { useEffect, useRef, useState } from 'react';
import type { EmailOtpType } from '@supabase/supabase-js';
import { createClient } from '@/lib/supabase/client';
import { authInputClass, authLabelClass, authButtonClass } from '@/components/auth-styles';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';
import { fmt } from '@/lib/i18n/config';
import { finishSignup, type FinishResult } from './actions';

type Status = 'checking' | 'finishing' | 'invalid' | 'error' | 'slugTaken';

/**
 * The link in a confirmation email lands here. Our templates (supabase/templates) send a
 * one-time ?token_hash=, verified in the browser - so it works on any device, and a mail
 * scanner that only fetches the page uses nothing up. The default template's ?code= works
 * too, in the browser that signed up. Then finishSignup() creates the center or accepts
 * the invitation, and we go there.
 */
export function ConfirmEmail({ t, signUp }: { t: Dictionary['confirmEmail']; signUp: Dictionary['signup'] }) {
  const [status, setStatus] = useState<Status>('checking');
  const [taken, setTaken] = useState<{ slug: string; orgName: string } | null>(null);
  const [busy, setBusy] = useState(false);
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
    const tokenHash = params.get('token_hash');
    const type = (params.get('type') ?? 'email') as EmailOtpType;
    const code = params.get('code');
    // the token is single-use: out of the address bar and history once read
    window.history.replaceState(null, '', window.location.pathname);
    const supabase = createClient();
    (async () => {
      const { error } = tokenHash
        ? await supabase.auth.verifyOtp({ token_hash: tokenHash, type })
        : code
          ? await supabase.auth.exchangeCodeForSession(code)
          : { error: new Error('no token') };
      if (error) return setStatus('invalid');
      setStatus('finishing');
      follow(await finishSignup());
    })().catch(() => setStatus('error'));
  }, []);

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
      <a href="/login" className="text-sm font-semibold text-brand">
        {t.signIn}
      </a>
    </div>
  );
}
