import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { NotificationsView } from '@/components/notifications-view';
import { TabsNav, TemplatesTab, UpcomingTab, SendTab, LogTab, DevicesTab, SettingsTab } from '@/components/notification-center/tabs';
import { getI18n } from '@/lib/i18n/server';

interface Search {
  tab?: string;
  ok?: string;
  error?: string;
  days?: string;
  from?: string;
  to?: string;
  event?: string;
  status?: string;
}

export default async function NotificationsPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<Search> }) {
  const { org: slug } = await params;
  const q = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;

  // teachers only have their own inbox; the centre's notification management is the admin's
  if (org.myRole !== 'admin') return <NotificationsView orgId={org.id} portal={false} />;

  const tab = q.tab ?? 'inbox';

  let names: Record<string, string> = {};
  if (tab === 'log') {
    const supabase = await createClient();
    const { data } = await supabase.rpc('admin_notification_config', { p_org: org.id });
    const list = ((data as { templates?: { event_key: string; name: string }[] } | null)?.templates ?? []) as { event_key: string; name: string }[];
    names = Object.fromEntries(list.map((t) => [t.event_key, (S.notif.events as Record<string, string>)[t.event_key] ?? t.name]));
  }

  return (
    <div>
      <h1 className="mb-1 text-2xl font-bold">{S.notif.heading}</h1>
      <p className="mb-4 text-sm text-gray-500">{S.notif.intro}</p>
      <TabsNav active={tab} />
      {q.ok && <p className="mb-4 max-w-3xl rounded bg-green-50 px-3 py-2 text-sm text-green-700">{q.ok}</p>}
      {q.error && <p className="mb-4 max-w-3xl rounded bg-red-50 px-3 py-2 text-sm text-red-600">{q.error}</p>}

      {tab === 'inbox' && <NotificationsView orgId={org.id} portal={false} embedded />}
      {tab === 'templates' && <TemplatesTab orgId={org.id} />}
      {tab === 'upcoming' && <UpcomingTab orgId={org.id} days={Number(q.days) || 14} />}
      {tab === 'send' && <SendTab orgId={org.id} />}
      {tab === 'log' && <LogTab orgId={org.id} from={q.from} to={q.to} event={q.event} status={q.status} names={names} />}
      {tab === 'devices' && <DevicesTab orgId={org.id} />}
      {tab === 'settings' && <SettingsTab orgId={org.id} />}
    </div>
  );
}
