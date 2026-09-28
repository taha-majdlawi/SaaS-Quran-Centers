import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { reviewDeletion } from '@/lib/privacy/actions';
import { getI18n } from '@/lib/i18n/server';

interface Req {
  id: string;
  status: string;
  role: string;
  reason: string | null;
  name: string | null;
  email: string | null;
  student: string | null;
  created_at: string;
}

export default async function DeletionRequestsPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ ok?: string; error?: string }> }) {
  const { org: slug } = await params;
  const { ok, error } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  if (org.myRole !== 'admin') redirect('/dashboard' as never);
  const supabase = await createClient();
  const { data } = await supabase.rpc('list_deletion_requests', { p_org: org.id });
  const rows = (data ?? []) as Req[];

  return (
    <div className="max-w-3xl">
      <h1 className="mb-1 text-2xl font-bold">{S.deletion.heading}</h1>
      <p className="mb-4 text-sm text-gray-500">
        {S.deletion.intro}
      </p>
      {ok && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.deletion.updated}</p>}
      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      <div className="flex flex-col gap-3">
        {rows.map((r) => (
          <div key={r.id} className="rounded-lg border bg-white p-4 text-sm">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <div>
                <b>{r.name ?? '—'}</b> <span className="text-xs text-gray-500">({T.shell.roles[r.role] ?? r.role})</span>
                <div className="text-xs text-gray-400" dir="ltr">
                  {r.email}
                </div>
                {r.student && <div className="text-xs text-gray-500">{S.deletion.student} {r.student}</div>}
              </div>
              <span className={`rounded px-2 py-0.5 text-xs ${r.status === 'pending' ? 'bg-amber-50 text-amber-700' : 'bg-gray-100 text-gray-600'}`}>{S.deletion.status[r.status] ?? r.status}</span>
            </div>
            {r.reason && <p className="mt-2 text-gray-700">{r.reason}</p>}
            <p className="mt-1 text-xs text-gray-400">{new Date(r.created_at).toLocaleString(T.labels.dateLocale)}</p>
            {r.status !== 'completed' && r.status !== 'rejected' && (
              <div className="mt-3 flex gap-2 border-t pt-3">
                {[
                  ...(r.status === 'pending' ? [['approved', S.deletion.approve], ['rejected', S.deletion.reject]] : []),
                  ['completed', S.deletion.done],
                ].map(([st, label]) => (
                  <form key={st} action={reviewDeletion}>
                    <input type="hidden" name="orgId" value={org.id} />
                    <input type="hidden" name="id" value={r.id} />
                    <input type="hidden" name="status" value={st} />
                    <SubmitButton className="rounded border px-3 py-1 text-xs hover:bg-gray-50" pendingText="...">
                      {label}
                    </SubmitButton>
                  </form>
                ))}
              </div>
            )}
          </div>
        ))}
        {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">{S.deletion.empty}</p>}
      </div>
    </div>
  );
}
