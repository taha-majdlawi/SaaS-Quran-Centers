export const STATUS_LABELS: Record<string, string> = { trial: 'تجريبي', active: 'فعّال', suspended: 'موقوف', cancelled: 'ملغى' };
export const ROLE_LABELS: Record<string, string> = { admin: 'مدير', teacher: 'معلم', guardian: 'ولي أمر', student: 'طالب' };

export const FEATURES: [string, string][] = [
  ['students', 'الطلاب'],
  ['circles', 'الحلقات'],
  ['attendance', 'الحضور'],
  ['serd', 'السرد القرآني'],
  ['points', 'النقاط'],
  ['badges', 'الشارات'],
  ['market', 'سوق النقاط'],
  ['circle-challenges', 'منافسات الحلقات'],
  ['activities', 'الأنشطة'],
  ['calendar', 'التقويم'],
  ['announcements', 'الإعلانات'],
  ['chat', 'المحادثات'],
  ['notifications', 'الإشعارات'],
  ['reports', 'التقارير'],
  ['certificates', 'الشهادات'],
  ['fees', 'رسوم الطلاب'],
  ['quran', 'المصحف'],
  ['recitations', 'التسميع المسجّل والمباشر'],
  ['wird', 'ورد اليوم وتذكيره'],
  ['garden_tree', 'الشجرة المتحركة'],
];

export const fmt = (iso: string | null | undefined) => (iso ? new Date(iso).toLocaleString('ar', { dateStyle: 'medium', timeStyle: 'short' }) : '—');

export const OK_MESSAGES: Record<string, string> = {
  saved: 'تم الحفظ', deleted: 'تم الحذف', member: 'تم تحديث العضو', invited: 'لا حساب بهذا البريد: أُنشئت دعوة (الرابط أدناه)',
  setting: 'تم تحديث الإعداد', features: 'تم حفظ مفاتيح الميزات', banned: 'أُوقف الحساب', unbanned: 'أُعيد تفعيل الحساب', password: 'عُيّنت كلمة السر الجديدة',
};
