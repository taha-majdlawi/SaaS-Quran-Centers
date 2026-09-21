import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { saveNotificationSettings, sendTestPush } from '@/lib/notifications/actions';
import { PUSH_STATUS, ROLE_LABELS } from '@/lib/notifications/catalog';
import { TemplateEditor, type TemplateRow } from './template-editor';
import { SendForm } from './send-form';

const fmt = (iso: string | null | undefined, withTime = true) =>
  iso ? new Date(iso).toLocaleString('ar', { day: 'numeric', month: 'short', year: 'numeric', ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}) }) : '—';

export const ADMIN_TABS: [string, string][] = [
  ['inbox', 'الوارد'],
  ['templates', 'القوالب'],
  ['upcoming', 'الجدول القادم'],
  ['send', 'إرسال فوري'],
  ['log', 'السجل'],
  ['devices', 'الأجهزة'],
  ['settings', 'الإعدادات'],
];

export function TabsNav({ active }: { active: string }) {
  return (
    <nav className="mb-6 flex flex-wrap gap-1 border-b">
      {ADMIN_TABS.map(([key, label]) => (
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
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notification_config', { p_org: orgId });
  const templates = ((data as { templates?: TemplateRow[] } | null)?.templates ?? []) as TemplateRow[];
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">قوالب الإشعارات</h2>
      <p className="mb-4 text-sm text-gray-500">
        صياغة كل نوع يصل لمركزك: عدّل العنوان والنص بالمتغيرات، وحدّد من يصله، وأوقف ما لا تريده. أي نوع تعدّله يخص مركزك وحده.
      </p>
      <div className="flex flex-col gap-2">
        {templates.map((t) => (
          <TemplateEditor key={t.event_key} orgId={orgId} t={t} />
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
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notifications_upcoming', { p_org: orgId, p_days: days });
  const r = data as { lead_hours: number; items: UpcomingItem[]; digest: { send_at: string; recipients: number } | null; paused: boolean } | null;
  const items = r?.items ?? [];
  const now = Date.now();
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">الإشعارات المجدولة القادمة</h2>
      <p className="mb-3 text-sm text-gray-500">
        ما سيصل تلقائيًا في الفترة القادمة: تذكير الفعاليات (قبل الموعد بـ {r?.lead_hours ?? 24} ساعة) والملخص الأسبوعي.
        {r?.paused && <b className="text-amber-700"> — الإرسال موقوف مؤقتًا الآن من الإعدادات.</b>}
      </p>
      <form className="mb-4 flex items-center gap-2 text-sm">
        <input type="hidden" name="tab" value="upcoming" />
        <span>المدى</span>
        <select name="days" defaultValue={String(days)} className="rounded border px-2 py-1">
          <option value="7">أسبوع</option>
          <option value="14">أسبوعان</option>
          <option value="30">شهر</option>
          <option value="90">ثلاثة أشهر</option>
        </select>
        <button className="rounded border px-3 py-1 text-brand">تحديث</button>
      </form>

      <div className="overflow-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right text-xs text-gray-500">
            <tr>
              <th className="p-2">سيصل</th>
              <th className="p-2">النوع</th>
              <th className="p-2">بشأن</th>
              <th className="p-2">موعد الحدث</th>
              <th className="p-2">المستلمون</th>
              <th className="p-2">الحالة</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {r?.digest && (
              <tr>
                <td className="p-2">{fmt(r.digest.send_at)}</td>
                <td className="p-2">ملخص الأسبوع</td>
                <td className="p-2">أداء كل طالب هذا الأسبوع</td>
                <td className="p-2">—</td>
                <td className="p-2">{r.digest.recipients}</td>
                <td className="p-2"><span className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">مجدول</span></td>
              </tr>
            )}
            {items.map((i) => {
              const due = new Date(i.send_at).getTime() <= now;
              return (
                <tr key={i.id}>
                  <td className="p-2">{fmt(i.send_at)}</td>
                  <td className="p-2">تذكير بفعالية</td>
                  <td className="p-2">{i.title}</td>
                  <td className="p-2">{fmt(`${i.start_date}T${i.starts_at ?? '08:00'}`)}</td>
                  <td className="p-2">{i.recipients}</td>
                  <td className="p-2">
                    {i.already_sent ? (
                      <span className="rounded bg-green-100 px-2 py-0.5 text-xs text-green-700">أُرسل</span>
                    ) : due ? (
                      <span className="rounded bg-amber-100 px-2 py-0.5 text-xs text-amber-800">يُرسل في الدورة القادمة</span>
                    ) : (
                      <span className="rounded bg-blue-100 px-2 py-0.5 text-xs text-blue-700">مجدول</span>
                    )}
                  </td>
                </tr>
              );
            })}
            {!items.length && !r?.digest && (
              <tr>
                <td colSpan={6} className="p-6 text-center text-gray-400">لا شيء مجدول في هذه الفترة</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      <p className="mt-3 text-xs text-gray-400">تذكير الطلاب المتأخرين عن التسميع وتذكير المعلمين بتسجيل الحضور يُحسبان يوميًا ولا يُعرضان هنا مسبقًا.</p>
    </section>
  );
}

interface Person {
  user_id: string;
  name: string | null;
  role: string;
}

export async function SendTab({ orgId }: { orgId: string }) {
  const supabase = await createClient();
  const [{ data: circles }, { data: dev }] = await Promise.all([
    supabase.from('circles').select('id, name').eq('organization_id', orgId).order('name'),
    supabase.rpc('admin_notification_devices', { p_org: orgId }),
  ]);
  const people = ((dev as { members?: Person[] } | null)?.members ?? []) as Person[];
  return (
    <section>
      <h2 className="mb-1 text-lg font-semibold">إرسال فوري</h2>
      <p className="mb-4 text-sm text-gray-500">رسالة تصل الآن إلى قائمة الإشعارات وإلى هواتف من سجّلوا الهاتف. تظهر في السجل بحالة كل مستلم.</p>
      <SendForm orgId={orgId} circles={(circles ?? []) as { id: string; name: string }[]} people={people} />
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
      <h2 className="mb-1 text-lg font-semibold">سجل الإرسال</h2>
      <p className="mb-3 text-sm text-gray-500">كل ما أُرسل لأعضاء مركزك وحالة وصوله إلى الهاتف. الافتراضي آخر 30 يومًا.</p>
      <form className="mb-4 flex flex-wrap items-end gap-2 text-sm">
        <input type="hidden" name="tab" value="log" />
        <label>من<input type="date" name="from" defaultValue={from} className="mt-1 block rounded border px-2 py-1" /></label>
        <label>إلى<input type="date" name="to" defaultValue={to} className="mt-1 block rounded border px-2 py-1" /></label>
        <label>النوع
          <select name="event" defaultValue={event ?? ''} className="mt-1 block rounded border px-2 py-1">
            <option value="">كل الأنواع</option>
            {Object.entries(names).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
            <option value="manual">إشعار يدوي</option>
          </select>
        </label>
        <label>الحالة
          <select name="status" defaultValue={status ?? ''} className="mt-1 block rounded border px-2 py-1">
            <option value="">كل الحالات</option>
            {['sent', 'pending', 'failed', 'no_device', 'skipped'].map((k) => (
              <option key={k} value={k}>{PUSH_STATUS[k].label}</option>
            ))}
          </select>
        </label>
        <button className="rounded border px-3 py-1.5 text-brand">عرض</button>
      </form>

      <div className="mb-3 flex flex-wrap gap-2 text-xs">
        <span className="rounded bg-gray-100 px-2 py-1">الكل {st.total ?? 0}</span>
        <span className="rounded bg-green-100 px-2 py-1 text-green-700">وصل {st.sent ?? 0}</span>
        <span className="rounded bg-blue-100 px-2 py-1 text-blue-700">في الطابور {st.pending ?? 0}</span>
        <span className="rounded bg-red-100 px-2 py-1 text-red-700">فشل {st.failed ?? 0}</span>
        <span className="rounded bg-gray-100 px-2 py-1">بلا هاتف {st.no_device ?? 0}</span>
        <span className="rounded bg-amber-100 px-2 py-1 text-amber-800">لم يُرسل {st.skipped ?? 0}</span>
      </div>

      <div className="overflow-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right text-xs text-gray-500">
            <tr>
              <th className="p-2">النوع</th>
              <th className="p-2">المستلم</th>
              <th className="p-2">الإشعار</th>
              <th className="p-2">الحالة</th>
              <th className="p-2">الأجهزة</th>
              <th className="p-2">الوقت</th>
            </tr>
          </thead>
          <tbody className="divide-y">
            {(r?.rows ?? []).map((n) => {
              const s = n.push_status ? PUSH_STATUS[n.push_status] : null;
              return (
                <tr key={n.id}>
                  <td className="p-2 text-xs text-gray-500">{names[n.event_key] ?? (n.event_key === 'manual' ? 'إشعار يدوي' : n.event_key === 'test' ? 'تجربة' : n.event_key)}</td>
                  <td className="p-2">{n.user_name ?? '—'} <span className="text-xs text-gray-400">{n.role ? ROLE_LABELS[n.role] : ''}</span></td>
                  <td className="p-2">
                    <b>{n.title}</b>
                    {n.body && <div className="text-xs text-gray-500">{n.body}</div>}
                  </td>
                  <td className="p-2">
                    {s ? <span className={`rounded px-2 py-0.5 text-xs ${s.cls}`}>{s.label}</span> : <span className="text-xs text-gray-400">قبل التفعيل</span>}
                    {n.push_error && <div className="mt-0.5 text-[11px] text-gray-400">{n.push_error}</div>}
                  </td>
                  <td className="p-2 text-xs">{n.push_status ? `${n.devices_ok}/${n.devices_total}` : '—'}</td>
                  <td className="p-2 text-xs text-gray-500">{fmt(n.created_at)}</td>
                </tr>
              );
            })}
            {!(r?.rows ?? []).length && (
              <tr>
                <td colSpan={6} className="p-6 text-center text-gray-400">لا سجلات في هذه الفترة</td>
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
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notification_devices', { p_org: orgId });
  const d = data as { configured: boolean; my_id: string; members: DeviceMember[] } | null;
  if (!d) return null;
  const withDevice = d.members.filter((m) => m.devices > 0).length;
  return (
    <section className="max-w-3xl">
      <h2 className="mb-1 text-lg font-semibold">الأجهزة المسجَّلة</h2>
      <p className="mb-3 text-sm text-gray-500">
        يُسجَّل الهاتف عند أول دخول للتطبيق ومنح إذن الإشعارات. من لا هاتف له تصله الإشعارات داخل التطبيق فقط.
      </p>
      <p className={`mb-3 rounded px-3 py-2 text-sm ${d.configured ? 'bg-green-50 text-green-700' : 'bg-amber-50 text-amber-800'}`}>
        {d.configured ? 'الخدمة مفعّلة على المنصة' : 'الخدمة غير مفعّلة على المنصة بعد'} · سجّل هواتفهم {withDevice} من {d.members.length} عضو
      </p>
      <div className="overflow-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 text-right text-xs text-gray-500">
            <tr>
              <th className="p-2">الاسم</th>
              <th className="p-2">الدور</th>
              <th className="p-2">الأجهزة</th>
              <th className="p-2">الجهاز</th>
              <th className="p-2">آخر ظهور</th>
              <th className="p-2" />
            </tr>
          </thead>
          <tbody className="divide-y">
            {d.members.map((m) => (
              <tr key={m.user_id}>
                <td className="p-2">{m.name ?? '—'}{m.user_id === d.my_id ? <span className="text-xs text-gray-400"> (أنت)</span> : null}</td>
                <td className="p-2 text-xs">{ROLE_LABELS[m.role] ?? m.role}</td>
                <td className="p-2">{m.devices || <span className="text-gray-400">لا</span>}</td>
                <td className="p-2 text-xs text-gray-500">{[m.label, m.platforms, m.app_version && `v${m.app_version}`].filter(Boolean).join(' · ') || '—'}</td>
                <td className="p-2 text-xs text-gray-500">{fmt(m.last_seen)}</td>
                <td className="p-2 text-left">
                  {m.devices > 0 && (
                    <form action={sendTestPush}>
                      <input type="hidden" name="orgId" value={orgId} />
                      <input type="hidden" name="userId" value={m.user_id} />
                      <SubmitButton className="rounded border px-3 py-1 text-xs text-brand hover:bg-gray-50" pendingText="...">
                        إرسال تجريبي
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
}

export async function SettingsTab({ orgId }: { orgId: string }) {
  const supabase = await createClient();
  const { data } = await supabase.rpc('admin_notification_config', { p_org: orgId });
  const s = (data as { settings?: Settings } | null)?.settings;
  if (!s) return null;
  const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';
  return (
    <section className="max-w-2xl">
      <h2 className="mb-1 text-lg font-semibold">الإعدادات العامة</h2>
      <p className="mb-4 text-sm text-gray-500">توقيت وقواعد الإرسال لمركزك. المنطقة الزمنية الحالية: <b>{s.timezone}</b> (تُغيَّر من إعدادات المركز).</p>
      <form action={saveNotificationSettings} className="grid gap-4 rounded-lg border bg-white p-5 sm:grid-cols-2">
        <input type="hidden" name="orgId" value={orgId} />
        <label className="text-sm">
          <span className="font-medium text-gray-700">بداية اليوم</span>
          <input type="time" name="day_start_time" defaultValue={s.day_start_time} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">أول وقت تُرسل فيه تذكيرات اليوم (مثل الطلاب المتأخرين).</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">مهلة التأخير (ساعات)</span>
          <input type="number" name="late_grace_hours" min={0} max={72} defaultValue={s.late_grace_hours} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">بعدها يُسقَط إشعار لم يُرسل (مثلًا بسبب ساعات الصمت).</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">الصمت من</span>
          <input type="time" name="quiet_from" defaultValue={s.quiet_from} required className={field} />
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">الصمت إلى</span>
          <input type="time" name="quiet_to" defaultValue={s.quiet_to} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">لا تصل إشعارات الهاتف في هذه الساعات وتُؤجَّل إلى الصباح (الرسائل والاختبار والإرسال الفوري مستثناة).</span>
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">أيام التأخر عن التسميع</span>
          <input type="number" name="idle_days" min={1} max={30} defaultValue={s.idle_days} required className={field} />
          <span className="mt-1 block text-xs text-gray-400">أيام دوام متتالية بلا تسميع قبل تذكير الطالب وولي أمره.</span>
        </label>
        <label className="flex items-start gap-2 pt-6 text-sm">
          <input type="checkbox" name="is_paused" defaultChecked={s.is_paused} className="mt-1" />
          <span>
            <span className="font-medium text-gray-700">إيقاف الإرسال مؤقتًا</span>
            <span className="block text-xs text-gray-400">يوقف إشعارات الهاتف والتذكيرات التلقائية؛ تبقى قائمة الإشعارات داخل التطبيق تعمل.</span>
          </span>
        </label>
        <div className="sm:col-span-2">
          <SubmitButton className="rounded bg-brand px-5 py-2 text-sm text-white" pendingText="...">حفظ الإعدادات</SubmitButton>
        </div>
      </form>
      <p className="mt-4 text-sm text-gray-500">
        يوم وساعة الملخص الأسبوعي ووقت تذكير الحضور من <a className="text-brand hover:underline" href={'/settings' as never}>إعدادات المركز</a>.
      </p>
    </section>
  );
}
