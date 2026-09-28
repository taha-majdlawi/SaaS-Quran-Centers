/** Shared bits of the notification centre: sample values for the live preview, status colours (the wording is in the staff dictionary). */

export const SAMPLE_VARS: Record<string, string> = {
  اسم_الطالب: 'أحمد محمد',
  العنوان: 'رحلة المركز',
  الوصف: 'نص الإعلان كما سيصل',
  التاريخ: 'غدًا',
  الوقت: 'الساعة 09:00',
  الموقع: 'مسجد النصيرات',
  الدرجة: '95%',
  السبب: 'الجزء غير مطابق للمرحلة',
  المنتج: 'حقيبة المركز',
  الشارة: 'حافظ المثابرة',
  الملخص: 'سمّع 4 مرات · +18 نقطة · حضر 4 من 5 أيام',
  الحلقة: 'حلقة البراعم',
  الأيام: '3',
};

/** Same substitution rules as the database (`notification_render`), so the preview matches what is delivered. */
export function renderTemplate(template: string, vars: Record<string, string> = SAMPLE_VARS): string {
  let out = template;
  for (const [k, v] of Object.entries(vars)) out = out.split(`{${k}}`).join(v);
  out = out
    .replace(/\{[^{}]*\}/g, '')
    .replace(/\s+/g, ' ')
    .replace(/\s*[—·]\s*(?:[—·]\s*)+/g, ' — ');
  return out.replace(/^[\s—·،-]+|[\s—·،-]+$/g, '');
}

export const PUSH_STYLES: Record<string, string> = {
  sent: 'bg-green-100 text-green-700',
  pending: 'bg-blue-100 text-blue-700',
  queued: 'bg-blue-100 text-blue-700',
  failed: 'bg-red-100 text-red-700',
  no_device: 'bg-gray-100 text-gray-600',
  skipped: 'bg-amber-100 text-amber-800',
};
