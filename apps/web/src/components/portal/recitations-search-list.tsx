'use client';

import { useMemo, useState } from 'react';
import { SURAH_NAMES } from '@/lib/quran/data';
import { TYPE_LABELS } from '@/lib/reports/format';
import { fmtDate, groupSessions, type PortalRecitation } from '@/lib/portal/format';

const chip = (on: boolean) =>
  `rounded-full border px-3 py-1 text-xs ${on ? 'border-brand bg-brand text-white' : 'bg-white text-gray-700 hover:bg-gray-50'}`;

/**
 * Search + type/grade filters over the already-fetched list (no round trip
 * per keystroke), consecutive same-session recitations grouped - the mobile
 * RecitationsSearchList (record_extras.dart).
 */
export function RecitationsSearchList({ recitations }: { recitations: PortalRecitation[] }) {
  const [query, setQuery] = useState('');
  const [type, setType] = useState<string | null>(null);
  const [grade, setGrade] = useState<string | null>(null);

  const grades = useMemo(
    () => [...new Set(recitations.map((r) => r.grade_label ?? '').filter(Boolean))].sort(),
    [recitations],
  );
  const groups = useMemo(() => {
    const q = query.trim();
    return groupSessions(
      recitations.filter((r) => {
        if (type && r.type !== type) return false;
        if (grade && r.grade_label !== grade) return false;
        if (q && !`${SURAH_NAMES[r.surah - 1] ?? ''} ${r.notes ?? ''}`.includes(q)) return false;
        return true;
      }),
    );
  }, [recitations, query, type, grade]);

  return (
    <div className="flex flex-col gap-3">
      <input
        type="search"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="بحث بالسورة أو الملاحظة"
        className="w-full rounded border px-3 py-2 text-sm"
      />
      <div className="flex flex-wrap gap-1.5">
        <button type="button" className={chip(type === null)} onClick={() => setType(null)}>
          الكل
        </button>
        {Object.entries(TYPE_LABELS).map(([key, label]) => (
          <button key={key} type="button" className={chip(type === key)} onClick={() => setType(type === key ? null : key)}>
            {label}
          </button>
        ))}
        {grades.map((g) => (
          <button key={g} type="button" className={chip(grade === g)} onClick={() => setGrade(grade === g ? null : g)}>
            {g}
          </button>
        ))}
      </div>
      {groups.length === 0 ? (
        <p className="p-3 text-sm text-gray-400">لا يوجد نتائج</p>
      ) : (
        <ul className="flex flex-col gap-2 text-sm">
          {groups.map((g) => (g.length === 1 ? <RecitationItem key={g[0].id} r={g[0]} /> : <SessionGroup key={g[0].id} items={g} />))}
        </ul>
      )}
    </div>
  );
}

export function RecitationItem({ r }: { r: PortalRecitation }) {
  return (
    <li className="rounded bg-gray-50 px-3 py-2">
      <div className="flex justify-between">
        <span className="font-semibold">
          {SURAH_NAMES[r.surah - 1]} ({r.ayah_from}–{r.ayah_to})
        </span>
        <span className="text-brand">+{r.points_awarded}</span>
      </div>
      <p className="text-xs text-gray-500">
        {TYPE_LABELS[r.type] ?? r.type} · {r.grade_label ?? '—'} · {fmtDate(r.created_at)}
      </p>
      {r.notes && <p className="mt-1 text-xs text-gray-600">{r.notes}</p>}
    </li>
  );
}

function SessionGroup({ items }: { items: PortalRecitation[] }) {
  const total = items.reduce((sum, r) => sum + r.points_awarded, 0);
  return (
    <li>
      <details className="rounded border bg-white">
        <summary className="flex cursor-pointer items-center justify-between gap-2 px-3 py-2">
          <span>
            <span className="font-semibold">{items.length} تسميعات في جلسة واحدة</span>
            <span className="block text-xs text-gray-500">
              {fmtDate(items[0].created_at)} · {TYPE_LABELS[items[0].type] ?? items[0].type}
            </span>
          </span>
          <span className="text-brand">+{total}</span>
        </summary>
        <ul className="flex flex-col gap-2 px-2 pb-2">
          {items.map((r) => (
            <RecitationItem key={r.id} r={r} />
          ))}
        </ul>
      </details>
    </li>
  );
}
