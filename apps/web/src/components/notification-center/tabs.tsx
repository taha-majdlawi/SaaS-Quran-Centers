import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveNotificationSettings, sendTestPush, saveAttendanceReminderSetting, saveDigestSetting } from '@/lib/notifications/actions';
import { PUSH_STYLES } from '@/lib/notifications/catalog';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { TemplateEditor, type TemplateRow } from './template-editor';
import { SendForm } from './send-form';

const when = (iso: string | null | undefined, lang: string, withTime = true) =>
  iso ? new Date(iso).toLocaleString(lang, { day: 'numeric', month: 'short', year: 'numeric', ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}) }) : '—';

const TAB_KEYS = ['inbox', 'templates', 'upcoming', 'send', 'log', 'devices', 'settings'];

export async function TabsNav({ active }: { active: string }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  return (
    <nav className="mb-6 flex flex-wrap gap-1 border-b">
      {TAB_KEYS.map((key) => [key, S.notif.tabs[key]]).map(([key, label]) => (
        <a
          key={key}
          href={`/notifications?tab=${key}` as never}
          className={`-mb-px border-b-2 px-3 py-2 text-sm ${active === key ? 'border-brand font-semibold text-brand' : 'border-transparent text-gray-500 hover:text-gray-800'}`}
        >
          {label}
        </a>
      ))}
    </nav>
  );
}

export async function TemplatesTab({ orgId }: { orgId: string }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const at = (iso: string | null | undefined) => when(iso, T.labels.dateLocale);
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notification_config', { p_org: orgId });
  const templates = ((data as { templates?: TemplateRow[] } | null)?.templates ?? []) as TemplateRow[];
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">{S.notif.templatesTitle}</h2>
      <p className="mb-4 text-sm text-gray-500">
        {S.notif.templatesHint}
      </p>
      <div className="flex flex-col gap-2">
        {templates.map((t) => (
          <TemplateEditor key={t.event_key} orgId={orgId} t={t} labels={S.notif} lang={T.labels.dateLocale} />
        ))}
      </div>
    </section>
  );
}

interface UpcomingItem {
  id: string;
  title: string;
  start_date: string;
  starts_at: string | null;
  send_at: string;
  recipients: number;
  already_sent: boolean;
}

