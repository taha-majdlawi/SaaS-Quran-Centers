import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { getI18n } from '@/lib/i18n/server';

interface Result {
  students: { id: string; name: string; code: string; circle: string | null; status: string }[];
  teachers: { id: string; user_id: string; name: string; role: string }[];
  circles: { id: string; name: string }[];
}

export default async function SearchPage({ params, searchParams }: { params: Promise<{ org: string }>; searchParams: Promise<{ q?: string }> }) {
  const { org: slug } = await params;
  const { q = '' } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();
  const query = q.trim();
  const { data } = query.length >= 2 ? await supabase.rpc('search_global', { p_org: org.id, p_q: query, p_limit: 20 }) : { data: null };
  const r = data as Result | null;

  return (
    <div className="max-w-2xl">
      <h1 className="mb-4 text-2xl font-bold">{S.search.title}</h1>
      <form className="mb-6 flex gap-2">
        <input name="q" defaultValue={query} autoFocus placeholder={S.search.placeholder} className="flex-1 rounded border bg-white px-3 py-2 text-sm" />
        <button className="rounded bg-brand px-4 py-2 text-sm text-white">{S.search.go}</button>
      </form>
      {query && query.length < 2 && <p className="text-sm text-gray-500">{S.search.min}</p>}
      {r && (
        <div className="flex flex-col gap-5">
          <Section title={S.search.students} empty={!r.students.length} none={S.search.none}>
            {r.students.map((s) => (
              <li key={s.id} className="flex justify-between py-2">
                <a href={`/students/${s.id}` as never} className="text-brand hover:underline">{s.name}</a>
                <span className="text-xs text-gray-400">{s.code} · {s.circle ?? S.search.noCircle}{s.status !== 'active' ? S.search.inactive : ''}</span>
              </li>
            ))}
          </Section>
          {org.myRole === 'admin' && (
            <Section title={S.search.staff} empty={!r.teachers.length} none={S.search.none}>
              {r.teachers.map((t) => (
                <li key={t.id} className="flex justify-between py-2">
                  <a href={`/teachers/${t.id}` as never} className="text-brand hover:underline">{t.name}</a>
                  <span className="text-xs text-gray-400">{T.shell.roles[t.role] ?? t.role}</span>
                </li>
              ))}
            </Section>
          )}
          <Section title={S.search.circles} empty={!r.circles.length} none={S.search.none}>
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

function Section({ title, empty, none, children }: { title: string; empty: boolean; none: string; children: React.ReactNode }) {
  return (
    <section className="rounded-lg border bg-white p-4">
      <h2 className="mb-1 font-semibold">{title}</h2>
      {empty ? <p className="text-sm text-gray-400">{none}</p> : <ul className="divide-y text-sm">{children}</ul>}
    </section>
  );
}
