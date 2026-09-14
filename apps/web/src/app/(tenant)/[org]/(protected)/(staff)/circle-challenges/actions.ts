'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

export async function createChallenge(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const title = (formData.get('title') as string)?.trim();
  const metric = (formData.get('metric') as string)?.trim();
  const startsOn = formData.get('startsOn') as string;
  const endsOn = formData.get('endsOn') as string;

  const supabase = await createClient();
  const { error } = await supabase
    .from('circle_challenges')
    .insert({ organization_id: orgId, title, metric, starts_on: startsOn, ends_on: endsOn });

  if (error) {
    redirect(`/circle-challenges/new?error=${encodeURIComponent(error.message)}` as never);
  }

  redirect('/circle-challenges');
}

export async function deleteChallenge(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('circle_challenges').delete().eq('id', id);

  redirect('/circle-challenges');
}

export async function saveScores(formData: FormData) {
  const challengeId = formData.get('challengeId') as string;

  const rows: { challenge_id: string; circle_id: string; score: number }[] = [];
  for (const [key, value] of formData.entries()) {
    if (!key.startsWith('score_')) continue;
    const circleId = key.slice('score_'.length);
    rows.push({ challenge_id: challengeId, circle_id: circleId, score: Number(value || 0) });
  }

  if (rows.length) {
    const supabase = await createClient();
    const { error } = await supabase
      .from('circle_challenge_entries')
      .upsert(rows, { onConflict: 'challenge_id,circle_id' });

    if (error) {
      redirect(`/circle-challenges/${challengeId}?error=${encodeURIComponent(error.message)}` as never);
    }
  }

  redirect(`/circle-challenges/${challengeId}?saved=1` as never);
}