export async function UpcomingTab({ orgId, days }: { orgId: string; days: number }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const at = (iso: string | null | undefined) => when(iso, T.labels.dateLocale);
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notifications_upcoming', { p_org: orgId, p_days: days });
  const r = data as { lead_hours: number; items: UpcomingItem[]; digest: { send_at: string; recipients: number } | null; paused: boolean } | null;
  const items = r?.items ?? [];
  const now = Date.now();
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">{S.notif.upcomingTitle}</h2>
      <p className="mb-3 text-sm text-gray-500">
        {fmt(S.notif.upcomingHint, { hours: r?.lead_hours ?? 24 })}
        {r?.paused && <b className="text-amber-700"> — {S.notif.pausedNow}</b>}
      </p>
      <form className="mb-4 flex items-center gap-2 text-sm">
        <input type="hidden" name="tab" value="upcoming" />
        <span>{S.notif.range}</span>
        <select name="days" defaultValue={String(days)} className="rounded border px-2 py-1">
          <option value="7">{S.notif.week}</option>
          <option value="14">{S.notif.twoWeeks}</option>
          <option value="30">{S.notif.month}</option>
          <option value="90">{S.notif.threeMonths}</option>
        </select>
        <button className="rounded border px-3 py-1 text-brand">{S.notif.refresh}</button>
      </form>

      <div className="overflow-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-start text-xs text-gray-500">
            <tr>
              <th className="p-2">{S.notif.sendsAt}</th>
              <th className="p-2">{S.notif.kind}</th>
              <th className="p-2">{S.notif.about}</th>
              <th className="p-2">{S.notif.eventTime}</th>
              <th className="p-2">{S.notif.recipients}</th>
              <th className="p-2">{S.notif.status}</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {r?.digest && (
              <tr>
                <td className="p-2">{at(r.digest.send_at)}</td>
                <td className="p-2">{S.notif.weeklyDigest}</td>
                <td className="p-2">{S.notif.digestAbout}</td>
                <td className="p-2">—</td>
                <td className="p-2">{r.digest.recipients}</td>
                <td className="p-2"><span className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">{S.notif.scheduled}</span></td>
              </tr>
            )}
            {items.map((i) => {
              const due = new Date(i.send_at).getTime() <= now;
              return (
                <tr key={i.id}>
                  <td className="p-2">{at(i.send_at)}</td>
                  <td className="p-2">{S.notif.eventReminder}</td>
                  <td className="p-2">{i.title}</td>
                  <td className="p-2">{at(`${i.start_date}T${i.starts_at ?? '08:00'}`)}</td>
                  <td className="p-2">{i.recipients}</td>
                  <td className="p-2">
                    {i.already_sent ? (
                      <span className="rounded bg-green-100 px-2 py-0.5 text-xs text-green-700">{S.notif.sent}</span>
                    ) : due ? (
                      <span className="rounded bg-amber-100 px-2 py-0.5 text-xs text-amber-800">{S.notif.nextRun}</span>
                    ) : (
                      <span className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">{S.notif.scheduled}</span>
                    )}
                  </td>
                </tr>
              );
            })}
            {!items.length && !r?.digest && (
              <tr>
                <td colSpan={6} className="p-6 text-center text-gray-400">{S.notif.nothingScheduled}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="mt-3 text-xs text-gray-400">{S.notif.dailyNote}</p>
    </section>
  );
}

interface Person {
  user_id: string;
  name: string | null;
  role: string;
}

export async function SendTab({ orgId }: { orgId: string }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const at = (iso: string | null | undefined) => when(iso, T.labels.dateLocale);
  const supabase = await createClient();
  const [{ data: circles }, { data: dev }] = await Promise.all([
    supabase.from('circles').select('id, name').eq('organization_id', orgId).order('name'),
    supabase.rpc('admin_notification_devices', { p_org: orgId }),
  ]);
  const people = ((dev as { members?: Person[] } | null)?.members ?? []) as Person[];
  return (
    <section>
      <h2 className="mb-1 text-lg font-semibold">{S.notif.sendTitle}</h2>
      <p className="mb-4 text-sm text-gray-500">{S.notif.sendHint}</p>
      <SendForm orgId={orgId} circles={(circles ?? []) as { id: string; name: string }[]} people={people} labels={S.notif} />
    </section>
  );
}

interface LogRow {
  id: string;
  event_key: string;
  title: string;
  body: string | null;
  push_status: string | null;
  devices_total: number;
  devices_ok: number;
  push_error: string | null;
  created_at: string;
  user_name: string | null;
  role: string | null;
}

export async function LogTab({ orgId, from, to, event, status, names }: { orgId: string; from?: string; to?: string; event?: string; status?: string; names: Record<string, string> }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const at = (iso: string | null | undefined) => when(iso, T.labels.dateLocale);
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notification_log', {
    p_org: orgId,
    p_from: from || null,
    p_to: to || null,
    p_event: event || null,
    p_status: status || null,
    p_limit: 150,
    p_offset: 0,
  });
  const r = data as { stats: Record<string, number>; rows: LogRow[] } | null;
  const st = r?.stats ?? {};
  return (
    <section>
      <h2 className="mb-1 text-lg font-semibold">{S.notif.logTitle}</h2>
      <p className="mb-3 text-sm text-gray-500">{S.notif.logHint}</p>
      <form className="mb-4 flex flex-wrap items-end gap-2 text-sm">
        <input type="hidden" name="tab" value="log" />
        <label>{S.notif.from}<input type="date" name="from" defaultValue={from} className="mt-1 block rounded border px-2 py-1" /></label>
        <label>{S.notif.to}<input type="date" name="to" defaultValue={to} className="mt-1 block rounded border px-2 py-1" /></label>
        <label>{S.notif.kind}
          <select name="event" defaultValue={event ?? ''} className="mt-1 block rounded border px-2 py-1">
            <option value="">{S.notif.allKinds}</option>
            {Object.entries(names).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
            <option value="manual">{S.notif.manual}</option>
          </select>
        </label>
        <label>{S.notif.status}
          <select name="status" defaultValue={status ?? ''} className="mt-1 block rounded border px-2 py-1">
            <option value="">{S.notif.allStatuses}</option>
            {['sent', 'pending', 'failed', 'no_device', 'skipped'].map((k) => (
              <option key={k} value={k}>{S.notif.pushStatus[k]}</option>
            ))}
          </select>
        </label>
        <button className="rounded border px-3 py-1.5 text-brand">{S.notif.show}</button>
      </form>

      <div className="mb-3 flex flex-wrap gap-2 text-xs">
        <span className="rounded bg-gray-100 px-2 py-1">{S.notif.all} {st.total ?? 0}</span>
        <span className="rounded bg-green-100 px-2 py-1 text-green-700">{S.notif.pushStatus.sent} {st.sent ?? 0}</span>
        <span className="rounded bg-blue-100 px-2 py-1 text-blue-700">{S.notif.pushStatus.pending} {st.pending ?? 0}</span>
        <span className="rounded bg-red-100 px-2 py-1 text-red-700">{S.notif.pushStatus.failed} {st.failed ?? 0}</span>
        <span className="rounded bg-gray-100 px-2 py-1">{S.notif.pushStatus.no_device} {st.no_device ?? 0}</span>
        <span className="rounded bg-amber-100 px-2 py-1 text-amber-800">{S.notif.pushStatus.skipped} {st.skipped ?? 0}</span>
      </div>

      <div className="overflow-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-start text-xs text-gray-500">
            <tr>
              <th className="p-2">{S.notif.kind}</th>
              <th className="p-2">{S.notif.recipient}</th>
              <th className="p-2">{S.notif.notification}</th>
              <th className="p-2">{S.notif.status}</th>
              <th className="p-2">{S.notif.devices}</th>
              <th className="p-2">{S.notif.time}</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {(r?.rows ?? []).map((n) => {
              const s = n.push_status ? { label: S.notif.pushStatus[n.push_status] ?? n.push_status, cls: PUSH_STYLES[n.push_status] ?? '' } : null;
              return (
                <tr key={n.id}>
                  <td className="p-2 text-xs text-gray-500">{names[n.event_key] ?? (n.event_key === 'manual' ? S.notif.manual : n.event_key === 'test' ? S.notif.test : n.event_key)}</td>
                  <td className="p-2">{n.user_name ?? '—'} <span className="text-xs text-gray-400">{n.role ? S.notif.roles[n.role] : ''}</span></td>
                  <td className="p-2">
                    <b>{n.title}</b>
                    {n.body && <div className="text-xs text-gray-500">{n.body}</div>}
                  </td>
                  <td className="p-2">
                    {s ? <span className={`rounded px-2 py-0.5 text-xs ${s.cls}`}>{s.label}</span> : <span className="text-xs text-gray-400">{S.notif.beforeSetup}</span>}
                    {n.push_error && <div className="mt-0.5 text-[11px] text-gray-400">{n.push_error}</div>}
                  </td>
                  <td className="p-2 text-xs">{n.push_status ? `${n.devices_ok}/${n.devices_total}` : '—'}</td>
                  <td className="p-2 text-xs text-gray-500">{at(n.created_at)}</td>
                </tr>
              );
            })}
            {!(r?.rows ?? []).length && (
              <tr>
                <td colSpan={6} className="p-6 text-center text-gray-400">{S.notif.noLog}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  );
}

interface DeviceMember extends Person {
  devices: number;
  last_seen: string | null;
  platforms: string | null;
  label: string | null;
  app_version: string | null;
}

export async function DevicesTab({ orgId }: { orgId: string }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const at = (iso: string | null | undefined) => when(iso, T.labels.dateLocale);
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notification_devices', { p_org: orgId });
  const d = data as { configured: boolean; my_id: string; members: DeviceMember[] } | null;
  if (!d) return null;
  const withDevice = d.members.filter((m) => m.devices > 0).length;
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">{S.notif.devicesTitle}</h2>
      <p className="mb-3 text-sm text-gray-500">
        {S.notif.devicesHint}
      </p>
      <p className={`mb-3 rounded px-3 py-2 text-sm ${d.configured ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-800'}`}>
        {d.configured ? S.notif.configured : S.notif.notConfigured} · {fmt(S.notif.withPhones, { n: withDevice, total: d.members.length })}
      </p>
      <div className="overflow-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-start text-xs text-gray-500">
            <tr>
              <th className="p-2">{S.notif.name}</th>
              <th className="p-2">{S.notif.role}</th>
              <th className="p-2">{S.notif.devices}</th>
              <th className="p-2">{S.notif.device}</th>
              <th className="p-2">{S.notif.lastSeen}</th>
              <th className="p-2" />
            </tr>
          </thead>
          <tbody className="divide-y">
            {d.members.map((m) => (
              <tr key={m.user_id}>
                <td className="p-2">{m.name ?? '—'}{m.user_id === d.my_id ? <span className="text-xs text-gray-400"> {S.notif.you}</span> : null}</td>
                <td className="p-2 text-xs">{S.notif.roles[m.role] ?? m.role}</td>
                <td className="p-2">{m.devices || <span className="text-gray-400">{S.notif.none}</span>}</td>
                <td className="p-2 text-xs text-gray-500">{[m.label, m.platforms, m.app_version && `v${m.app_version}`].filter(Boolean).join(' · ') || '—'}</td>
                <td className="p-2 text-xs text-gray-500">{at(m.last_seen)}</td>
                <td className="p-2 text-end">
                  {m.devices > 0 && (
                    <form action={sendTestPush}>
                      <input type="hidden" name="orgId" value={orgId} />
                      <input type="hidden" name="userId" value={m.user_id} />
                      <SubmitButton className="rounded border px-3 py-1 text-xs text-brand hover:bg-gray-50" pendingText="...">
                        {S.notif.testSend}
                      </SubmitButton>
                    </form>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

interface Settings {
  timezone: string;
  quiet_from: string;
  quiet_to: string;
  day_start_time: string;
  late_grace_hours: number;
  idle_days: number;
  is_paused: boolean;
  idle_teacher_days: number;
  absence_alert_count: number;
  absence_alert_window: number;
  checkin_reminder_time: string;
}

export async function SettingsTab({ orgId }: { orgId: string }) {
  const { t: T } = await getI18n();
  const S = T.staff;
  const at = (iso: string | null | undefined) => when(iso, T.labels.dateLocale);
  const supabase = await createClient();
  const [{ data }, { data: digestData }, { data: settingRows }] = await Promise.all([
    supabase.rpc('admin_notification_config', { p_org: orgId }),
    supabase.rpc('get_digest_settings', { p_org: orgId }),
    supabase.from('organization_settings').select('key, value').eq('organization_id', orgId).in('key', ['attendance_reminder_enabled', 'attendance_reminder_hour']),
  ]);
  const s = (data as { settings?: Settings } | null)?.settings;
  if (!s) return null;
  const digest = digestData as { enabled: boolean; dow: number; hour: number } | null;
  const att = new Map(((settingRows ?? []) as { key: string; value: string | null }[]).map((r) => [r.key, r.value ?? '']));
  const DAYS = T.labels.weekdays;
  const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">{S.notif.generalTitle}</h2>
      <p className="mb-4 text-sm text-gray-500">{S.notif.generalHint} <b>{s.timezone}</b> {S.notif.tzNote}</p>
      <form action={saveNotificationSettings} className="grid gap-4 rounded-lg border bg-white p-5 sm:grid-cols-2">
        <input type="hidden" name="orgId" value={orgId} />
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.dayStart}</span>
          <input type="time" name="day_start_time" defaultValue={s.day_start_time} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.dayStartHint}</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.lateGrace}</span>
          <input type="number" name="late_grace_hours" min={0} max={72} defaultValue={s.late_grace_hours} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.lateGraceHint}</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.quietFrom}</span>
          <input type="time" name="quiet_from" defaultValue={s.quiet_from} required className={field} />
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.quietTo}</span>
          <input type="time" name="quiet_to" defaultValue={s.quiet_to} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.quietHint}</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.idleDays}</span>
          <input type="number" name="idle_days" min={1} max={30} defaultValue={s.idle_days} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.idleHint}</span>
        </label>
        <label className="flex items-start gap-2 pt-6 text-sm">
          <input type="checkbox" name="is_paused" defaultChecked={s.is_paused} className="mt-1" />
          <span>
            <span className="font-medium text-gray-700">{S.notif.pause}</span>
            <span className="block text-xs text-gray-400">{S.notif.pauseHint}</span>
          </span>
        </label>
        <div className="sm:col-span-2 border-t pt-4">
          <h3 className="font-semibold text-gray-800">{S.notif.smartTitle}</h3>
          <p className="text-xs text-gray-400">{S.notif.smartHint}</p>
        </div>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.idleTeacherDays}</span>
          <input type="number" name="idle_teacher_days" min={1} max={30} defaultValue={s.idle_teacher_days} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.idleTeacherHint}</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.checkinTime}</span>
          <input type="time" name="checkin_reminder_time" defaultValue={s.checkin_reminder_time} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.checkinHint}</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.absenceCount}</span>
          <input type="number" name="absence_alert_count" min={2} max={30} defaultValue={s.absence_alert_count} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">{S.notif.absenceHint}</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.absenceWindow}</span>
          <input type="number" name="absence_alert_window" min={7} max={90} defaultValue={s.absence_alert_window} required className={field} />
        </label>
        <div className="sm:col-span-2">
          <SubmitButton className="rounded bg-brand px-5 py-2 text-sm text-white" pendingText="...">{S.notif.saveSettings}</SubmitButton>
        </div>
      </form>
      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <form action={saveAttendanceReminderSetting} className="flex flex-col gap-3 rounded-lg border bg-white p-5">
          <input type="hidden" name="orgId" value={orgId} />
          <h3 className="font-semibold">{S.notif.attTitle}</h3>
          <p className="text-xs text-gray-500">{S.notif.attHint}</p>
          <label className="flex items-center gap-2 text-sm">
            <input type="checkbox" name="enabled" defaultChecked={(att.get('attendance_reminder_enabled') ?? 'true') !== 'false'} /> {S.notif.attEnable}
          </label>
          <label className="text-sm">
            {S.notif.afterHour}
            <select name="hour" defaultValue={att.get('attendance_reminder_hour') ?? '11'} className={field}>
              {Array.from({ length: 21 }, (_, h) => (
                <option key={h} value={h}>{String(h).padStart(2, '0')}:00</option>
              ))}
            </select>
          </label>
          <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm text-white" pendingText="...">{S.common.save}</SubmitButton>
        </form>
        {digest && (
          <form action={saveDigestSetting} className="flex flex-col gap-3 rounded-lg border bg-white p-5">
            <input type="hidden" name="orgId" value={orgId} />
            <h3 className="font-semibold">{S.notif.digestTitle}</h3>
            <p className="text-xs text-gray-500">{S.notif.digestHint}</p>
            <label className="flex items-center gap-2 text-sm">
              <input type="checkbox" name="enabled" defaultChecked={digest.enabled} /> {S.notif.digestEnable}
            </label>
            <div className="flex gap-3">
              <label className="flex-1 text-sm">
                {S.notif.day}
                <select name="dow" defaultValue={digest.dow} className={field}>
                  {DAYS.map((d, i) => (
                    <option key={d} value={i}>{d}</option>
                  ))}
                </select>
              </label>
              <label className="flex-1 text-sm">
                {S.notif.hour}
                <select name="hour" defaultValue={digest.hour} className={field}>
                  {Array.from({ length: 24 }, (_, h) => (
                    <option key={h} value={h}>{String(h).padStart(2, '0')}:00</option>
                  ))}
                </select>
              </label>
            </div>
            <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm text-white" pendingText="...">{S.common.save}</SubmitButton>
          </form>
        )}
      </div>
    </section>
  );
}
