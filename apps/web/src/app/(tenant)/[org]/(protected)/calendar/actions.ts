'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function createEvent(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const title = (formData.get('title') as string)?.trim();
  const description = (formData.get('description') as string)?.trim() || null;
  const startsAt = formData.get('startsAt') as string;
  const location = (formData.get('location') as string)?.trim() || null;
  const requiresConsent = formData.get('requiresConsent') === 'on';

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { error } = await supabase.from('center_calendar').insert({
    organization_id: orgId,
    title,
    description,
    starts_at: startsAt,
    location,
    requires_guardian_consent: requiresConsent,
    created_by: user?.id,
  });

  if (error) {
    redirect(`/calendar/new?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/calendar');
}

export async function updateEvent(formData: FormData) {
  const id = formData.get('id') as string;
  const title = (formData.get('title') as string)?.trim();
  const description = (formData.get('description') as string)?.trim() || null;
  const startsAt = formData.get('startsAt') as string;
  const location = (formData.get('location') as string)?.trim() || null;
  const requiresConsent = formData.get('requiresConsent') === 'on';

  const supabase = await createClient();
  const { error } = await supabase
    .from('center_calendar')
    .update({
      title,
      description,
      starts_at: startsAt,
      location,
      requires_guardian_consent: requiresConsent,
    })
    .eq('id', id);

  if (error) {
    redirect(`/calendar/${id}?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/calendar');
}

export async function deleteEvent(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('center_calendar').delete().eq('id', id);

  redirect('/calendar');
}

export async function registerStudent(formData: FormData) {
  const eventId = formData.get('eventId') as string;
  const studentId = formData.get('studentId') as string;

  const supabase = await createClient();
  const { error } = await supabase
    .from('calendar_registrations')
    .insert({ event_id: eventId, student_id: studentId, status: 'registered' });

  if (error) {
    const message = error.code === '23505' ? 'الطالب مسجّل بالفعالية من قبل' : error.message;
    redirect(`/calendar/${eventId}?error=${encodeURIComponent(message)}` as never);
  }

  redirect(`/calendar/${eventId}` as never);
}

export async function cancelRegistration(formData: FormData) {
  const id = formData.get('id') as string;
  const eventId = formData.get('eventId') as string;

  const supabase = await createClient();
  await supabase.from('calendar_registrations').delete().eq('id', id);

  redirect(`/calendar/${eventId}` as never);
}
