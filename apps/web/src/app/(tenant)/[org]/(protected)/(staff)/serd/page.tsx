import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { SubmitButton } from '@/components/submit-button';
import { STATUS_LABELS, STATUS_STYLES, fmtDate, juzEquivalent, partsLabel, type SerdRow } from '@/lib/serd/format';
import { deleteSerd, reviewSerd } from './actions';
import { issueSerdCertificate } from '@/lib/certs/actions';

const FILTERS: [string, string][] = [
  ['', 'الكل'],
  ['submitted', 'بانتظار الاعتماد'],
  ['scheduled', 'مجدول'],
  ['approved', 'معتمد'],
  ['rejected', 'مرفوض'],
];

function Notice({ text, tone }: { text: string; tone: 'ok' | 'error' }) {
  return (
    <p className={`mb-4 rounded px-3 py-2 text-sm ${tone === 'ok' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-600'}`}>
      {text}
    </p>
  );
}

function RowCard({ row, isAdmin, students, orgId }: { row: SerdRow; isAdmin: boolean; students: { id: string; full_name: string }[]; orgId: string }) {
  return (
    <div className="rounded-lg border bg-white p-4 text-sm">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div>
          <span className="font-semibold">{row.student_name}</span>
          {row.student_code && <span className="text-xs text-gray-500"> · {row.student_code}</span>}
          {!row.student_id && row.status !== 'scheduled' && (
            <span className="mr-2 rounded bg-amber-50 px-2 py-0.5 text-xs text-amber-700">غير مرتبط بطالب</span>
          )}
        </div>
        <span className={`rounded px-2 py-0.5 text-xs ${STATUS_STYLES[row.status] ?? ''}`}>{STATUS_LABELS[row.status] ?? row.status}</span>
      </div>

      <p className="mt-1 text-gray-700">
        {partsLabel(row.parts)} <span className="text-xs text-gray-500">({juzEquivalent(row.total_eighths)} جزء)</span>
      </p>
      <p className="mt-1 text-xs text-gray-500">
        {fmtDate(row.session_date)}
        {row.examiner_name && <> · المستمع: {row.examiner_name}</>}
        {row.circle_teacher_name && <> · معلم الحلقة: {row.circle_teacher_name}</>}
        {row.status === 'scheduled' && <> · {row.assigned_teacher_name ? `مسند إلى ${row.assigned_teacher_name}` : 'مفتوح لأي معلم'}</>}
      </p>

      {row.score_percent != null && (
        <p className="mt-1">
          الدرجة: <b>{row.score_percent}%</b>
          {row.status === 'approved' && (
            <>
              {' '}
              · {row.score_percent >= (row.pass_percent_applied ?? 0) ? 'نجح' : 'يعيد'} (حد النجاح {row.pass_percent_applied}%) ·{' '}
              <span className="text-brand">+{row.points_awarded} نقطة</span>
            </>
          )}
        </p>
      )}
      {row.errors.length > 0 && (
        <p className="mt-1 text-xs text-gray-500">{row.errors.map((e) => `${e.name}: ${e.count} (−${e.deducted}%)`).join(' · ')}</p>
      )}
      {row.notes && <p className="mt-1 text-xs text-gray-600">{row.notes}</p>}
      {row.reject_reason && <p className="mt-1 text-xs text-red-600">سبب الرفض: {row.reject_reason}</p>}

      {isAdmin && row.status === 'approved' && row.student_id && row.score_percent != null && row.score_percent >= (row.pass_percent_applied ?? 0) && (
        <form action={issueSerdCertificate} className="mt-3 border-t pt-3">
          <input type="hidden" name="orgId" value={orgId} />
          <input type="hidden" name="sessionId" value={row.id} />
          <input type="hidden" name="back" value="/serd" />
          <SubmitButton className="rounded border border-brand px-3 py-1.5 text-xs text-brand hover:bg-gray-50" pendingText="جاري الإصدار...">
            إصدار شهادة
          </SubmitButton>
        </form>
      )}

      {isAdmin && (
        <div className="mt-3 flex flex-wrap items-end gap-3 border-t pt-3">
          {row.status === 'submitted' && (
            <>
              <form action={reviewSerd} className="flex items-end gap-2">
                <input type="hidden" name="id" value={row.id} />
                <input type="hidden" name="decision" value="approve" />
                {!row.student_id && (
                  <select name="studentId" required defaultValue="" className="rounded border px-2 py-1.5 text-sm">
                    <option value="" disabled>
                      اربط بطالب
                    </option>
                    {students.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.full_name}
                      </option>
                    ))}
                  </select>
                )}
                <SubmitButton className="rounded bg-brand px-3 py-1.5 text-sm font-semibold text-white" pendingText="...">
                  اعتماد
                </SubmitButton>
              </form>
              <form action={reviewSerd} className="flex items-end gap-2">
                <input type="hidden" name="id" value={row.id} />
                <input type="hidden" name="decision" value="reject" />
                <input name="reason" placeholder="سبب الرفض" className="rounded border px-2 py-1.5 text-sm" />
                <SubmitButton className="rounded border border-red-200 px-3 py-1.5 text-sm text-red-600" pendingText="...">
                  رفض
                </SubmitButton>
              </form>
            </>
          )}
          {row.status === 'rejected' && row.score_percent != null && (
            <form action={reviewSerd}>
              <input type="hidden" name="id" value={row.id} />
              <input type="hidden" name="decision" value="approve" />
              <SubmitButton className="rounded border px-3 py-1.5 text-sm text-brand" pendingText="...">
                إعادة اعتماد
              </SubmitButton>
            </form>
          )}
          <form action={deleteSerd} className="mr-auto">
            <input type="hidden" name="id" value={row.id} />
            <ConfirmSubmitButton
              confirmMessage="سيُحذف هذا السرد وتُخصم نقاطه إن كان معتمدًا. متأكد؟"
              pendingText="..."
              className="rounded border border-red-200 px-3 py-1.5 text-xs text-red-600 hover:bg-red-50"
            >
              حذف
            </ConfirmSubmitButton>
          </form>
        </div>
      )}
    </div>
  );
}

