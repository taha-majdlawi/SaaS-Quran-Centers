import type { SupabaseClient } from '@supabase/supabase-js';
import { toLoginEmail } from './login-id';
import { staffStrings } from '@/lib/i18n/server';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';

type AccountStrings = Dictionary['staff']['accounts'];

/** Error whose message is safe (and written) to show the user. */
export class AccountError extends Error {}

interface CallerMembership {
  role: 'admin' | 'teacher' | 'student' | 'guardian';
  permissions: string[] | null;
}

async function membershipOf(admin: SupabaseClient, userId: string, orgId: string): Promise<CallerMembership | null> {
  const { data } = await admin
    .from('organization_members')
    .select('role, permissions')
    .eq('organization_id', orgId)
    .eq('user_id', userId)
    .eq('status', 'active')
    .maybeSingle();
  return (data as CallerMembership | null) ?? null;
}

function friendlyAuthError(message: string, A: AccountStrings): string {
  if (/already|registered|exists/i.test(message)) return A.idTaken;
  if (/password/i.test(message)) return A.passwordInvalid;
  return A.createFailed;
}

function requirePassword(password: string | undefined, A: AccountStrings): string {
  if (!password || password.length < 8) throw new AccountError(A.passwordShort);
  return password;
}

export interface ProvisionStudentInput {
  orgId: string;
  fullName: string;
  studentCode: string;
  circleId: string;
  password: string;
  /** Optional real email; otherwise the student signs in with the number. */
  email?: string | null;
  birthDate?: string | null;
  phone?: string | null;
  whatsapp?: string | null;
  address?: string | null;
}

/**
 * Creates a student's login AND record in one step (eqraa's
 * provision_student_account). Admins may add anyone; a teacher only into
 * their own circle, and only while the center allows teachers to manage
 * students (organization_settings.flag_teacher_manage_students).
 */
export async function provisionStudent(admin: SupabaseClient, callerId: string, input: ProvisionStudentInput) {
  const A = (await staffStrings()).accounts;
  const caller = await membershipOf(admin, callerId, input.orgId);
  if (!caller) throw new AccountError(A.notAllowed);

  const fullName = input.fullName?.trim();
  const studentCode = input.studentCode?.trim();
  if (!fullName) throw new AccountError(A.studentNameRequired);
  if (!studentCode) throw new AccountError(A.studentCodeRequired);
  const password = requirePassword(input.password, A);

  const { data: circle } = await admin
    .from('circles')
    .select('id, teacher_id')
    .eq('id', input.circleId)
    .eq('organization_id', input.orgId)
    .maybeSingle();
  if (!circle) throw new AccountError(A.circleRequired);

  if (caller.role === 'teacher') {
    const { data: flag } = await admin
      .from('organization_settings')
      .select('value')
      .eq('organization_id', input.orgId)
      .eq('key', 'flag_teacher_manage_students')
      .maybeSingle();
    if (flag?.value === 'false') throw new AccountError(A.teacherAddOff);
    if (!(caller.permissions ?? []).includes('students')) throw new AccountError(A.noStudentsPermission);
    if (circle.teacher_id !== callerId) {
      const { data: assist } = await admin.from('circle_assistants').select('user_id').eq('circle_id', circle.id).eq('user_id', callerId).maybeSingle();
      if (!assist) throw new AccountError(A.ownCircleOnly);
    }
  } else if (caller.role !== 'admin') {
    throw new AccountError(A.notAllowed);
  }

  const { data: org } = await admin.from('organizations').select('slug').eq('id', input.orgId).single();
  if (!org) throw new AccountError(A.noCenter);

  const email = input.email?.trim() ? input.email.trim().toLowerCase() : toLoginEmail(org.slug, studentCode);

  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });
  if (createError || !created.user) throw new AccountError(friendlyAuthError(createError?.message ?? '', A));
  const userId = created.user.id;

  const undo = async () => {
    await admin.auth.admin.deleteUser(userId);
  };

  const { data: member, error: memberError } = await admin
    .from('organization_members')
    .insert({ organization_id: input.orgId, user_id: userId, role: 'student', status: 'active', invited_by: callerId })
    .select('id')
    .single();
  if (memberError || !member) {
    await undo();
    throw new AccountError(A.linkFailed);
  }

  const { data: student, error: studentError } = await admin
    .from('students_profile')
    .insert({
      organization_id: input.orgId,
      student_code: studentCode,
      full_name: fullName,
      circle_id: input.circleId,
      member_id: member.id,
      birth_date: input.birthDate || null,
      phone: input.phone?.trim() || null,
      whatsapp: input.whatsapp?.trim() || null,
      address: input.address?.trim() || null,
    })
    .select('id')
    .single();
  if (studentError || !student) {
    await undo();
    throw new AccountError(studentError?.code === '23505' ? A.codeTaken : A.studentFailed);
  }

  return { studentId: student.id as string, loginEmail: email, loginId: email.includes('.id.bustan') ? studentCode : email };
}

export interface ProvisionTeacherInput {
  orgId: string;
  fullName: string;
  /** ID number (signs in with number + center code) or a real email. */
  identifier: string;
  password: string;
  phone?: string | null;
  whatsapp?: string | null;
}

