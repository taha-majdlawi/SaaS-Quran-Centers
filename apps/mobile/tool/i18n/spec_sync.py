# (key, arabic, english) - see gen.py
SPEC = {'sync': ('Offline uploads.', (
  ('title', 'المزامنة', 'Sync'),
  ('allUp', 'كل شيء مرفوع', 'Everything is uploaded'),
  ('lastSync', 'آخر رفع ناجح: {time}', 'Last successful upload: {time}'),
  ('cached', 'تُعرض بيانات محفوظة سابقًا لأن الاتصال غير متاح', 'Showing saved data because there’s no connection'),
  ('uploadNow', 'ارفع الآن', 'Upload now'),
  ('nothing', 'لا يوجد شيء في الانتظار', 'Nothing waiting'),
  ('rejected', 'رُفض من الخادم: {error}', 'Rejected by the server: {error}'),
  ('discardTitle', 'حذف من الانتظار؟', 'Remove from the queue?'),
  ('discardBody', 'لن يُرفع هذا السجل أبدًا.', 'This record will never be uploaded.'),
  ('retry', 'أعد المحاولة', 'Try again'),
  ('stripFailed', 'بعض السجلات رُفضت ({n}) — اضغط للمراجعة', 'Some records were rejected ({n}) — tap to review'),
  ('counts', 'بانتظار الرفع: {waiting} · تحتاج مراجعة: {failed}', 'Waiting: {waiting} · need review: {failed}'),
  ('nothingHint', 'ما تسجّله دون اتصال يظهر هنا حتى يُرفع.', 'What you record offline shows here until it’s uploaded.'),
  ('queued', 'سُجّل {time} · محاولات: {n}', 'Recorded {time} · attempts: {n}'),
  ('stripWaiting', 'بانتظار الرفع: {n} — يُرفع تلقائيًا عند عودة الاتصال', 'Waiting to upload: {n} — goes up automatically when back online'),
  ('stripOffline', 'لا يوجد اتصال — تُعرض بيانات محفوظة', 'No connection — showing saved data'),
))}
