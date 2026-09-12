'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

function readStudentFields(formData: FormData) {
  return {
    full_name: (formData.get('fullName') as string)?.trim(),
    student_code: (formData.get('studentCode') as string)?.trim(),
    circle_id: (formData.get('circleId') as string) || null,
    birth_date: (formData.get('birthDate') as string) || null,
  };
}

export async function createStudent(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const fields = readStudentFields(formData);

  const supabase = await createClient();
  const { error } = await supabase.from('students_profile').insert({ organization_id: orgId, ...fields });

  if (error) {
    const message = error.code === '23505' ? 'رقم الطالب مستخدم من قبل بهذا المركز' : error.message;
    redirect(`/students/new?error=${encodeURIComponent(message)}` as never);
  }

  redirect('/students');
}

export async function updateStudent(formData: FormData) {
  const id = formData.get('id') as string;
  const status = formData.get('status') as string;
  const fields = readStudentFields(formData);

  const supabase = await createClient();
  const { error } = await supabase
    .from('students_profile')
    .update({ ...fields, status })
    .eq('id', id);

  if (error) {
    const message = error.code === '23505' ? 'رقم الطالب مستخدم من قبل بهذا المركز' : error.message;
    redirect(`/students/${id}?error=${encodeURIComponent(message)}` as never);
  }

  redirect('/students');
}

export async function deleteStudent(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  await supabase.from('students_profile').delete().eq('id', id);

  redirect('/students');
}
