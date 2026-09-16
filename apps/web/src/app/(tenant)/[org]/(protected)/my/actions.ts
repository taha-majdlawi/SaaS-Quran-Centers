'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

// Mirrors apps/mobile's my_portal_repository.giveConsent/withdrawConsent -
// RLS (migration 0006's calendar_registrations_guardian_consent, 0016's
// calendar_registrations_guardian_cancel) already restricts both to a
// guardian acting on their own linked student, so there's nothing extra to
// check here beyond what the form itself supplies.
export async function giveConsent(formData: FormData) {
  const eventId = formData.get('eventId') as string;
  const studentId = formData.get('studentId') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  // consented_by records the guardian's own organization_members.id, same
  // as mobile's fetchMyMemberId - looked up here rather than trusted from
  // the form since it must match auth.uid() for the RLS check to pass.
  const { data: membership } = await supabase
    .from('organization_members')
    .select('id')
    .eq('user_id', user?.id ?? '')
    .maybeSingle();

  const { error } = await supabase.from('calendar_registrations').insert({
    event_id: eventId,
    student_id: studentId,
    status: 'registered',
    consented_by: membership?.id ?? null,
  });

  if (error) {
    redirect(`/my?error=${encodeURIComponent(error.code === '23505' ? 'تم إعطاء الموافقة من قبل' : error.message)}` as never);
  }

  redirect('/my');
}

export async function withdrawConsent(formData: FormData) {
  const registrationId = formData.get('registrationId') as string;

  const supabase = await createClient();
  await supabase.from('calendar_registrations').delete().eq('id', registrationId);

  redirect('/my');
}
