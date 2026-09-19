import { createClient } from '@/lib/supabase/server';
import { AUDIENCE_LABELS } from '@/lib/calendar/format';

export interface AnnouncementRow {
  id: string;
  title: string;
  body: string;
  audience: string;
  circle_id: string | null;
  circle_name: string | null;
  pinned: boolean;
  published_at: string | null;
  expires_on: string | null;
  draft: boolean;
  author: string | null;
  can_edit: boolean;
}

export async function AnnouncementsList({ orgId, manage, ok }: { orgId: string; manage: boolean; ok?: string }) {
  const supabase = await createClient();
  const { data } = await supabase.rpc('list_announcements', { p_org: orgId });
  const rows = (data ?? []) as AnnouncementRow[];

  return (
    <div className="max-w-2xl">
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold">الإعلانات</h1>
        {manage && (
          <a href="/announcements/new" className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white">
            + إعلان جديد
          </a>
        )}
      </div>
      {ok === 'saved' && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم الحفظ ✓</p>}
      {ok === 'deleted' && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">تم الحذف</p>}
      <div className="flex flex-col gap-3">
        {rows.map((a) => (
          <article key={a.id} className="rounded-lg border bg-white p-4 text-sm">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h2 className="text-base font-bold">
                {a.pinned && '📌 '}
                {a.title}
              </h2>
              <span className="flex items-center gap-2 text-xs text-gray-500">
                {a.draft && <span className="rounded bg-amber-50 px-2 py-0.5 text-amber-700">مسودة</span>}
                {manage && (
                  <span className="rounded bg-gray-100 px-2 py-0.5">
                    {AUDIENCE_LABELS[a.audience]}
                    {a.circle_name && ` · ${a.circle_name}`}
                  </span>
                )}
                {a.published_at && new Date(a.published_at).toLocaleDateString('ar')}
              </span>
            </div>
            <p className="mt-2 whitespace-pre-line text-gray-700">{a.body}</p>
            <p className="mt-2 flex items-center justify-between text-xs text-gray-400">
              <span>{a.author}</span>
              {manage && a.can_edit && (
                <a href={`/announcements/${a.id}` as never} className="text-brand hover:underline">
                  تعديل
                </a>
              )}
            </p>
          </article>
        ))}
        {!rows.length && <p className="rounded-lg border bg-white p-6 text-center text-sm text-gray-400">لا توجد إعلانات</p>}
      </div>
    </div>
  );
}
