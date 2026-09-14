'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { logAudit } from '@/lib/audit/log';

export async function createSerdSession(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const studentId = formData.get('studentId') as string;
  const circleId = (formData.get('circleId') as string) || null;
  const sessionType = formData.get('sessionType') as string;
  const scheduledAt = (formData.get('scheduledAt') as string) || null;

  const supabase = await createClient();
  const { error } = await supabase.from('serd_sessions').insert({
    organization_id: orgId,
    student_id: studentId,
    circle_id: circleId,
    session_type: sessionType,
    scheduled_at: scheduledAt,
    status: scheduledAt ? 'scheduled' : 'pending',
  });

  if (error) {
    redirect(`/serd/new?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/serd');
}

export async function updateSerdSession(formData: FormData) {
  const id = formData.get('id') as string;
  const status = formData.get('status') as string;
  const examinerUserId = formData.get('examinerId') as string;
  const scheduledAt = (formData.get('scheduledAt') as string) || null;
  const overallGrade = formData.get('overallGrade') as string;
  const notes = (formData.get('notes') as string)?.trim() || null;

  const supabase = await createClient();
  const { error } = await supabase
    .from('serd_sessions')
    .update({
      status,
      examiner_id: examinerUserId || null,
      scheduled_at: scheduledAt,
      overall_grade: overallGrade ? Number(overallGrade) : null,
      notes,
    })
    .eq('id', id);

  if (error) {
    redirect(`/serd/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/serd');
}

export async function deleteSerdSession(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data: session } = await supabase
    .from('serd_sessions')
    .select('organization_id')
    .eq('id', id)
    .maybeSingle();

  await supabase.from('serd_sessions').delete().eq('id', id);

  if (session && user) {
    await logAudit(supabase, {
      organizationId: session.organization_id,
      actorId: user.id,
      action: 'delete',
      entityTable: 'serd_sessions',
      entityId: id,
    });
  }

  redirect('/serd');
}
