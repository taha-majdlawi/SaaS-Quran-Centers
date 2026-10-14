'use client';

import { useActionState } from 'react';
import type { staffAr } from '@/lib/i18n/dictionaries/staff.ar';
import { changeEmail, changePassword, type AccountState } from './actions';

type MyAccount = (typeof staffAr)['myAccount'];

const input = 'mt-1 w-full rounded-lg border border-gray-300 px-3 py-2 text-sm outline-none focus:border-brand focus:ring-1 focus:ring-brand';
const button = 'rounded-lg bg-brand px-4 py-2 text-sm font-semibold text-white hover:opacity-90 disabled:opacity-50';

function Note({ state }: { state: AccountState }) {
  if (state.ok) return <p className="rounded-lg bg-green-50 px-3 py-2 text-sm text-green-700">{state.ok}</p>;
  if (state.error) return <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{state.error}</p>;
  return null;
}

export function EmailForm({ A }: { A: MyAccount }) {
  const [state, action, pending] = useActionState(changeEmail, {});
  return (
    <form action={action} className="flex flex-col gap-3">
      <Note state={state} />
      <label className="text-sm font-medium text-gray-700">
        {A.newEmail}
        <input type="email" name="email" required dir="ltr" autoComplete="email" className={input} />
      </label>
      <div>
        <button type="submit" disabled={pending} className={button}>
          {pending ? A.sending : A.sendLink}
        </button>
      </div>
    </form>
  );
}

export function PasswordForm({ A }: { A: MyAccount }) {
  const [state, action, pending] = useActionState(changePassword, {});
  return (
    <form action={action} className="flex flex-col gap-3" key={state.ok ? 'done' : 'form'}>
      <Note state={state} />
      <label className="text-sm font-medium text-gray-700">
        {A.currentPassword}
        <input type="password" name="current" required autoComplete="current-password" className={input} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {A.newPassword}
        <input type="password" name="password" required minLength={8} autoComplete="new-password" className={input} />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {A.confirmPassword}
        <input type="password" name="confirm" required minLength={8} autoComplete="new-password" className={input} />
      </label>
      <div>
        <button type="submit" disabled={pending} className={button}>
          {pending ? A.saving : A.savePassword}
        </button>
      </div>
    </form>
  );
}
