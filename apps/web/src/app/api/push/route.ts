import { createAdminClient } from '@/lib/supabase/admin';

/**
 * Push delivery. The database calls this (pg_net) for every new inbox
 * notification and every new chat message, with a shared secret. It looks the
 * recipient's phones up and sends through Firebase Cloud Messaging (HTTP v1).
 *
 * Secrets (Cloudflare): PUSH_SHARED_SECRET (same value as platform_settings.push_secret in the DB)
 * and FCM_SERVICE_ACCOUNT_JSON (the Firebase service-account key file, whole JSON).
 */

interface ServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

const b64url = (input: ArrayBuffer | string) => {
  const bytes = typeof input === 'string' ? new TextEncoder().encode(input) : new Uint8Array(input);
  let s = '';
  bytes.forEach((b) => (s += String.fromCharCode(b)));
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
};

const safeEqual = (a: string, b: string) => {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
};

let cached: { token: string; exp: number } | null = null;

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;

  const pem = sa.private_key.replace(/-----(BEGIN|END) PRIVATE KEY-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const uri = sa.token_uri ?? 'https://oauth2.googleapis.com/token';
  const unsigned = `${b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${b64url(
    JSON.stringify({ iss: sa.client_email, scope: 'https://www.googleapis.com/auth/firebase.messaging', aud: uri, iat: now, exp: now + 3600 }),
  )}`;
  const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));
  const res = await fetch(uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: `${unsigned}.${b64url(sig)}` }),
  });
  if (!res.ok) throw new Error(`token exchange failed: ${res.status}`);
  const data = (await res.json()) as { access_token: string; expires_in: number };
  cached = { token: data.access_token, exp: now + data.expires_in };
  return data.access_token;
}

interface Payload {
  userId: string;
  title: string;
  body: string;
  data: Record<string, string>;
}

async function deliver(sa: ServiceAccount, p: Payload) {
  const admin = createAdminClient();
  const { data: tokens } = await admin.from('device_tokens').select('token').eq('user_id', p.userId);
  if (!tokens?.length) return { sent: 0, removed: 0 };
  const bearer = await accessToken(sa);
  let sent = 0;
  let removed = 0;
  for (const { token } of tokens) {
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${bearer}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: p.title, body: p.body },
          data: p.data,
          android: { priority: 'HIGH', notification: { channel_id: 'bustan_default' } },
        },
      }),
    });
    if (res.ok) sent++;
    else if (res.status === 404 || res.status === 400) {
      // the app was uninstalled / the token is stale: forget it
      const err = (await res.text()).toUpperCase();
      if (err.includes('UNREGISTERED') || err.includes('INVALID_ARGUMENT') || res.status === 404) {
        await admin.from('device_tokens').delete().eq('token', token);
        removed++;
      }
    }
  }
  return { sent, removed };
}

export async function POST(req: Request) {
  const secret = process.env.PUSH_SHARED_SECRET;
  if (!secret || !safeEqual(req.headers.get('x-push-secret') ?? '', secret)) return new Response('unauthorized', { status: 401 });

  const raw = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!raw) return new Response('push not configured', { status: 503 });
  let sa: ServiceAccount;
  try {
    sa = JSON.parse(raw) as ServiceAccount;
  } catch {
    return new Response('bad service account', { status: 500 });
  }

  const { kind, id } = (await req.json().catch(() => ({}))) as { kind?: string; id?: string };
  if (!id || (kind !== 'notification' && kind !== 'chat')) return new Response('bad request', { status: 400 });

  const admin = createAdminClient();
  try {
    if (kind === 'notification') {
      const { data: n } = await admin.from('notifications').select('user_id, organization_id, event_key, title, body, ref_id').eq('id', id).maybeSingle();
      if (!n) return Response.json({ ok: true, skipped: 'gone' });
      const result = await deliver(sa, {
        userId: n.user_id,
        title: n.title,
        body: n.body ?? '',
        data: { kind: 'notification', event_key: n.event_key, ref_id: n.ref_id ?? '', org_id: n.organization_id },
      });
      return Response.json({ ok: true, ...result });
    }

    const { data: m } = await admin.from('chat_messages').select('thread_id, sender_id, body, image_path').eq('id', id).maybeSingle();
    if (!m) return Response.json({ ok: true, skipped: 'gone' });
    const { data: t } = await admin.from('chat_threads').select('organization_id, user_a, user_b').eq('id', m.thread_id).maybeSingle();
    if (!t) return Response.json({ ok: true, skipped: 'gone' });
    const recipient = t.user_a === m.sender_id ? t.user_b : t.user_a;
    const { data: pref } = await admin.from('chat_thread_prefs').select('muted').eq('thread_id', m.thread_id).eq('user_id', recipient).maybeSingle();
    if (pref?.muted) return Response.json({ ok: true, skipped: 'muted' });
    const { data: sender } = await admin.from('profiles').select('full_name').eq('id', m.sender_id).maybeSingle();
    const result = await deliver(sa, {
      userId: recipient,
      title: sender?.full_name ?? 'رسالة جديدة',
      body: m.body ? String(m.body).slice(0, 140) : '📷 صورة',
      data: { kind: 'chat', event_key: 'chat_message', ref_id: m.sender_id, org_id: t.organization_id },
    });
    return Response.json({ ok: true, ...result });
  } catch (e) {
    return new Response(e instanceof Error ? e.message : 'error', { status: 500 });
  }
}
