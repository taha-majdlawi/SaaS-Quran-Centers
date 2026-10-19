'use server';

import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { deleteErrorMessage } from '@/lib/db-errors';
import { logAudit } from '@/lib/audit/log';
import { createAdminClient } from '@/lib/supabase/admin';
import { AccountError, provisionStudent } from '@/lib/accounts/provision';
import { staffStrings } from '@/lib/i18n/server';
import { nationalIdField } from '@/lib/auth/national-id';

function readStudentFields(formData: FormData) {
  return {
    full_name: (formData.get('fullName') as string)?.trim(),
    student_code: (formData.get('studentCode') as string)?.trim(),
    circle_id: (formData.get('circleId') as string) || null,
    birth_date: (formData.get('birthDate') as string) || null,
    // only when the form has the field (0095); undefined = what was typed is not an ID
    ...(formData.has('nationalId') ? { national_id: nationalIdField(formData.get('nationalId')) } : {}),
  };
}

/** A unique clash: the national ID (0095) or, otherwise, the student number. */
async function clashMessage(error: { code?: string; message: string }) {
  const S = (await staffStrings()).students;
  if (error.code !== '23505') return error.message;
  return /national/i.test(error.message) ? S.nationalIdTaken : S.codeTaken;
}

export async function createStudent(formData: FormData) {
  const orgId = formData.get('orgId') as string;
  const fields = readStudentFields(formData);
  const password = ((formData.get('password') as string) ?? '').trim();
  const contact = {
    phone: (formData.get('phone') as string)?.trim() || null,
    whatsapp: (formData.get('whatsapp') as string)?.trim() || null,
    address: (formData.get('address') as string)?.trim() || null,
  };

  if (!fields.circle_id) {
    redirect(`/students/new?error=${encodeURIComponent((await staffStrings()).students.needCircle)}` as never);
  }
  if (fields.national_id === undefined && 'national_id' in fields) {
    redirect(`/students/new?error=${encodeURIComponent((await staffStrings()).students.nationalIdInvalid)}` as never);
  }

  const supabase = await createClient();

  // With a password the student gets a working login in the same step
  // (eqraa always does this); without one only the record is created.
  if (password) {
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) redirect('/login' as never);
    try {
      const created = await provisionStudent(createAdminClient(), user.id, {
        orgId,
        fullName: fields.full_name,
        studentCode: fields.student_code,
        circleId: fields.circle_id!,
        password,
        email: (formData.get('email') as string) || null,
        birthDate: fields.birth_date,
        nationalId: fields.national_id ?? null,
        ...contact,
      });
      redirect(
        `/students?createdId=${encodeURIComponent(created.loginId)}&createdPassword=${encodeURIComponent(password)}` as never,
      );
    } catch (e) {
      if (!(e instanceof AccountError)) throw e;
      redirect(`/students/new?error=${encodeURIComponent(e.message)}` as never);
    }
  }

  const { error } = await supabase.from('students_profile').insert({ organization_id: orgId, ...fields, ...contact });

  if (error) redirect(`/students/new?error=${encodeURIComponent(await clashMessage(error))}` as never);

  redirect('/students');
}

export async function updateStudent(formData: FormData) {
  const id = formData.get('id') as string;
  const status = formData.get('status') as string;
  const fields = readStudentFields(formData);

  if (!fields.circle_id) {
    redirect(`/students/${id}/edit?error=${encodeURIComponent((await staffStrings()).students.needCircle)}` as never);
  }
  if (fields.national_id === undefined && 'national_id' in fields) {
    redirect(`/students/${id}/edit?error=${encodeURIComponent((await staffStrings()).students.nationalIdInvalid)}` as never);
  }

  // Contact fields are only touched when the form actually carries them.
  const contact: Record<string, string | null> = {};
  for (const key of ['phone', 'whatsapp', 'address'] as const) {
    if (formData.has(key)) contact[key] = (formData.get(key) as string)?.trim() || null;
  }

  const supabase = await createClient();
  const { error } = await supabase
    .from('students_profile')
    .update({ ...fields, ...contact, status })
    .eq('id', id);

  if (error) redirect(`/students/${id}/edit?error=${encodeURIComponent(await clashMessage(error))}` as never);

  redirect(`/students/${id}` as never);
}

export async function deleteStudent(formData: FormData) {
  const id = formData.get('id') as string;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  const { data: student } = await supabase
    .from('students_profile')
    .select('organization_id')
    .eq('id', id)
    .maybeSingle();

  const { data: removed, error: delError } = await supabase.from('students_profile').delete().eq('id', id).select('id');
  if (delError || !removed?.length) redirect(`/students/${id}/edit?error=${encodeURIComponent(await deleteErrorMessage(delError))}` as never);

  if (student && user) {
    await logAudit(supabase, {
      organizationId: student.organization_id,
      actorId: user.id,
      action: 'delete',
      entityTable: 'students_profile',
      entityId: id,
    });
  }

  redirect('/students');
}
