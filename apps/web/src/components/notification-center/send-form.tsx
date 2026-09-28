'use client';

import { useState } from 'react';
import { sendBroadcast } from '@/lib/notifications/actions';
import { renderTemplate } from '@/lib/notifications/catalog';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

interface Person {
  user_id: string;
  name: string | null;
  role: string;
}

/** Immediate message: an audience (or hand-picked people), a title and text, and where a tap leads. */
export function SendForm({ orgId, circles, people, labels }: { orgId: string; circles: { id: string; name: string }[]; people: Person[]; labels: Dictionary['staff']['notif'] }) {
  const S = { notif: labels };
  const [audience, setAudience] = useState('all');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [q, setQ] = useState('');
  const shown = people.filter((p) => !q || (p.name ?? '').includes(q));

  return (
    <form action={sendBroadcast} className="flex max-w-2xl flex-col gap-3 rounded-lg border bg-white p-5">
      <input type="hidden" name="orgId" value={orgId} />
      <label className="text-sm">
        <span className="font-medium text-gray-700">{S.notif.to}</span>
        <select name="audience" value={audience} onChange={(e) => setAudience(e.target.value)} className="mt-1 w-full rounded border px-2 py-2 text-sm">
          <option value="all">{S.notif.everyone}</option>
          <option value="teachers">{S.notif.teachers}</option>
          <option value="students">{S.notif.students}</option>
          <option value="guardians">{S.notif.guardians}</option>
          <option value="admins">{S.notif.admins}</option>
          <option value="__people__">{S.notif.people}</option>
        </select>
      </label>

      {audience !== '__people__' && audience !== 'admins' && (
        <label className="text-sm">
          <span className="font-medium text-gray-700">{S.notif.circle}</span>
          <select name="circle" defaultValue="" className="mt-1 w-full rounded border px-2 py-2 text-sm">
            <option value="">{S.notif.allCircles}</option>
            {circles.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
        </label>
      )}

      {audience === '__people__' && (
        <div className="text-sm">
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={S.notif.searchName} className="mb-2 w-full rounded border px-3 py-2 text-sm" />
          <div className="max-h-56 divide-y overflow-auto rounded border">
            {shown.map((p) => (
              <label key={p.user_id} className="flex items-center gap-2 px-3 py-1.5">
                <input type="checkbox" name="user" value={p.user_id} />
                {p.name ?? '—'} <span className="text-xs text-gray-400">({S.notif.roles[p.role] ?? p.role})</span>
              </label>
            ))}
            {!shown.length && <p className="px-3 py-3 text-center text-gray-400">{S.notif.noResults}</p>}
          </div>
        </div>
      )}

      <label className="text-sm">
        <span className="font-medium text-gray-700">{S.notif.title}</span>
        <input name="title" value={title} onChange={(e) => setTitle(e.target.value)} maxLength={120} required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
      </label>
      <label className="text-sm">
        <span className="font-medium text-gray-700">{S.notif.body}</span>
        <textarea name="body" value={body} onChange={(e) => setBody(e.target.value)} maxLength={400} required rows={3} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
      </label>
      <label className="text-sm">
        <span className="font-medium text-gray-700">{S.notif.opens}</span>
        <select name="deep_link" defaultValue="" className="mt-1 w-full rounded border px-2 py-2 text-sm">
          <option value="">{S.notif.notifList}</option>
          {Object.entries(S.notif.deepLinks).map(([k, v]) => (
            <option key={k} value={k}>
              {v}
            </option>
          ))}
        </select>
      </label>

      <div className="rounded-lg bg-gray-50 p-3 text-sm">
        <p className="mb-1 text-xs text-gray-400">{S.notif.preview}</p>
        <p className="font-semibold">{renderTemplate(title) || S.notif.titlePh}</p>
        <p className="text-gray-600">{renderTemplate(body) || S.notif.bodyPh}</p>
      </div>

      <div className="flex flex-wrap gap-2">
        <button className="rounded bg-brand px-4 py-2 text-sm text-white">{S.notif.sendNow}</button>
        <button name="mode" value="self" className="rounded border px-3 py-2 text-sm text-brand hover:bg-gray-50">
          {S.notif.sendSelf}
        </button>
      </div>
    </form>
  );
}
