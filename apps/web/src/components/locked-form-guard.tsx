'use client';

import { useEffect, useState } from 'react';

/**
 * A center locked for non-payment refuses every write in the database
 * (_assert_can_write, 0066), but its staff would otherwise only find out AFTER
 * filling a whole form: the server action redirects back and the typed values
 * are gone. This stops a POST form before it leaves the page and says why, so
 * nothing typed is lost. Exempt: the billing page (a locked center must still
 * be able to report its payment) and forms marked data-allow-locked (sign out).
 */
export function LockedFormGuard({ message, allowPath = '/billing' }: { message: string; allowPath?: string }) {
  const [shown, setShown] = useState(false);

  useEffect(() => {
    const onSubmit = (e: SubmitEvent) => {
      const form = e.target;
      if (!(form instanceof HTMLFormElement)) return;
      if (form.method.toLowerCase() !== 'post') return;
      if (form.hasAttribute('data-allow-locked')) return;
      if (window.location.pathname.startsWith(allowPath)) return;
      e.preventDefault();
      e.stopImmediatePropagation();
      setShown(true);
    };
    document.addEventListener('submit', onSubmit, true);
    return () => document.removeEventListener('submit', onSubmit, true);
  }, [allowPath]);

  if (!shown) return null;
  return (
    <div role="alert" className="fixed inset-x-0 top-0 z-50 flex items-center justify-center gap-3 bg-red-600 px-6 py-3 text-sm font-semibold text-white shadow-lg print:hidden">
      <span>{message}</span>
      <button type="button" onClick={() => setShown(false)} aria-label="×" className="text-lg leading-none">
        ×
      </button>
    </div>
  );
}
