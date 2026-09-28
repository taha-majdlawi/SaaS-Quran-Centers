# (key, arabic, english) - see gen.py
SPEC = {'deletion': ('Data deletion requests.', (
  ('intro', 'طلب من عضو أو أسرة. «موافقة» تعني أنك ستحذف الحساب والبيانات (من صفحة الطالب أو الأعضاء)، ثم اضغط «اكتمل» ليصله إشعار.', 'A request from a member or family. “Approve” means you will delete the account and data (from the student or members page); then press “Deletion done” so they are notified.'),
  ('heading', 'طلبات حذف البيانات', 'Data deletion requests'),
  ('updated', 'تم تحديث الطلب', 'Request updated'),
  ('empty', 'لا طلبات', 'No requests'),
  ('status', {'pending': 'قيد المراجعة', 'approved': 'موافَق عليه', 'rejected': 'مرفوض', 'completed': 'اكتمل'}, {'pending': 'Under review', 'approved': 'Approved', 'rejected': 'Rejected', 'completed': 'Completed'}),
  ('student', 'الطالب:', 'Student:'),
  ('approve', 'موافقة', 'Approve'),
  ('reject', 'رفض', 'Reject'),
  ('done', 'اكتمل الحذف', 'Deletion done'),
))}
