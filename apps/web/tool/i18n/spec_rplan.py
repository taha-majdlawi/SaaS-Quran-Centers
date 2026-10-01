# (key, arabic, english) - see gen.py
SPEC = {'rplan': ('The daily review portion (suggested from what is memorized, approved by the teacher).', (
  ('title', 'ورد المراجعة اليومي', 'Daily review portions'),
  ('hint', 'لكل طالب صفحات المراجعة التالية من محفوظه بالترتيب، تكمل من حيث توقّف آخر ورد. اعتمدها فتظهر للطالب وولي أمره، وتُعلَّم «سمّعه» عند تسجيل مراجعة لها.', 'For each student, the next pages of what they memorised, in order, continuing from the last portion. Approve it and the student and the family see it; it is marked done when a review covering it is recorded.'),
  ('range', 'من {from} إلى {to}', 'From {from} to {to}'),
  ('pagesN', '{n} صفحات (ص {a}–{b})', '{n} pages (p. {a}–{b})'),
  ('approve', 'اعتماد', 'Approve'),
  ('approveAll', 'اعتماد كل المقترح', 'Approve all suggestions'),
  ('cancel', 'إلغاء الاعتماد', 'Withdraw'),
  ('status', {'suggested': 'مقترح', 'approved': 'معتمد', 'done': 'سمّعه ✓'}, {'suggested': 'Suggested', 'approved': 'Approved', 'done': 'Done ✓'}),
  ('none', 'لا يوجد طلاب لهم محفوظ بعد', 'No students with memorised pages yet'),
  ('cycleStart', 'بداية دورة جديدة', 'A new round starts'),
  ('today', 'ورد المراجعة اليوم', 'Today’s review'),
  ('reviewPages', 'صفحات المراجعة اليومية', 'Daily review pages'),
  ('reviewHint', 'فارغ = تلقائي (كل المحفوظ خلال 20 يوم دوام تقريبًا)', 'Empty = automatic (everything memorised in about 20 working days)'),
  ('approvedN', 'اعتُمد {n}', '{n} approved'),
))}
