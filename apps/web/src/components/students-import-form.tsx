'use client';

import { useActionState } from 'react';
import { importStudents, type ImportState } from '@/app/(tenant)/[org]/(protected)/(staff)/students/import/actions';
import { fmt } from '@/lib/i18n/config';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

export function StudentsImportForm({ orgId, labels }: { orgId: string; labels: Dictionary['staff']['studentsImport'] }) {
  const L = { studentsImport: labels };
  const [state, action, pending] = useActionState<ImportState | null, FormData>(importStudents, null);
  return (
    <form action={action} className="flex max-w-2xl flex-col gap-3 rounded-lg border bg-white p-6">
      <input type="hidden" name="orgId" value={orgId} />
      <label className="text-sm font-medium text-gray-700">
        {L.studentsImport.file}
        <input type="file" name="file" accept=".csv,text/csv,text/plain" className="mt-1 block w-full text-sm" />
      </label>
      <label className="text-sm font-medium text-gray-700">
        {L.studentsImport.paste}
        <textarea name="csv" rows={6} dir="ltr" placeholder={'name,circle,birth_date,phone\nأحمد علي,حلقة النور,2014-03-05,0790000000'} className="mt-1 w-full rounded border px-3 py-2 font-mono text-xs" />
      </label>
      <button disabled={pending} className="self-start rounded bg-brand px-5 py-2 text-sm font-semibold text-white disabled:opacity-50">
        {pending ? L.studentsImport.importing : L.studentsImport.submit}
      </button>
      {state && (
        <div className="text-sm">
          <p className={state.created ? 'text-green-700' : 'text-gray-600'}>{fmt(L.studentsImport.added, { n: state.created })}</p>
          {state.errors.length > 0 && (
            <ul className="mt-2 list-disc ps-5 text-xs text-red-600">
              {state.errors.map((e, i) => (
                <li key={i}>{e}</li>
              ))}
            </ul>
          )}
        </div>
      )}
    </form>
  );
}
