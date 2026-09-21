import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';

interface Result {
  students: { id: string; name: string; code: string; circle: string | null; status: string }[];
  teachers: { id: string; user_id: string; name: string; role: string }[];
  circles: { id: string; name: string }[];
}

export default async function SearchPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ q?: string }> }) {
  const { org: slug } = await params;
  const { q = '' } = await searchParams;
  const org = await getOrgContext(slug);
  const supabase = await createClient();
  const query = q.trim();
  const { data } = query.length >= 2 ? await supabase.rpc('search_global', { p_org: org.id, p_q: query, p_limit: 20 }) : { data: null };
  const r = data as Result | null;

  return (
    <div className="max-w-2xl">
      <h1 className="mb-4 text-2xl font-bold">بحث شامل</h1>
      <form className="mb-6 flex gap-2">
        <input name="q" defaultValue={query} autoFocus placeholder="اسم طالب أو معلم أو حلقة، أو رقم الطالب" className="flex-1 rounded border bg-white px-3 py-2 text-sm" />
        <button className="rounded bg-brand px-4 py-2 text-sm text-white">بحث</button>
      </form>
      {query && query.length < 2 && <p className="text-sm text-gray-500">اكتب حرفين على الأقل</p>}
      {r && (
        <div className="flex flex-col gap-5">
          <Section title="الطلاب" empty={!r.students.length}>
            {r.students.map((s) => (
              <li key={s.id} className="flex justify-between py-2">
                <a href={`/students/${s.id}` as never} className="text-brand hover:underline">{s.name}</a>
                <span className="text-xs text-gray-400">{s.code} · {s.circle ?? 'بدون حلقة'}{s.status !== 'active' ? ' · غير نشط' : ''}</span>
              </li>
            ))}
          </Section>
          {org.myRole === 'admin' && (
            <Section title="المعلمون والمشرفون" empty={!r.teachers.length}>
              {r.teachers.map((t) => (
                <li key={t.id} className="flex justify-between py-2">
                  <a href={`/teachers/${t.id}` as never} className="text-brand hover:underline">{t.name}</a>
                  <span className="text-xs text-gray-400">{t.role === 'admin' ? 'مشرف' : 'معلم'}</span>
                </li>
              ))}
            </Section>
          )}
          <Section title="الحلقات" empty={!r.circles.length}>
            {r.circles.map((c) => (
              <li key={c.id} className="py-2">
                <a href={`/circles/${c.id}` as never} className="text-brand hover:underline">{c.name}</a>
              </li>
            ))}
          </Section>
        </div>
      )}
    </div>
  );
}

function Section({ title, empty, children }: { title: string; empty: boolean; children: React.ReactNode }) {
  return (
    <section className="rounded-lg border bg-white p-4">
      <h2 className="mb-1 font-semibold">{title}</h2>
      {empty ? <p className="text-sm text-gray-400">لا نتائج</p> : <ul className="divide-y text-sm">{children}</ul>}
    </section>
  );
}
