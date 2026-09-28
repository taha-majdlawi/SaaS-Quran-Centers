# (key, arabic, english) - see gen.py
SPEC = {'notif': ('Notifications.', (
  ('now', 'الآن', 'Now'),
  ('minutesAgo', 'قبل {n} دقيقة', '{n} min ago'),
  ('hoursAgo', 'قبل {n} ساعة', '{n} h ago'),
  ('today', 'اليوم', 'Today'),
  ('yesterday', 'أمس', 'Yesterday'),
  ('title', 'الإشعارات', 'Notifications'),
  ('markAll', 'تعليم الكل كمقروء', 'Mark all as read'),
  ('prefs', 'ما الذي يصلني', 'What I receive'),
  ('none', 'لا توجد إشعارات', 'No notifications'),
  ('notSaved', 'لم يُحفظ التغيير. تحقّق من الاتصال وأعد المحاولة.', 'The change wasn’t saved. Check your connection and try again.'),
  ('noPush', 'الإشعارات الفورية غير مفعّلة في هذه النسخة من التطبيق — تصلك داخل التطبيق فقط.', 'Push notifications aren’t enabled in this version of the app — you’ll see them inside the app only.'),
  ('noPermission', 'لم يُمنح التطبيق إذن الإشعارات. افتح إعدادات الهاتف ← التطبيقات ← بستان القرآن ← الإشعارات وفعّلها.', 'The app hasn’t been allowed to send notifications. Open the phone’s Settings → Apps → Bustan Al-Quran → Notifications and turn them on.'),
  ('paused', 'أوقف المركز إرسال الإشعارات مؤقتًا — تبقى القائمة داخل التطبيق تعمل.', 'The center has paused notifications for now — the in-app list still works.'),
  ('quiet', 'لا تصل إشعارات الهاتف بين {from} و{to} — تُؤجَّل إلى الصباح.', 'Phone notifications are held between {from} and {to} — they arrive in the morning.'),
  ('types', 'أنواع الإشعارات', 'Notification types'),
))}
