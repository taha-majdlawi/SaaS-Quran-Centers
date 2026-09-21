'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { safeBack, withParam } from '@/lib/calendar/actions-shared';

const s = (formData: FormData, key: string) => ((formData.get(key) as string) ?? '').trim();

async function finish(back: string, error: { message: string } | null, okMessage: string): Promise<never> {
  if (error) redirect(withParam(back, 'error', error.message) as never);
  redirect(withParam(back, 'ok', okMessage) as never);
}

export async function addStudentNote(formData: FormData) {
  const back = safeBack(formData.get('back'), '/students');
  const supabase = await createClient();
  const { error } = await supabase.rpc('add_student_note', {
    p_org: s(formData, 'orgId'),
    p_student: s(formData, 'studentId'),
    p_body: s(formData, 'body'),
    p_visibility: s(formData, 'visibility') || 'staff_only',
  });
  await finish(back, error, 'أُضيفت الملاحظة');
}

export async function teacherCheckIn(formData: FormData) {
  const back = safeBack(formData.get('back'), '/dashboard');
  const supabase = await createClient();
  const { error } = await supabase.rpc('teacher_check_in', { p_org: s(formData, 'orgId'), p_circle: s(formData, 'circleId'), p_date: null });
  await finish(back, error, 'سُجّل حضورك');
}

export async function setTeacherAttendance(formData: FormData) {
  const back = safeBack(formData.get('back'), '/teachers');
  const supabase = await createClient();
  const { error } = await supabase.rpc('admin_set_teacher_attendance', {
    p_org: s(formData, 'orgId'),
    p_teacher: s(formData, 'teacherId'),
    p_circle: s(formData, 'circleId'),
    p_date: s(formData, 'date'),
    p_status: s(formData, 'status'),
    p_note: s(formData, 'note') || null,
  });
  await finish(back, error, 'حُفظ حضور المعلم');
}
