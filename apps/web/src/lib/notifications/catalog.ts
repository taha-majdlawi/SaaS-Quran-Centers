/** Shared bits of the notification centre: role names, screens a message can open, sample values for the live preview. */

export const ROLE_LABELS: Record<string, string> = { admin: 'مشرف', teacher: 'معلم', guardian: 'ولي أمر', student: 'طالب' };

export const AUDIENCE_LABELS: Record<string, string> = {
  source: 'كما هو (الجمهور الافتراضي للحدث)',
  admins: 'المشرفون فقط',
  teachers: 'المعلمون فقط',
  students: 'الطلاب فقط',
  guardians: 'أولياء الأمور فقط',
};

/** Screens an immediate message can open when tapped (keys are shared with the mobile app). */
export const DEEP_LINKS: Record<string, string> = {
  announcements: 'الإعلانات',
  calendar: 'التقويم',
  market: 'السوق',
  chat: 'المحادثات',
  badges: 'الشارات',
};

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

export const PUSH_STATUS: Record<string, { label: string; cls: string }> = {
  sent: { label: 'وصل', cls: 'bg-green-100 text-green-700' },
  pending: { label: 'في الطابور', cls: 'bg-blue-100 text-blue-700' },
  queued: { label: 'بانتظار انتهاء الصمت', cls: 'bg-blue-100 text-blue-700' },
  failed: { label: 'فشل', cls: 'bg-red-100 text-red-700' },
  no_device: { label: 'بلا هاتف', cls: 'bg-gray-100 text-gray-600' },
  skipped: { label: 'لم يُرسل', cls: 'bg-amber-100 text-amber-800' },
};
