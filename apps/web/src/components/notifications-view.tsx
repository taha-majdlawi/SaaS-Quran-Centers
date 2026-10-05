import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { markAllRead, setPref } from '@/lib/comms/actions';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

interface Item {
  id: string;
  event_key: string;
  title: string;
  body: string | null;
  ref_id: string | null;
  deep_link: string | null;
  created_at: string;
  read: boolean;
}

interface PrefType {
  event_key: string;
  name: string;
  enabled: boolean;
}

/** Screens an immediate message can open (keys chosen in the notification centre). */
const DEEP: Record<string, [string, string]> = {
  announcements: ['/announcements', '/my/announcements'],
  calendar: ['/calendar', '/my/calendar'],
  market: ['/market', '/my/market'],
  chat: ['/chat', '/my/chat'],
  badges: ['/badges', '/my/badges'],
};

/** Where an inbox row leads, per audience (`base` is '' for staff, '/my' for the portal). */
function linkFor(n: Item, portal: boolean): string | null {
  if (n.deep_link && DEEP[n.deep_link]) return DEEP[n.deep_link][portal ? 1 : 0];
  if (!n.ref_id) return null;
  switch (n.event_key) {
    case 'calendar_entry':
    case 'center_closed':
    case 'event_reminder':
    case 'waitlist_promoted':
      return portal ? `/my/calendar/${n.ref_id}` : `/calendar/${n.ref_id}`;
    case 'announcement':
      return portal ? '/my/announcements' : '/announcements';
    case 'serd_assigned':
      return `/serd/new?session=${n.ref_id}`;
    case 'serd_reviewed':
    case 'serd_approved':
    case 'serd_rejected':
      return portal ? '/my' : '/serd';
    case 'student_idle':
      return portal ? '/my' : null;
    case 'student_idle_teacher':
    case 'student_absences':
      return portal ? null : `/students/${n.ref_id}`;
    case 'teacher_checkin_reminder':
      return portal ? null : '/dashboard';
    case 'market_order':
    case 'market_fulfilled':
    case 'market_cancelled':
      return portal ? '/my/market' : '/market';
    case 'attendance_reminder':
      return portal ? null : '/attendance';
    case 'deletion_request':
      return portal ? null : '/deletion-requests';
    case 'billing_reviewed':
      return portal ? null : '/billing';
    case 'deletion_reviewed':
      return portal ? '/my/privacy' : null;
    case 'weekly_digest':
      return portal ? `/my/weekly?student=${n.ref_id}` : `/students/${n.ref_id}/weekly`;
    case 'badge_awarded':
      return portal ? '/my/badges' : `/badges/${n.ref_id}`;
    case 'recitation_submitted':
      return portal ? null : '/recitations';
    case 'recitation_reviewed':
      return portal ? '/my/recitations' : '/recitations?tab=reviewed';
    case 'fee_payment':
    case 'fee_overdue':
      return portal ? `/my/fees?s=${n.ref_id}` : `/fees/${n.ref_id}`;
    default:
      return null;
  }
}

export async function NotificationsView({ orgId, portal, embedded = false }: { orgId: string; portal: boolean; embedded?: boolean }) {
  const supabase = await createClient();
  const back = portal ? '/my/notifications' : '/notifications';
  const [{ data }, { data: prefsData }] = await Promise.all([
    supabase.rpc('my_notifications', { p_org: orgId, p_limit: 80 }),
    supabase.rpc('my_notification_types', { p_org: orgId }),
  ]);
  const items = (data ?? []) as Item[];
  const prefs = (prefsData ?? { types: [] }) as { types: PrefType[]; quiet_from?: string; quiet_to?: string };
  const unread = items.filter((i) => !i.read).length;
  const { t } = await getI18n();
  const N = t.notifications;

  return (
    <div className="max-w-2xl">
      <div className="mb-4 flex items-center justify-between">
        {embedded ? <span /> : <h1 className="text-2xl font-bold">{N.title}</h1>}
        {unread > 0 && (
          <form action={markAllRead}>
            <input type="hidden" name="orgId" value={orgId} />
            <input type="hidden" name="back" value={back} />
            <SubmitButton className="rounded border px-3 py-1.5 text-sm text-brand" pendingText="...">
              {fmt(N.markAll, { n: unread })}
            </SubmitButton>
          </form>
        )}
      </div>

      <div className="mb-8 flex flex-col gap-2">
        {items.map((n) => {
          const href = linkFor(n, portal);
          const inner = (
            <div className={`rounded-lg border p-3 text-sm ${n.read ? 'bg-white' : 'border-brand/40 bg-brand/5'}`}>
              <div className="flex items-center justify-between gap-2">
                <b>{n.title}</b>
                <span className="text-xs text-gray-400">{new Date(n.created_at).toLocaleString(t.labels.dateLocale, { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</span>
              </div>
              {n.body && <p className="mt-1 text-gray-600">{n.body}</p>}
            </div>
          );
          return href ? (
            <a key={n.id} href={href as never}>
              {inner}
            </a>
          ) : (
            <div key={n.id}>{inner}</div>
          );
        })}
        {!items.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{N.none}</p>}
      </div>

      <h2 className="mb-1 font-semibold">{N.prefs}</h2>
      {prefs.quiet_from && prefs.quiet_to && (
        <p className="mb-2 text-xs text-gray-500">{fmt(N.quiet, { from: prefs.quiet_from, to: prefs.quiet_to })}</p>
      )}
      <div className="flex flex-col gap-1 rounded-lg border bg-white p-3 text-sm">
        {prefs.types.map((pt) => (
          <form key={pt.event_key} action={setPref} className="flex items-center justify-between py-1">
            <input type="hidden" name="orgId" value={orgId} />
            <input type="hidden" name="event" value={pt.event_key} />
            <input type="hidden" name="enabled" value={pt.enabled ? '0' : '1'} />
            <input type="hidden" name="back" value={back} />
            <span>{(t.staff.notif.events as Record<string, string>)[pt.event_key] ?? pt.name}</span>
            <button className={`rounded-full px-3 py-1 text-xs ${pt.enabled ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{pt.enabled ? N.on : N.off}</button>
          </form>
        ))}
      </div>
    </div>
  );
}
