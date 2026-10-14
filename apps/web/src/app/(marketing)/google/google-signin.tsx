'use client';

import { useEffect, useRef, useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';
import { completeGoogle } from './actions';

type GoogleId = {
  initialize: (o: Record<string, unknown>) => void;
  renderButton: (el: HTMLElement, o: Record<string, unknown>) => void;
  prompt: () => void;
};
declare global {
  interface Window {
    google?: { accounts: { id: GoogleId } };
  }
}

const sha256Hex = async (text: string) =>
  [...new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text)))].map((b) => b.toString(16).padStart(2, '0')).join('');

/**
 * Google's own sign-in button (Google Identity Services), on bustan-alquran.com: Google names
 * this site, not the Supabase host. Its ID token is handed to Supabase (signInWithIdToken, with a
 * one-time nonce Google signs into the token), then completeGoogle() decides who comes in.
 */
export function GoogleSignIn({
  clientId,
  center,
  invite,
  signup,
  lang,
  t,
}: {
  clientId: string;
  center?: string;
  invite?: string;
  signup?: boolean;
  lang: string;
  t: Dictionary['googlePage'];
}) {
  const button = useRef<HTMLDivElement>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const rawNonce = Array.from(crypto.getRandomValues(new Uint8Array(16)), (b) => b.toString(16).padStart(2, '0')).join('');

    const onCredential = async ({ credential }: { credential: string }) => {
      setBusy(true);
      setError(null);
      const supabase = createClient();
      const { error: signInError } = await supabase.auth.signInWithIdToken({ provider: 'google', token: credential, nonce: rawNonce });
      if (signInError) {
        setBusy(false);
        setError(t.failed);
        return;
      }
      const result = await completeGoogle({ center, invite, signup });
      if ('to' in result) {
        window.location.assign(result.to);
        return;
      }
      setBusy(false);
      setError(result.error);
    };

    const start = async () => {
      const hashed = await sha256Hex(rawNonce);
      const id = window.google?.accounts.id;
      if (!id || cancelled || !button.current) return;
      id.initialize({ client_id: clientId, callback: onCredential, nonce: hashed, ux_mode: 'popup', context: signup ? 'signup' : 'signin', use_fedcm_for_prompt: true });
      id.renderButton(button.current, { theme: 'outline', size: 'large', text: signup ? 'signup_with' : 'continue_with', shape: 'pill', locale: lang, width: 300 });
      id.prompt();
    };

    if (window.google?.accounts?.id) void start();
    else {
      // added by this (nonce-trusted) code, so the page's CSP lets it run ('strict-dynamic')
      const script = document.createElement('script');
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.onload = () => void start();
      script.onerror = () => setFailed(true);
      document.head.appendChild(script);
    }
    return () => {
      cancelled = true;
    };
    // the page renders once per visit
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="flex flex-col items-center gap-4">
      {error && <p className="w-full rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-600">{error}</p>}
      {failed && <p className="w-full rounded-lg bg-amber-50 px-3 py-2 text-center text-sm text-amber-800">{t.unavailable}</p>}
      {busy ? <p className="py-3 text-sm text-gray-500">{t.working}</p> : <div ref={button} className="flex min-h-11 justify-center" />}
    </div>
  );
}
