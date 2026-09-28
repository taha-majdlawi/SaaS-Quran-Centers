# (key, arabic, english) - see gen.py
SPEC = {'plan': ('Subscription / plan-capacity strips for staff.', (
  ('graceTrial', '🍂 انتهت الفترة التجريبية — بستانكم ينتظر السقاية: جدّدوا من لوحة التحكم على الويب', '🍂 The trial has ended — your garden is waiting to be watered: renew from the web dashboard'),
  ('gracePaid', '🍂 انتهى اشتراك المركز — بستانكم ينتظر السقاية: جدّدوا من لوحة التحكم على الويب', '🍂 The center’s subscription has ended — your garden is waiting to be watered: renew from the web dashboard'),
  ('soonTrial', '🌿 تنتهي الفترة التجريبية خلال {days}', '🌿 The trial ends in {days}'),
  ('soonPaid', '🌿 ينتهي اشتراك المركز خلال {days}', '🌿 The center’s subscription ends in {days}'),
  ('days', {'one': 'يوم واحد', 'two': 'يومين', 'many': '{n} أيام'}, {'one': '1 day', 'two': '2 days', 'many': '{n} days'}),
  ('students', {'one': 'طالب واحد', 'two': 'طالبان', 'many': '{n} طلاب'}, {'one': '1 student', 'two': '2 students', 'many': '{n} students'}),
  ('studentsFull', '🌳 امتلأ البستان: وصل المركز للحد الأقصى من الطلاب ({max})', '🌳 The garden is full: the center has reached its student limit ({max})'),
  ('studentsLeft', '🌿 تبقى {n} يمكن إضافتهم ضمن الخطة', '🌿 {n} more can be added on the plan'),
  ('teachersFull', '🌳 وصل المركز للحد الأقصى من المعلمين ({max})', '🌳 The center has reached its teacher limit ({max})'),
  ('oneTeacherLeft', '🌿 تبقى إضافة معلم واحد فقط ضمن الخطة', '🌿 Only one more teacher can be added on the plan'),
))}
