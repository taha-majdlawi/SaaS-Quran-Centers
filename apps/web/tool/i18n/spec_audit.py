# (key, arabic, english) - see gen.py
SPEC = {'audit': ('The activity log.', (
  ('tables', {'students_profile': 'طالب', 'circles': 'حلقة', 'stages': 'مرحلة', 'serd_sessions': 'جلسة سرد', 'organization_members': 'عضو', 'billing_requests': 'دفعة', 'organizations': 'المركز'}, {'students_profile': 'Student', 'circles': 'Circle', 'stages': 'Stage', 'serd_sessions': 'Serd session', 'organization_members': 'Member', 'billing_requests': 'Payment', 'organizations': 'The center'}),
  ('actions', {'delete': 'حذف', 'update': 'تعديل', 'create': 'إضافة', 'insert': 'إضافة'}, {'delete': 'Deleted', 'update': 'Changed', 'create': 'Added', 'insert': 'Added'}),
  ('intro', 'آخر 100 عملية حذف/تعديل حساسة بالمركز.', 'The last 100 sensitive deletions / changes at the center.'),
  ('none', 'لا يوجد عمليات مسجّلة بعد', 'Nothing logged yet'),
  ('colWho', 'من قام بالعملية', 'By'),
  ('title', 'سجل العمليات', 'Activity log'),
  ('colDate', 'التاريخ', 'Date'),
  ('colAction', 'العملية', 'Action'),
  ('colOn', 'على', 'On'),
))}
