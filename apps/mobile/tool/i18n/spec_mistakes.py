# (key, arabic, english) - see gen.py
SPEC = {'mistakes': ('Recurring mistakes (recitation_mistake_stats).', (
  ('title', 'مواضع الأخطاء المتكررة', 'Recurring mistakes'),
  ('hint', 'من اختبارات المعلم في المصحف والفحص الآلي للتسميعات المسجّلة، في آخر {days} يومًا. ركّز عليها في المراجعة.', 'From the teacher\'s tests in the mushaf and the automatic checks of recorded recitations, over the last {days} days. Focus on them when reviewing.'),
  ('summary', '{sessions} تسميع · {mistakes} خطأ', '{sessions} recitations · {mistakes} mistakes'),
  ('bySurah', 'حسب السورة', 'By surah'),
  ('byAyah', 'الآيات الأكثر خطأ', 'Ayahs with the most mistakes'),
  ('byWord', 'الكلمات الأكثر خطأ', 'Words with the most mistakes'),
  ('times', '×{n}', '×{n}'),
  ('none', 'لا توجد أخطاء مسجّلة في هذه الفترة.', 'No mistakes recorded in this period.'),
  ('ayah', '{surah} : {ayah}', '{surah} : {ayah}'),
)),}
