import { createClient } from '@/lib/supabase/server';
import { countText, type Usage } from '@/lib/billing/format';

/** "تبقى 5 طلاب يمكنك إضافتهم ضمن خطتك" above an add-student / add-teacher form (0067 usage). */
export async function PlanCapacityNote({ orgId, kind, isAdmin }: { orgId: string; kind: 'students' | 'teachers'; isAdmin: boolean }) {
  const supabase = await createClient();
  const { data } = await supabase.rpc('my_access', { p_org: orgId });
  const u = (data as { usage?: Usage | null } | null)?.usage;
  if (!u) return null;
  const max = kind === 'students' ? u.max_students : u.max_teachers;
  const left = kind === 'students' ? u.students_left : u.teachers_left;
  if (max == null || left == null) return null;
  const unit: [string, string, string] = kind === 'students' ? ['طالب', 'طالبان', 'طلاب'] : ['معلم', 'معلمان', 'معلمين'];
  const full = left === 0;
  const low = left <= (kind === 'students' ? 5 : 1);
  return (
    <p className={`mb-4 rounded px-3 py-2 text-sm ${full ? 'bg-red-50 text-red-700' : low ? 'bg-amber-50 text-amber-800' : 'bg-gray-50 text-gray-600'}`}>
      {full ? `وصلت للحد الأقصى في خطة «${u.plan_name ?? ''}» (${max}) — لا يمكن إضافة المزيد` : `تبقى ${countText(left, unit[0], unit[1], unit[2])} يمكنك إضافتهم ضمن خطة «${u.plan_name ?? ''}»`}
      {(full || low) && isAdmin && (
        <a href="/billing" className="ms-2 font-semibold underline">
          ترقية الخطة
        </a>
      )}
    </p>
  );
}
