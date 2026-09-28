# (key, arabic, english) - see gen.py
SPEC = {'attendance': ('Taking attendance.', (
  ('status', {'present': 'حاضر', 'absent': 'غائب', 'excused': 'مستأذن', 'late': 'متأخر'}, {'present': 'Present', 'absent': 'Absent', 'excused': 'Excused', 'late': 'Late'}),
  ('noStudents', 'لا يوجد طلاب بهذي الحلقة', 'No students in this circle'),
  ('saved', 'تم حفظ الحضور بنجاح', 'Attendance saved'),
  ('pickCircle', 'اختر الحلقة', 'Choose a circle'),
  ('save', 'حفظ الحضور', 'Save attendance'),
  ('date', 'التاريخ', 'Date'),
  ('title', 'الحضور', 'Attendance'),
  ('circle', 'الحلقة', 'Circle'),
  ('colStatus', 'الحالة', 'Status'),
  ('colCode', 'الرقم', 'Number'),
  ('colName', 'الاسم', 'Name'),
  ('show', 'عرض', 'Show'),
))}
