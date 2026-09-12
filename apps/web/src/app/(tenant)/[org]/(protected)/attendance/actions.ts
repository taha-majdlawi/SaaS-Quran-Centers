'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

const VALID_STATUSES = new Set(['present', 'absent', 'excused', 'late']);

export async function saveAttendance(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const circleId = formData.get('circleId') as string;
  const sessionDate = formData.get('sessionDate') as string;

  const rows: { organization_id: string; student_id: string; circle_id: string; session_date: string; status: string }[] =
    [];

  for (const [key, value] of formData.entries()) {
    if (!key.startsWith('status_')) continue;
    const studentId = key.slice('status_'.length);
    const status = String(value);
    if (!VALID_STATUSES.has(status)) continue;
    rows.push({
      organization_id: orgId,
      student_id: studentId,
      circle_id: circleId,
      session_date: sessionDate,
      status,
    });
  }

  if (rows.length) {
    const supabase = await createClient();
    const { error } = await supabase
      .from('attendance')
      .upsert(rows, { onConflict: 'student_id,session_date' });

    if (error) {
      redirect(
        `/attendance?circleId=${circleId}&date=${sessionDate}&error=${encodeURIComponent(error.message)}` as never,
      );
    }
  }

  redirect(`/attendance?circleId=${circleId}&date=${sessionDate}&saved=1` as never);
}
