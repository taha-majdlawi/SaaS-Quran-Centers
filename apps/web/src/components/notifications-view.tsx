import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { markAllRead, setPref } from '@/lib/comms/actions';

interface Item {
  id: string;
  event_key: string;
  title: string;
  body: string | null;
  ref_id: string | null;
  created_at: string;
  read: boolean;
}

export const EVENT_LABELS: Record<string, string> = {
  announcement: 'الإعلانات',
  calendar_entry: 'التقويم والفعاليات',
  waitlist_promoted: 'الترقية من قائمة الانتظار',
  event_reminder: 'تذكير بالفعاليات',
  weekly_digest: 'ملخص الأسبوع',
  serd_assigned: 'سرد مطلوب مني',
  serd_reviewed: 'اعتماد السرد',
  market_order: 'طلبات السوق',
  badge_awarded: 'الشارات',
};

/** Where an inbox row leads, per audience (`base` is '' for staff, '/my' for the portal). */
function linkFor(n: Item, portal: boolean): string | null {
  if (!n.ref_id) return null;
  switch (n.event_key) {
    case 'calendar_entry':
    case 'event_reminder':
    case 'waitlist_promoted':
      return portal ? `/my/calendar/${n.ref_id}` : `/calendar/${n.ref_id}`;
    case 'announcement':
      return portal ? '/my/announcements' : '/announcements';
    case 'serd_assigned':
      return `/serd/new?session=${n.ref_id}`;
    case 'serd_reviewed':
      return portal ? '/my' : '/serd';
    case 'market_order':
      return portal ? '/my/market' : '/market';
    case 'weekly_digest':
      return portal ? `/my/report?student=${n.ref_id}` : null;
    case 'badge_awarded':
      return portal ? '/my/badges' : `/badges/${n.ref_id}`;
    default:
      return null;
  }
}

export async function NotificationsView({ orgId, portal }: { orgId: string; portal: boolean }) {
  const supabase = await createClient();
  const back = portal ? '/my/notifications' : '/notifications';
  const [{ data }, { data: prefsData }] = await Promise.all([
    supabase.rpc('my_notifications', { p_org: orgId, p_limit: 80 }),
    supabase.rpc('my_notification_prefs', { p_org: orgId }),
  ]);
  const items = (data ?? []) as Item[];
  const prefs = (prefsData ?? {}) as Record<string, boolean>;
  const unread = items.filter((i) => !i.read).length;

  return (
    <div className="max-w-2xl">
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold">الإشعارات</h1>
        {unread > 0 && (
          <form action={markAllRead}>
            <input type="hidden" name="orgId" value={orgId} />
            <input type="hidden" name="back" value={back} />
            <SubmitButton className="rounded border px-3 py-1.5 text-sm text-brand" pendingText="...">
              تعليم الكل كمقروء ({unread})
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
                <span className="text-xs text-gray-400">{new Date(n.created_at).toLocaleString('ar', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}</span>
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
        {!items.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد إشعارات</p>}
      </div>

      <h2 className="mb-2 font-semibold">ما أريد أن يصلني</h2>
      <div className="flex flex-col gap-1 rounded-lg border bg-white p-3 text-sm">
        {Object.entries(EVENT_LABELS).map(([event, label]) => {
          const on = prefs[event] !== false;
          return (
            <form key={event} action={setPref} className="flex items-center justify-between py-1">
              <input type="hidden" name="orgId" value={orgId} />
              <input type="hidden" name="event" value={event} />
              <input type="hidden" name="enabled" value={on ? '0' : '1'} />
              <input type="hidden" name="back" value={back} />
              <span>{label}</span>
              <button className={`rounded-full px-3 py-1 text-xs ${on ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>{on ? 'مفعّل' : 'متوقف'}</button>
            </form>
          );
        })}
      </div>
    </div>
  );
}
