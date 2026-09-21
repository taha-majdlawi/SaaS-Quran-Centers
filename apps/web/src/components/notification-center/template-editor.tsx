'use client';

import { useRef, useState } from 'react';
import { saveTemplate, resetTemplate } from '@/lib/notifications/actions';
import { AUDIENCE_LABELS, ROLE_LABELS, renderTemplate } from '@/lib/notifications/catalog';

export interface TemplateRow {
  event_key: string;
  name: string;
  roles: string[];
  available_vars: string[];
  title_template: string;
  body_template: string;
  default_title: string;
  default_body: string;
  has_lead: boolean;
  lead_hours: number | null;
  audience: string;
  is_enabled: boolean;
  customized: boolean;
  updated_at: string | null;
  updated_by_name: string | null;
  sent_count: number;
}

/** One notification type: wording with variables, audience, lead time, on/off, and a live preview. */
export function TemplateEditor({ orgId, t }: { orgId: string; t: TemplateRow }) {
  const [title, setTitle] = useState(t.title_template);
  const [body, setBody] = useState(t.body_template);
  const [enabled, setEnabled] = useState(t.is_enabled);
  const last = useRef<'title' | 'body'>('body');

  const insert = (v: string) => {
    const chip = `{${v}}`;
    if (last.current === 'title') setTitle((x) => `${x}${chip}`);
    else setBody((x) => `${x}${chip}`);
  };

  return (
    <details className="rounded-lg border bg-white open:shadow-sm">
      <summary className="flex cursor-pointer flex-wrap items-center justify-between gap-2 px-4 py-3">
        <span className="flex items-center gap-2">
          <b>{t.name}</b>
          {t.customized && <span className="rounded bg-brand/10 px-1.5 py-0.5 text-[11px] text-brand">مخصّص</span>}
          {!enabled && <span className="rounded bg-gray-100 px-1.5 py-0.5 text-[11px] text-gray-500">متوقف</span>}
        </span>
        <span className="text-xs text-gray-400">
          {t.roles.map((r) => ROLE_LABELS[r] ?? r).join(' · ')} · أُرسل {t.sent_count}
        </span>
      </summary>

      <form action={saveTemplate} className="flex flex-col gap-3 border-t px-4 py-4">
        <input type="hidden" name="orgId" value={orgId} />
        <input type="hidden" name="event" value={t.event_key} />

        <label className="text-sm">
          <span className="font-medium text-gray-700">العنوان (السطر الذي يظهر على الشاشة المقفلة)</span>
          <input name="title" value={title} onChange={(e) => setTitle(e.target.value)} onFocus={() => (last.current = 'title')} maxLength={120} required className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>
        <label className="text-sm">
          <span className="font-medium text-gray-700">النص</span>
          <textarea name="body" value={body} onChange={(e) => setBody(e.target.value)} onFocus={() => (last.current = 'body')} maxLength={300} required rows={2} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
        </label>

        <div className="flex flex-wrap items-center gap-1.5 text-xs">
          <span className="text-gray-500">المتغيرات (اضغط للإدراج):</span>
          {t.available_vars.map((v) => (
            <button key={v} type="button" onClick={() => insert(v)} className="rounded-full border bg-gray-50 px-2 py-0.5 hover:bg-brand/10">
              {`{${v}}`}
            </button>
          ))}
        </div>

        <div className="grid gap-3 sm:grid-cols-3">
          <label className="text-sm">
            <span className="font-medium text-gray-700">الجمهور</span>
            <select name="audience" defaultValue={t.audience} className="mt-1 w-full rounded border px-2 py-2 text-sm">
              {Object.entries(AUDIENCE_LABELS).map(([k, v]) => (
                <option key={k} value={k}>
                  {v}
                </option>
              ))}
            </select>
          </label>
          {t.has_lead && (
            <label className="text-sm">
              <span className="font-medium text-gray-700">قبل الموعد بـ (ساعات، 0 = إيقاف)</span>
              <input name="lead" type="number" min={0} max={336} defaultValue={t.lead_hours ?? 24} className="mt-1 w-full rounded border px-3 py-2 text-sm" />
            </label>
          )}
          <label className="flex items-center gap-2 pt-6 text-sm">
            <input type="checkbox" name="enabled" checked={enabled} onChange={(e) => setEnabled(e.target.checked)} />
            مفعّل
          </label>
        </div>

        <div className="rounded-lg bg-gray-50 p-3 text-sm">
          <p className="mb-1 text-xs text-gray-400">معاينة على الهاتف (بقيم تجريبية)</p>
          <p className="font-semibold">{renderTemplate(title) || '—'}</p>
          <p className="text-gray-600">{renderTemplate(body) || '—'}</p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <button className="rounded bg-brand px-4 py-2 text-sm text-white">حفظ</button>
          {t.customized && (
            <button formAction={resetTemplate} formNoValidate className="rounded border px-3 py-2 text-sm text-gray-600 hover:bg-gray-50">
              استعادة الصياغة الافتراضية
            </button>
          )}
          {t.updated_at && (
            <span className="text-xs text-gray-400">
              آخر تعديل {new Date(t.updated_at).toLocaleDateString('ar')}
              {t.updated_by_name ? ` · ${t.updated_by_name}` : ''}
            </span>
          )}
        </div>
      </form>
    </details>
  );
}
