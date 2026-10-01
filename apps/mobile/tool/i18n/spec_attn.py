# (key, arabic, english) - see gen.py
SPEC = {'attn': ('Students needing attention.', (
  ('title', 'طلاب يحتاجون اهتمام', 'Students needing attention'),
  ('hint', 'مرتّبون من الأكثر حاجة: المتأخر عن هدفه، المنقطع عن التسميع، وكثير الغياب.', 'Most urgent first: behind their goal, not reciting, often absent.'),
  ('none', 'لا أحد يحتاج اهتمامًا خاصًا الآن 🌿', 'Nobody needs special attention right now 🌿'),
  ('behind', 'متأخر عن هدفه {pages} صفحة', 'Behind their goal by {pages} pages'),
  ('idle', 'لم يسمّع منذ {days} أيام دوام', 'Has not recited for {days} working days'),
  ('never', 'لم يسمّع أبدًا', 'Has never recited'),
  ('absences', 'غاب {count} مرات في أسبوعين', 'Absent {count} times in two weeks'),
  ('all', 'الكل', 'All'),
  ('filterBehind', 'متأخر عن الهدف', 'Behind goal'),
  ('filterIdle', 'منقطع', 'Not reciting'),
  ('filterAbsent', 'غياب', 'Absences'),
  ('recite', 'تسميع', 'Recite'),
  ('call', 'اتصال', 'Call'),
  ('lastRecited', 'آخر تسميع: {v}', 'Last recitation: {v}'),
  ('count', '{n} طالب', '{n} students'),
))}