export async function provisionTeacher(admin: SupabaseClient, callerId: string, input: ProvisionTeacherInput) {
  const A = (await staffStrings()).accounts;
  const caller = await membershipOf(admin, callerId, input.orgId);
  if (caller?.role !== 'admin') throw new AccountError(A.notAllowed);

  const fullName = input.fullName?.trim();
  const identifier = input.identifier?.trim();
  if (!fullName) throw new AccountError(A.teacherNameRequired);
  if (!identifier) throw new AccountError(A.idRequired);
  const password = requirePassword(input.password, A);

  const { data: org } = await admin.from('organizations').select('slug').eq('id', input.orgId).single();
  if (!org) throw new AccountError(A.noCenter);

  const email = toLoginEmail(org.slug, identifier);
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });
  if (createError || !created.user) throw new AccountError(friendlyAuthError(createError?.message ?? '', A));

  const { error: memberError } = await admin.from('organization_members').insert({
    organization_id: input.orgId,
    user_id: created.user.id,
    role: 'teacher',
    status: 'active',
    invited_by: callerId,
  });
  if (memberError) {
    await admin.auth.admin.deleteUser(created.user.id);
    throw new AccountError(A.linkFailed);
  }

  const contact = { phone: input.phone?.trim() || null, whatsapp: input.whatsapp?.trim() || null };
  if (contact.phone || contact.whatsapp) {
    await admin.from('profiles').update(contact).eq('id', created.user.id);
  }
  return { userId: created.user.id as string, loginEmail: email };
}

export interface ProvisionGuardianInput {
  orgId: string;
  studentId: string;
  fullName: string;
  identifier: string;
  password: string;
  phone?: string | null;
}

/**
 * Creates a guardian login and links it to a student (students_profile.
 * guardian_member_id). Admin only. RLS then limits the guardian to the
 * children linked to them.
 */
export async function provisionGuardian(admin: SupabaseClient, callerId: string, input: ProvisionGuardianInput) {
  const A = (await staffStrings()).accounts;
  const caller = await membershipOf(admin, callerId, input.orgId);
  if (caller?.role !== 'admin') throw new AccountError(A.notAllowed);

  const fullName = input.fullName?.trim();
  const identifier = input.identifier?.trim();
  if (!fullName) throw new AccountError(A.guardianNameRequired);
  if (!identifier) throw new AccountError(A.loginRequired);
  const password = requirePassword(input.password, A);

  const { data: student } = await admin
    .from('students_profile')
    .select('id, guardian_member_id')
    .eq('id', input.studentId)
    .eq('organization_id', input.orgId)
    .maybeSingle();
  if (!student) throw new AccountError(A.noStudent);
  if (student.guardian_member_id) throw new AccountError(A.hasGuardian);

  const { data: org } = await admin.from('organizations').select('slug').eq('id', input.orgId).single();
  if (!org) throw new AccountError(A.noCenter);

  const email = toLoginEmail(org.slug, identifier);
  const { data: created, error: createError } = await admin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { full_name: fullName },
  });
  if (createError || !created.user) throw new AccountError(friendlyAuthError(createError?.message ?? '', A));

  const { data: member, error: memberError } = await admin
    .from('organization_members')
    .insert({ organization_id: input.orgId, user_id: created.user.id, role: 'guardian', status: 'active', invited_by: callerId })
    .select('id')
    .single();
  if (memberError || !member) {
    await admin.auth.admin.deleteUser(created.user.id);
    throw new AccountError(A.linkFailed);
  }

  const { error: linkError } = await admin
    .from('students_profile')
    .update({ guardian_member_id: member.id })
    .eq('id', input.studentId)
    .eq('organization_id', input.orgId);
  if (linkError) {
    await admin.from('organization_members').delete().eq('id', member.id);
    await admin.auth.admin.deleteUser(created.user.id);
    throw new AccountError(A.guardianLinkFailed);
  }

  if (input.phone?.trim()) {
    await admin.from('profiles').update({ phone: input.phone.trim() }).eq('id', created.user.id);
  }
  return { memberId: member.id as string, loginEmail: email };
}

/** Links an EXISTING guardian (e.g. one with several children) to another student. */
export async function linkGuardian(
  admin: SupabaseClient,
  callerId: string,
  input: { orgId: string; studentId: string; guardianMemberId: string | null },
) {
  const A = (await staffStrings()).accounts;
  const caller = await membershipOf(admin, callerId, input.orgId);
  if (caller?.role !== 'admin') throw new AccountError(A.notAllowed);

  if (input.guardianMemberId) {
    const { data: guardian } = await admin
      .from('organization_members')
      .select('id')
      .eq('id', input.guardianMemberId)
      .eq('organization_id', input.orgId)
      .eq('role', 'guardian')
      .maybeSingle();
    if (!guardian) throw new AccountError(A.noGuardian);
  }

  const { error } = await admin
    .from('students_profile')
    .update({ guardian_member_id: input.guardianMemberId })
    .eq('id', input.studentId)
    .eq('organization_id', input.orgId);
  if (error) throw new AccountError(A.relinkFailed);
}

/** Admin resets any member's password (students have no real email to recover with). */
export async function resetMemberPassword(
  admin: SupabaseClient,
  callerId: string,
  input: { orgId: string; memberId: string; password: string },
) {
  const A = (await staffStrings()).accounts;
  const caller = await membershipOf(admin, callerId, input.orgId);
  if (caller?.role !== 'admin') throw new AccountError(A.notAllowed);
  const password = requirePassword(input.password, A);

  const { data: member } = await admin
    .from('organization_members')
    .select('user_id')
    .eq('id', input.memberId)
    .eq('organization_id', input.orgId)
    .maybeSingle();
  if (!member) throw new AccountError(A.noMember);

  const { error } = await admin.auth.admin.updateUserById(member.user_id, { password });
  if (error) throw new AccountError(A.passwordFailed);
}
