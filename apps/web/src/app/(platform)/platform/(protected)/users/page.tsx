import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { ConfirmSubmitButton } from '@/components/confirm-submit-button';
import { Flash, btnGhost } from '@/components/platform-flash';
import { deleteUser, setBan, setUserPassword } from '@/lib/platform/actions';
import { ROLE_LABELS, fmt } from '@/lib/platform/labels';

interface Row {
  id: string;
  email: string | null;
  name: string | null;
  created_at: string;
  last_sign_in: string | null;
  banned: boolean;
  owner: boolean;
  memberships: { org: string; slug: string; role: string; status: string }[];
}

const PAGE = 30;

export default async function UsersPage({ searchParams }: { searchParams: Promise<{ q?: string; page?: string; ok?: string; error?: string }> }) {
  const { q, page, ok, error } = await searchParams;
  const p = Math.max(1, Number(page) || 1);
  const supabase = await createClient();
  const { data } = await supabase.rpc('platform_users', { p_query: q || null, p_limit: PAGE, p_offset: (p - 1) * PAGE });
  const r = data as { total: number; rows: Row[] } | null;
  const pages = Math.max(1, Math.ceil((r?.total ?? 0) / PAGE));

  return (
    <div className="max-w-5xl">
      <h1 className="mb-4 text-2xl font-bold">الحسابات ({r?.total ?? 0})</h1>
      <Flash ok={ok} error={error} />
      <form className="mb-4 flex gap-2">
        <input name="q" defaultValue={q} placeholder="ابحث بالبريد أو الاسم" className="w-72 rounded border px-3 py-2 text-sm" />
        <button className="rounded border px-4 py-2 text-sm hover:bg-gray-50">بحث</button>
      </form>

      <div className="flex flex-col gap-3">
        {(r?.rows ?? []).map((u) => (
          <div key={u.id} className="rounded-lg border bg-white p-3 text-sm">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <b>{u.name ?? '—'}</b>{' '}
                {u.owner && <span className="rounded bg-purple-50 px-2 py-0.5 text-xs text-purple-700">مالك منصة</span>}{' '}
                {u.banned && <span className="rounded bg-red-50 px-2 py-0.5 text-xs text-red-600">موقوف</span>}
                <div className="text-xs text-gray-500" dir="ltr">
                  {u.email}
                </div>
                <div className="text-xs text-gray-400">
                  سُجّل {fmt(u.created_at)} · آخر دخول {fmt(u.last_sign_in)}
                </div>
              </div>
              <div className="text-xs text-gray-600">
                {u.memberships.map((m) => (
                  <div key={m.slug + m.role}>
                    <a href="/organizations" className="text-brand">
                      {m.org}
                    </a>{' '}
                    · {ROLE_LABELS[m.role] ?? m.role}
                    {m.status !== 'active' && ` (${m.status})`}
                  </div>
                ))}
              </div>
            </div>
            {!u.owner && (
              <details className="mt-2">
                <summary className="cursor-pointer text-xs text-gray-500">إجراءات</summary>
                <div className="mt-2 flex flex-wrap items-end gap-3 border-t pt-2">
                  <form action={setBan}>
                    <input type="hidden" name="userId" value={u.id} />
                    <input type="hidden" name="ban" value={u.banned ? '0' : '1'} />
                    <SubmitButton className={btnGhost} pendingText="...">
                      {u.banned ? 'إعادة التفعيل' : 'إيقاف الدخول'}
                    </SubmitButton>
                  </form>
                  <form action={setUserPassword} className="flex items-end gap-2">
                    <input type="hidden" name="userId" value={u.id} />
                    <input name="password" type="password" minLength={12} required placeholder="كلمة سر جديدة (12+)" autoComplete="new-password" className="rounded border px-2 py-1.5" />
                    <SubmitButton className={btnGhost} pendingText="...">
                      تعيين كلمة السر
                    </SubmitButton>
                  </form>
                  <form action={deleteUser} className="flex items-end gap-2">
                    <input type="hidden" name="userId" value={u.id} />
                    <input type="hidden" name="email" value={u.email ?? ''} />
                    <input name="confirmEmail" placeholder="اكتب بريده للتأكيد" dir="ltr" className="rounded border px-2 py-1.5" />
                    <ConfirmSubmitButton confirmMessage="حذف الحساب نهائيًا؟" pendingText="..." className="rounded border border-red-300 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50">
                      حذف الحساب
                    </ConfirmSubmitButton>
                  </form>
                </div>
              </details>
            )}
          </div>
        ))}
      </div>

      {pages > 1 && (
        <div className="mt-4 flex items-center justify-center gap-3 text-sm">
          {p > 1 && (
            <a href={`/users?q=${encodeURIComponent(q ?? '')}&page=${p - 1}` as never} className={btnGhost}>
              السابق
            </a>
          )}
          <span>
            {p} / {pages}
          </span>
          {p < pages && (
            <a href={`/users?q=${encodeURIComponent(q ?? '')}&page=${p + 1}` as never} className={btnGhost}>
              التالي
            </a>
          )}
        </div>
      )}
    </div>
  );
}
