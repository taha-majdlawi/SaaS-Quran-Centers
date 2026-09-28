import { createClient } from '@/lib/supabase/server';
import { plural, type Usage } from '@/lib/billing/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

/** "تبقى 5 طلاب يمكنك إضافتهم ضمن خطتك" above an add-student / add-teacher form (0067 usage). */
export async function PlanCapacityNote({ orgId, kind, isAdmin }: { orgId: string; kind: 'students' | 'teachers'; isAdmin: boolean }) {
  const supabase = await createClient();
  const { data } = await supabase.rpc('my_access', { p_org: orgId });
  const u = (data as { usage?: Usage | null } | null)?.usage;
  if (!u) return null;
  const max = kind === 'students' ? u.max_students : u.max_teachers;
  const left = kind === 'students' ? u.students_left : u.teachers_left;
  if (max == null || left == null) return null;
  const L = (await getI18n()).t.staff.billing;
  const unit = kind === 'students' ? L.students : L.teachers;
  const full = left === 0;
  const low = left <= (kind === 'students' ? 5 : 1);
  return (
    <p className={`mb-4 rounded px-3 py-2 text-sm ${full ? 'bg-red-50 text-red-700' : low ? 'bg-amber-50 text-amber-800' : 'bg-gray-50 text-gray-600'}`}>
      {full ? fmt(L.capFull, { plan: u.plan_name ?? '', max }) : fmt(L.capLeft, { n: plural(left, unit), plan: u.plan_name ?? '' })}
      {(full || low) && isAdmin && (
        <a href="/billing" className="ms-2 font-semibold underline">
          {L.upgrade}
        </a>
      )}
    </p>
  );
}