export default async function SerdPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ status?: string; page?: string; saved?: string; scheduled?: string; reviewed?: string; deleted?: string; ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const sp = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';
  const page = Math.max(1, Number(sp.page ?? 1));
  const pageSize = 30;

  let rows: SerdRow[] = [];
  let scheduled: SerdRow[] = [];
  let total = 0;
  let students: { id: string; full_name: string }[] = [];

  if (isAdmin) {
    const [{ data: list }, { data: studs }] = await Promise.all([
      supabase.rpc('admin_serd_list', {
        p_org: org.id,
        p_status: sp.status || null,
        p_from: null,
        p_to: null,
        p_search: null,
        p_limit: pageSize,
        p_offset: (page - 1) * pageSize,
      }),
      supabase.from('students_profile').select('id, full_name').eq('organization_id', org.id).order('full_name'),
    ]);
    const result = list as { total: number; rows: SerdRow[] } | null;
    rows = result?.rows ?? [];
    total = result?.total ?? 0;
    students = studs ?? [];
  } else {
    const [{ data: mine }, { data: open }] = await Promise.all([
      supabase.rpc('teacher_my_serd', { p_org: org.id, p_limit: 60 }),
      supabase.rpc('teacher_scheduled_serd', { p_org: org.id }),
    ]);
    rows = (mine ?? []) as SerdRow[];
    scheduled = (open ?? []) as SerdRow[];
  }

  const pages = Math.max(1, Math.ceil(total / pageSize));
  const link = (status: string, p = 1) => `/serd?${new URLSearchParams({ ...(status ? { status } : {}), page: String(p) })}`;

  return (
    <div className="max-w-4xl">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">السرد القرآني</h1>
        <div className="flex gap-2 text-sm">
          <a href="/serd/new" className="rounded bg-brand px-4 py-2 font-semibold text-white">
            رصد سرد
          </a>
          {isAdmin && (
            <>
              <a href="/serd/schedule" className="rounded border px-4 py-2 text-brand">
                جدولة
              </a>
              <a href="/serd/report" className="rounded border px-4 py-2 text-brand">
                التقرير
              </a>
              <a href="/serd/settings" className="rounded border px-4 py-2 text-brand">
                الإعدادات
              </a>
            </>
          )}
        </div>
      </div>

      {sp.error && <Notice tone="error" text={sp.error} />}
      {sp.saved !== undefined && <Notice tone="ok" text={`تم إرسال السرد للاعتماد${sp.saved ? ` — الدرجة ${sp.saved}%` : ''}`} />}
      {sp.scheduled && <Notice tone="ok" text="تمت جدولة السرد" />}
      {sp.reviewed && <Notice tone="ok" text={sp.reviewed === 'approve' ? 'تم الاعتماد' : 'تم الرفض'} />}
      {sp.deleted && <Notice tone="ok" text="تم الحذف" />}
      {sp.ok === 'certificate' && <Notice tone="ok" text="صدرت الشهادة — تجدها في صفحة الشهادات" />}

      {isAdmin && (
        <div className="mb-4 flex flex-wrap gap-2 text-sm">
          {FILTERS.map(([value, label]) => (
            <a
              key={value}
              href={link(value) as never}
              className={`rounded-full border px-3 py-1 ${(sp.status ?? '') === value ? 'bg-brand text-white' : 'bg-white'}`}
            >
              {label}
            </a>
          ))}
        </div>
      )}

      {!isAdmin && scheduled.length > 0 && (
        <section className="mb-6">
          <h2 className="mb-2 font-semibold">سرد مطلوب ({scheduled.length})</h2>
          <div className="flex flex-col gap-2">
            {scheduled.map((s) => (
              <div key={s.id} className="flex flex-wrap items-center justify-between gap-2 rounded-lg border bg-white p-4 text-sm">
                <div>
                  <p className="font-semibold">{s.student_name}</p>
                  <p className="text-gray-600">{partsLabel(s.parts)}</p>
                  <p className="text-xs text-gray-500">
                    {fmtDate(s.session_date)} · {s.assigned_to_me ? 'مخصّص لك' : 'عام — أي معلم يستطيع رصده'}
                    {s.overdue && <span className="text-red-600"> · متأخر</span>}
                  </p>
                </div>
                <a href={`/serd/new?session=${s.id}` as never} className="rounded bg-brand px-3 py-1.5 font-semibold text-white">
                  رصد
                </a>
              </div>
            ))}
          </div>
        </section>
      )}

      {!isAdmin && <h2 className="mb-2 font-semibold">سردي</h2>}
      <div className="flex flex-col gap-3">
        {rows.map((r) => (
          <RowCard key={r.id} row={r} isAdmin={isAdmin} students={students} orgId={org.id} />
        ))}
        {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا يوجد سرد بعد</p>}
      </div>

      {isAdmin && pages > 1 && (
        <div className="mt-4 flex items-center justify-center gap-3 text-sm">
          {page > 1 && (
            <a href={link(sp.status ?? '', page - 1) as never} className="rounded border px-3 py-1">
              السابق
            </a>
          )}
          <span>
            {page} / {pages}
          </span>
          {page < pages && (
            <a href={link(sp.status ?? '', page + 1) as never} className="rounded border px-3 py-1">
              التالي
            </a>
          )}
        </div>
      )}
    </div>
  );
}
