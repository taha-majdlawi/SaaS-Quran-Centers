import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ruleText } from '@/lib/engagement/format';
import { evaluateAll } from './actions';

interface Badge {
  id: string;
  name: string;
  description: string | null;
  icon: string;
  color: string;
  rule_type: string;
  threshold: number;
  param: string | null;
  duration_days: number | null;
  is_active: boolean;
}

const OK: Record<string, string> = { deleted: 'تم حذف الشارة', evaluated: 'أُعيد تقييم الشارات لكل الطلاب ✓' };

export default async function BadgesPage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ ok?: string; error?: string }>;
}) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const [{ data: badges }, { data: grades }] = await Promise.all([
    supabase.from('badges').select('*').eq('organization_id', org.id).order('sort_order').order('name'),
    supabase.from('recitation_grades').select('key, label').eq('organization_id', org.id),
  ]);
  const labels = new Map((grades ?? []).map((g) => [g.key as string, g.label as string]));

  return (
    <div className="max-w-4xl">
      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h1 className="text-2xl font-bold">الشارات</h1>
        {isAdmin && (
          <div className="flex gap-2">
            <form action={evaluateAll}>
              <input type="hidden" name="orgId" value={org.id} />
              <SubmitButton className="rounded border px-4 py-2 text-sm text-brand" pendingText="جاري التقييم...">
                إعادة تقييم الكل
              </SubmitButton>
            </form>
            <a href="/badges/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
              + شارة جديدة
            </a>
          </div>
        )}
      </div>
      {ok && OK[ok] && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{OK[ok]}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <p className="mb-4 text-sm text-gray-500">
        الشارات التلقائية تُمنح فور تحقق شرطها (تسميع، حضور، اعتماد سرد). اليدوية يمنحها المشرف، أو المعلم لطلاب حلقته.
      </p>

      <div className="grid gap-3 sm:grid-cols-2">
        {((badges ?? []) as Badge[]).map((b) => (
          <a key={b.id} href={`/badges/${b.id}` as never} className={`flex items-start gap-3 rounded-lg border bg-white p-4 hover:bg-gray-50 ${b.is_active ? '' : 'opacity-60'}`}>
            <span className="flex h-12 w-12 items-center justify-center rounded-full text-2xl" style={{ backgroundColor: `${b.color}22`, border: `2px solid ${b.color}` }}>
              {b.icon}
            </span>
            <div className="text-sm">
              <b>{b.name}</b>
              {b.description && <p className="text-xs text-gray-500">{b.description}</p>}
              <p className="mt-1 text-xs text-gray-600">
                {ruleText(b, labels)}
                {b.duration_days && ` · تنتهي بعد ${b.duration_days} يوم`}
                {!b.is_active && ' · غير فعّالة'}
              </p>
            </div>
          </a>
        ))}
        {!badges?.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد شارات بعد</p>}
      </div>
    </div>
  );
}
