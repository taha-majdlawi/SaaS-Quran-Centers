'use client';

import { createClient } from '@/lib/supabase/client';

// Crash reports from the browser (0076 report_client_error). The last steps
// the person took ride along so a bug can be reproduced.

const crumbs: string[] = [];
const recent = new Map<string, number>();
let orgId: string | null = null;

/** The center the page belongs to (set by the tenant layout). */
export function setMonitoringOrg(id: string | null) {
  orgId = id;
}

export function addCrumb(text: string) {
  const t = text.replace(/\s+/g, ' ').trim().slice(0, 120);
  if (!t) return;
  crumbs.push(`${new Date().toISOString().slice(11, 19)} ${t}`);
  if (crumbs.length > 25) crumbs.shift();
}

function describeDevice(): { os: string; device: string } {
  const ua = navigator.userAgent;
  const os = /Android [\d.]+/.exec(ua)?.[0] ?? /iPhone OS [\d_]+/.exec(ua)?.[0]?.replace(/_/g, '.') ?? /Windows NT [\d.]+/.exec(ua)?.[0] ?? /Mac OS X [\d_]+/.exec(ua)?.[0]?.replace(/_/g, '.') ?? (/Linux/.test(ua) ? 'Linux' : 'unknown');
  const browser = /(Edg|OPR|Chrome|Firefox|Version)\/[\d.]+/.exec(ua)?.[0]?.replace('Version', 'Safari') ?? 'browser';
  return { os, device: `${browser} · ${window.innerWidth}×${window.innerHeight}` };
}

export function reportError(error: unknown, extra: Record<string, unknown> = {}) {
  try {
    if (!process.env.NEXT_PUBLIC_SUPABASE_URL) return;
    const err = error instanceof Error ? error : new Error(typeof error === 'string' ? error : JSON.stringify(error));
    const message = `${err.name && err.name !== 'Error' ? `${err.name}: ` : ''}${err.message || 'Unknown error'}`;
    // the same error twice in a few seconds is one report
    const key = message + location.pathname;
    const now = Date.now();
    if ((recent.get(key) ?? 0) > now - 10_000) return;
    recent.set(key, now);
    // noise that is not ours
    if (/ResizeObserver loop|Script error\.?$|chrome-extension:|moz-extension:/i.test(message + (err.stack ?? ''))) return;

    const { os, device } = describeDevice();
    void createClient().rpc('report_client_error', {
      p_source: 'web',
      p_message: message,
      p_stack: err.stack ?? null,
      p_screen: location.pathname,
      p_url: location.href.split('#')[0].slice(0, 500),
      p_org: orgId,
      p_app_version: process.env.NEXT_PUBLIC_BUILD_ID ?? null,
      p_os: os,
      p_device: device,
      p_locale: document.documentElement.lang || null,
      p_breadcrumbs: [...crumbs],
      p_extra: { digest: (err as { digest?: string }).digest, ...extra },
    });
  } catch {
    // reporting must never break the page
  }
}
