import { notFound } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { Flash, btn, btnGhost, field } from '@/components/platform-flash';
import { addMember, deleteOrg, saveFeatures, setMember, setOrgSetting, updateOrg } from '@/lib/platform/actions';
import { FEATURES, ROLE_LABELS, STATUS_LABELS, fmt } from '@/lib/platform/labels';

interface Detail {
  org: { id: string; name: string; slug: string; logo_url: string | null; primary_color: string; secondary_color: string; timezone: string; status: string; plan_id: string | null; trial_ends_at: string | null; created_at: string };
  stats: { students: number; students_all: number; circles: number; recitations_30d: number; last_activity: string | null; chat_images_mb: number };
  members: { id: string; user_id: string; name: string | null; email: string | null; role: string; status: string; read_only: boolean }[];
  settings: { key: string; value: string }[];
  features: { key: string; effective: boolean; override: boolean | null; platform: boolean | null }[];
  audit: { at: string; action: string; table: string; actor: string | null }[];
}

export default async function OrgDetailPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ ok?: string; error?: string; created?: string; invite?: string }>;
}) {
  const { id } = await params;
  const { ok, error, created, invite } = await searchParams;
  const supabase = await createClient();
  const [{ data }, { data: overview }, { data: st }] = await Promise.all([
    supabase.rpc('platform_org_detail', { p_org: id }),
    supabase.rpc('platform_overview'),
    supabase.rpc('platform_org_storage', { p_org: id }),
  ]);
  const storage = st as { used_bytes: number; limit_mb: number | null; full: boolean; by_bucket: Record<string, number> } | null;
  const d = data as Detail | null;
  if (!d) notFound();
  const plans = ((overview as { plans: { id: string; name: string }[] } | null)?.plans ?? []);
  const o = d.org;
  const host = `${o.slug}.${process.env.NEXT_PUBLIC_ROOT_DOMAIN ?? 'bustan-alquran.com'}`;

  return (
    <div className="max-w-4xl">
      <a href="/organizations" className="text-sm text-blue-700 hover:underline">
        ← المراكز
      </a>
      <div className="mb-4 mt-2 flex flex-wrap items-center justify-between gap-2">
        <h1 className="text-2xl font-bold">
          {o.name} <span className="text-sm font-normal text-gray-400">{o.slug}</span>
        </h1>
        <a href={`https://${host}/dashboard`} target="_blank" rel="noreferrer" className={btnGhost}>
          دخول كمشرف ↗
        </a>
      </div>
      {created && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">أُنشئ المركز.</p>}
      {invite && (
        <p className="mb-4 break-all rounded bg-amber-50 px-3 py-2 text-sm text-amber-800" dir="ltr">
          https://{host}/join?token={invite}
        </p>
      )}
      <Flash ok={ok} error={error} />

      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-5">
        {[
          ['طلاب نشطون', d.stats.students],
          ['كل الطلاب', d.stats.students_all],
          ['الحلقات', d.stats.circles],
          ['تسميعات 30 يومًا', d.stats.recitations_30d],
          ['صور المحادثات', `${d.stats.chat_images_mb} MB`],
        ].map(([l, v]) => (
          <div key={String(l)} className="rounded-lg border bg-white p-3">
            <p className="text-xs text-gray-500">{l}</p>
            <p className="text-lg font-bold">{v}</p>
          </div>
        ))}
      </div>
      <p className="mb-6 text-xs text-gray-500">أُنشئ {fmt(o.created_at)} · آخر نشاط {fmt(d.stats.last_activity)}</p>

      <form action={updateOrg} className="mb-8 grid gap-3 rounded-lg border bg-white p-4 sm:grid-cols-2">
        <input type="hidden" name="id" value={o.id} />
        <h2 className="font-semibold sm:col-span-2">الهوية والاشتراك</h2>
        <label className="text-sm">
          الاسم
          <input name="name" defaultValue={o.name} required className={field} />
        </label>
        <label className="text-sm">
          المنطقة الزمنية
          <input name="timezone" defaultValue={o.timezone} dir="ltr" className={field} />
        </label>
        <label className="text-sm">
          اللون الأساسي
          <input name="primary" defaultValue={o.primary_color} dir="ltr" pattern="#[0-9a-fA-F]{6}" className={field} />
        </label>
        <label className="text-sm">
          اللون الثانوي
          <input name="secondary" defaultValue={o.secondary_color} dir="ltr" pattern="#[0-9a-fA-F]{6}" className={field} />
        </label>
        <label className="text-sm sm:col-span-2">
          رابط الشعار (https)
          <input name="logo" defaultValue={o.logo_url ?? ''} dir="ltr" className={field} />
        </label>
        <label className="text-sm">
          الحالة
          <select name="status" defaultValue={o.status} className={field}>
            {Object.entries(STATUS_LABELS).map(([v, l]) => (
              <option key={v} value={v}>
                {l}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          الخطة
          <select name="planId" defaultValue={o.plan_id ?? ''} className={field}>
            <option value="">بلا خطة (بلا حدود)</option>
            {plans.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name}
              </option>
            ))}
          </select>
        </label>
        <label className="text-sm">
          نهاية التجربة
          <input type="date" name="trialEnds" defaultValue={o.trial_ends_at?.slice(0, 10) ?? ''} className={field} />
        </label>
        <p className="self-end text-xs text-gray-500">رابط المركز ({o.slug}) ثابت: بريد دخول الطلاب مبني عليه.</p>
        <div className="sm:col-span-2">
          <SubmitButton className={btn} pendingText="جاري الحفظ...">
            حفظ
          </SubmitButton>
        </div>
      </form>

      {storage && (
        <section className="mb-6 rounded-lg border bg-white p-4 text-sm">
          <h2 className="mb-2 font-semibold">مساحة التخزين</h2>
          <p className={storage.full ? 'font-semibold text-red-700' : ''}>
            <span dir="ltr">
              {mb(storage.used_bytes)} / {storage.limit_mb == null ? '∞' : `${storage.limit_mb} MB`}
            </span>
            {storage.full && ' — ممتلئة، لا يمكن للمركز رفع ملفات جديدة'}
          </p>
          <ul className="mt-2 flex flex-wrap gap-2 text-xs text-gray-600">
            {Object.entries(storage.by_bucket).map(([b, n]) => (
              <li key={b} className="rounded bg-gray-100 px-2 py-1">
                {BUCKETS[b] ?? b}: <span dir="ltr">{mb(n)}</span>
              </li>
            ))}
          </ul>
          <p className="mt-2 text-xs text-gray-500">الحد من خطة المركز (الخطط ← مساحة التخزين). لا تظهر في الموقع التسويقي.</p>
        </section>
      )}

      <h2 className="mb-2 font-semibold">الأعضاء ({d.members.length})</h2>
      <div className="mb-3 overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <tbody>
            {d.members.map((m) => (
              <tr key={m.id} className="border-t first:border-0">
                <td className="px-3 py-2">
                  {m.name ?? '—'}
                  {m.read_only && <span className="mr-2 rounded bg-amber-50 px-2 py-0.5 text-xs text-amber-700">عرض فقط</span>}
                  <div className="text-xs text-gray-400" dir="ltr">
                    {m.email}
                  </div>
                </td>
                <td className="px-3 py-2">
                  <form action={setMember} className="flex items-center gap-2">
                    <input type="hidden" name="orgId" value={o.id} />
                    <input type="hidden" name="memberId" value={m.id} />
                    <select name="role" defaultValue={m.role} className="rounded border px-2 py-1">
                      {Object.entries(ROLE_LABELS).map(([v, l]) => (
                        <option key={v} value={v}>
                          {l}
                        </option>
                      ))}
                    </select>
                    <select name="status" defaultValue={m.status === 'suspended' ? 'suspended' : 'active'} className="rounded border px-2 py-1">
                      <option value="active">نشط</option>
                      <option value="suspended">موقوف</option>
                    </select>
                    <SubmitButton className={btnGhost} pendingText="...">
                      حفظ
                    </SubmitButton>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <form action={addMember} className="mb-8 flex flex-wrap items-end gap-2 rounded-lg border bg-white p-3 text-sm">
        <input type="hidden" name="orgId" value={o.id} />
        <label>
          إضافة عضو بالبريد
          <input name="email" type="email" required dir="ltr" className="mt-1 block rounded border px-3 py-2" />
        </label>
        <select name="role" defaultValue="teacher" className="rounded border px-2 py-2">
          {Object.entries(ROLE_LABELS).map(([v, l]) => (
            <option key={v} value={v}>
              {l}
            </option>
          ))}
        </select>
        <SubmitButton className={btnGhost} pendingText="...">
          إضافة / دعوة
        </SubmitButton>
      </form>

      <form action={saveFeatures} className="mb-8 rounded-lg border bg-white p-4">
        <input type="hidden" name="orgId" value={o.id} />
        <h2 className="mb-1 font-semibold">مفاتيح الميزات لهذا المركز</h2>
        <p className="mb-3 text-xs text-gray-500">«افتراضي» يتبع خطة المركز ثم إعداد المنصة. التعطيل يخفي الميزة ويمنعها في القاعدة.</p>
        <div className="grid gap-2 sm:grid-cols-3">
          {FEATURES.map(([key, label]) => {
            const f = d.features.find((x) => x.key === key);
            const value = f?.override === true ? 'on' : f?.override === false ? 'off' : '';
            return (
              <label key={key} className="flex items-center justify-between gap-2 rounded border px-3 py-2 text-sm">
                <span>
                  {label} {f && !f.effective && <span className="text-xs text-red-600">(معطّلة)</span>}
                </span>
                <select name={`f_${key}`} defaultValue={value} className="rounded border px-1 py-0.5 text-xs">
                  <option value="">افتراضي</option>
                  <option value="on">مفعّلة</option>
                  <option value="off">معطّلة</option>
                </select>
              </label>
            );
          })}
        </div>
        <div className="mt-3">
          <SubmitButton className={btn} pendingText="جاري الحفظ...">
            حفظ المفاتيح
          </SubmitButton>
        </div>
      </form>

      <h2 className="mb-2 font-semibold">إعدادات المركز الخام</h2>
      <div className="mb-3 overflow-x-auto rounded-lg border bg-white">
        <table className="w-full text-sm">
          <tbody>
            {d.settings.map((st) => (
              <tr key={st.key} className="border-t first:border-0">
                <td className="px-3 py-1.5 font-mono text-xs" dir="ltr">
                  {st.key}
                </td>
                <td className="px-3 py-1.5 text-xs text-gray-600">{st.value}</td>
                <td className="px-3 py-1.5 text-left">
                  <form action={setOrgSetting}>
                    <input type="hidden" name="orgId" value={o.id} />
                    <input type="hidden" name="key" value={st.key} />
                    <input type="hidden" name="remove" value="1" />
                    <ConfirmSubmitButton confirmMessage={`حذف الإعداد ${st.key}؟ يعود لقيمته الافتراضية.`} pendingText="..." className="text-xs text-red-600 hover:underline">
                      حذف
                    </ConfirmSubmitButton>
                  </form>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <form action={setOrgSetting} className="mb-8 flex flex-wrap items-end gap-2 text-sm">
        <input type="hidden" name="orgId" value={o.id} />
        <input name="key" required placeholder="flag_market_enabled" dir="ltr" className="rounded border px-3 py-2" />
        <input name="value" required placeholder="false" dir="ltr" className="rounded border px-3 py-2" />
        <SubmitButton className={btnGhost} pendingText="...">
          ضبط إعداد
        </SubmitButton>
      </form>

      <h2 className="mb-2 font-semibold">آخر عمليات المركز</h2>
      <ul className="mb-10 rounded-lg border bg-white p-3 text-xs text-gray-600">
        {d.audit.map((a, i) => (
          <li key={i} className="flex justify-between border-b py-1 last:border-0">
            <span>
              {a.action} · {a.table}
            </span>
            <span>
              {a.actor ?? '—'} · {fmt(a.at)}
            </span>
          </li>
        ))}
        {!d.audit.length && <li>—</li>}
      </ul>

      <form action={deleteOrg} className="rounded-lg border border-red-200 bg-red-50 p-4">
        <input type="hidden" name="id" value={o.id} />
        <h2 className="mb-1 font-semibold text-red-700">حذف المركز نهائيًا</h2>
        <p className="mb-3 text-xs text-red-700">يحذف كل بيانات المركز (طلاب، تسميع، حضور، محادثات...) ولا يمكن التراجع. للإيقاف المؤقت غيّر الحالة إلى «موقوف».</p>
        <div className="flex flex-wrap items-end gap-2">
          <label className="text-sm">
            اكتب رابط المركز ({o.slug}) للتأكيد
            <input name="confirmSlug" required dir="ltr" className="mt-1 block rounded border px-3 py-2" />
          </label>
          <ConfirmSubmitButton confirmMessage={`حذف «${o.name}» وكل بياناته نهائيًا؟`} pendingText="جاري الحذف..." className="rounded bg-red-600 px-4 py-2 text-sm font-semibold text-white">
            حذف نهائي
          </ConfirmSubmitButton>
        </div>
      </form>
    </div>
  );
}

const BUCKETS: Record<string, string> = {
  recitations: 'تسجيلات التسميع',
  'chat-images': 'صور المحادثات',
  'org-logos': 'الشعار',
  'market-images': 'صور السوق',
  'event-images': 'صور التقويم',
};

const mb = (bytes: number) => `${Math.round((bytes / 1048576) * 10) / 10} MB`;
