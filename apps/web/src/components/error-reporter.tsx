'use client';

import { useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { addCrumb, reportError, setMonitoringOrg } from '@/lib/monitoring/client';

/**
 * Listens for crashes the page did not catch and keeps a short trail of what
 * the person did (pages opened, buttons pressed) to send along with them.
 */
export function ErrorReporter() {
  const path = usePathname();

  useEffect(() => {
    addCrumb(`open ${path}`);
  }, [path]);

  useEffect(() => {
    const onError = (e: ErrorEvent) => reportError(e.error ?? e.message, { kind: 'window.onerror', file: e.filename, line: e.lineno });
    const onRejection = (e: PromiseRejectionEvent) => reportError(e.reason, { kind: 'unhandledrejection' });
    const onClick = (e: MouseEvent) => {
      const el = (e.target as HTMLElement | null)?.closest('a,button,[role=button],input[type=submit],summary');
      if (el) addCrumb(`tap ${el.tagName.toLowerCase()} "${(el.textContent || (el as HTMLInputElement).value || el.getAttribute('aria-label') || '').trim().slice(0, 40)}"`);
    };
    const onSubmit = (e: SubmitEvent) => addCrumb(`submit form ${(e.target as HTMLFormElement | null)?.getAttribute('action') ?? ''}`);
    window.addEventListener('error', onError);
    window.addEventListener('unhandledrejection', onRejection);
    document.addEventListener('click', onClick, true);
    document.addEventListener('submit', onSubmit, true);
    return () => {
      window.removeEventListener('error', onError);
      window.removeEventListener('unhandledrejection', onRejection);
      document.removeEventListener('click', onClick, true);
      document.removeEventListener('submit', onSubmit, true);
    };
  }, []);

  return null;
}

/** Tells the reporter which center this page belongs to. */
export function MonitoringOrg({ orgId }: { orgId: string }) {
  useEffect(() => {
    setMonitoringOrg(orgId);
    return () => setMonitoringOrg(null);
  }, [orgId]);
  return null;
}
