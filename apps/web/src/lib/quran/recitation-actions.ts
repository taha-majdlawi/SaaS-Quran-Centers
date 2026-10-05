'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

/** The teacher's decision on a recorded recitation; approving writes it into the student's record (review_recitation, 0085). */
export async function reviewRecitation(formData: FormData) {
  const id = formData.get('id') as string;
  const approve = formData.get('decision') === 'approve';
  const supabase = await createClient();
  const { error } = await supabase.rpc('review_recitation', {
    p_id: id,
    p_approve: approve,
    p_grade: approve ? ((formData.get('grade') as string) || null) : null,
    p_type: approve ? ((formData.get('type') as string) || null) : null,
    p_note: ((formData.get('note') as string) ?? '').trim() || null,
  });
  if (error) redirect(`/recitations?error=${encodeURIComponent(error.message)}` as never);
  redirect(`/recitations?done=${approve ? 'approved' : 'rejected'}` as never);
}
