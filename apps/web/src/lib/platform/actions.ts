'use server';

import { redirect } from '@/lib/platform/redirect';
import { createClient } from '@/lib/supabase/server';
import { createAdminClient } from '@/lib/supabase/admin';
import { withParam } from '@/lib/calendar/actions-shared';

const s = (f: FormData, k: string) => ((f.get(k) as string) ?? '').trim();
const orNull = (f: FormData, k: string) => s(f, k) || null;
const num = (f: FormData, k: string) => {
  const v = s(f, k);
  return v === '' ? null : Number(v);
};

/** Runs one owner RPC, then returns to `back` with ?ok= / ?error=. Every RPC re-checks is_platform_owner() itself. */
async function run(fn: string, args: Record<string, unknown>, back: string, ok: string): Promise<never> {
  const supabase = await createClient();
  const { error } = await supabase.rpc(fn, args);
  if (error) return redirect(withParam(back, 'error', error.message) as never);
  return redirect(withParam(back, 'ok', ok) as never);
}

/** Service-role actions must be gated by hand: the caller has to be the owner, past the second factor (0094). */
async function requireOwner(): Promise<string> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return redirect('/login' as never);
  const { data: isOwner } = await supabase.rpc('is_platform_owner');
  if (isOwner !== true) return redirect('/login' as never);
  return user.id;
}

async function logEvent(action: string, target: string, detail: Record<string, unknown>) {
  const supabase = await createClient();
  await supabase.rpc('platform_log_event', { p_action: action, p_target: target, p_detail: detail });
}

// ---- centers ---------------------------------------------------------------------

export async function createOrg(formData: FormData) {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('platform_create_org', {
    p_name: s(formData, 'name'),
    p_slug: s(formData, 'slug'),
    p_plan: orNull(formData, 'planId'),
    p_admin_email: s(formData, 'adminEmail') || null,
  });
  if (error) return redirect(withParam('/organizations', 'error', error.message) as never);
  const r = data as { id: string; invite_token: string | null };
  // the invitation link is shown once on the new center's page
  return redirect(`/organizations/${r.id}?created=1${r.invite_token ? `&invite=${r.invite_token}` : ''}` as never);
}

export async function updateOrg(formData: FormData) {
  const id = s(formData, 'id');
  await run(
    'platform_update_org',
    {
      p_org: id,
      p_name: s(formData, 'name'),
      p_timezone: s(formData, 'timezone'),
      p_primary: s(formData, 'primary'),
      p_secondary: s(formData, 'secondary'),
      p_logo: s(formData, 'logo') || null,
      p_status: s(formData, 'status'),
      p_plan: orNull(formData, 'planId'),
      p_trial_ends: orNull(formData, 'trialEnds'),
    },
    `/organizations/${id}`,
    'saved',
  );
}

export async function deleteOrg(formData: FormData) {
  const id = s(formData, 'id');
  const supabase = await createClient();
  const { error } = await supabase.rpc('platform_delete_org', { p_org: id, p_slug: s(formData, 'confirmSlug') });
  if (error) return redirect(withParam(`/organizations/${id}`, 'error', error.message) as never);
  return redirect('/organizations?ok=deleted' as never);
}

export async function setMember(formData: FormData) {
  const org = s(formData, 'orgId');
  await run('platform_set_member', { p_member: s(formData, 'memberId'), p_role: s(formData, 'role'), p_status: s(formData, 'status') }, `/organizations/${org}`, 'member');
}

export async function addMember(formData: FormData) {
  const org = s(formData, 'orgId');
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('platform_add_member', { p_org: org, p_email: s(formData, 'email'), p_role: s(formData, 'role') });
  if (error) return redirect(withParam(`/organizations/${org}`, 'error', error.message) as never);
  const r = data as { added: boolean; invite_token: string | null };
  return redirect(`/organizations/${org}?ok=${r.added ? 'member' : 'invited'}${r.invite_token ? `&invite=${r.invite_token}` : ''}` as never);
}

export async function setOrgSetting(formData: FormData) {
  const org = s(formData, 'orgId');
  const remove = formData.get('remove') === '1';
  await run('platform_set_org_setting', { p_org: org, p_key: s(formData, 'key'), p_value: remove ? null : s(formData, 'value') }, `/organizations/${org}`, 'setting');
}

/** All feature switches of one center (or the platform defaults when orgId is empty) in one submit: '' = inherit, on, off. */
export async function saveFeatures(formData: FormData) {
  const org = orNull(formData, 'orgId');
  const supabase = await createClient();
  for (const [name, value] of formData.entries()) {
    if (!name.startsWith('f_')) continue;
    const enabled = value === 'on' ? true : value === 'off' ? false : null;
    const { error } = await supabase.rpc('platform_set_feature', { p_org: org, p_key: name.slice(2), p_enabled: enabled });
    if (error) return redirect(withParam(org ? `/organizations/${org}` : '/feature-flags', 'error', error.message) as never);
  }
  return redirect(withParam(org ? `/organizations/${org}` : '/feature-flags', 'ok', 'features') as never);
}

// ---- plans / settings / notices -----------------------------------------------------

export async function savePlan(formData: FormData) {
  const features: Record<string, boolean> = {};
  for (const [name, value] of formData.entries()) {
    if (name.startsWith('pf_') && value === 'off') features[name.slice(3)] = false;
    if (name.startsWith('pf_') && value === 'on') features[name.slice(3)] = true;
  }
  await run(
    'platform_save_plan',
    {
      p_id: orNull(formData, 'id'),
      p_code: s(formData, 'code'),
      p_name: s(formData, 'name'),
      p_price_cents: Math.round(Number(s(formData, 'price') || '0') * 100),
      p_yearly_cents: s(formData, 'yearlyPrice') === '' ? null : Math.round(Number(s(formData, 'yearlyPrice')) * 100),
      p_currency: s(formData, 'currency') || 'USD',
      p_max_students: num(formData, 'maxStudents'),
      p_max_teachers: num(formData, 'maxTeachers'),
      p_storage_mb: num(formData, 'storageMb'),
      p_features: features,
      p_active: formData.get('active') === 'on',
    },
    '/plans',
    'saved',
  );
}

export async function deletePlan(formData: FormData) {
  await run('platform_delete_plan', { p_id: s(formData, 'id') }, '/plans', 'deleted');
}

export async function savePlatformSettings(formData: FormData) {
  await run(
    'platform_set_settings',
    { p_signup: formData.get('signup') === 'on', p_default_plan: orNull(formData, 'defaultPlan'), p_trial_days: Number(s(formData, 'trialDays') || '0') },
    '/settings',
    'saved',
  );
}

export async function saveNotice(formData: FormData) {
  const ends = s(formData, 'endsAt');
  await run(
    'platform_save_notice',
    {
      p_id: orNull(formData, 'id'),
      p_title: s(formData, 'title'),
      p_body: orNull(formData, 'body'),
      p_level: s(formData, 'level') || 'info',
      p_active: formData.get('active') === 'on',
      p_ends: ends ? new Date(ends).toISOString() : null,
    },
    '/notices',
    'saved',
  );
}

export async function deleteNotice(formData: FormData) {
  await run('platform_delete_notice', { p_id: s(formData, 'id') }, '/notices', 'deleted');
}

// ---- accounts (service role: gated by requireOwner) ---------------------------------------

export async function setBan(formData: FormData) {
  const me = await requireOwner();
  const id = s(formData, 'userId');
  const ban = formData.get('ban') === '1';
  if (id === me) return redirect(withParam('/users', 'error', 'لا يمكنك إيقاف حسابك') as never);
  const { error } = await createAdminClient().auth.admin.updateUserById(id, { ban_duration: ban ? '876000h' : 'none' });
  if (error) return redirect(withParam('/users', 'error', error.message) as never);
  await logEvent(ban ? 'ban_user' : 'unban_user', id, {});
  return redirect(withParam('/users', 'ok', ban ? 'banned' : 'unbanned') as never);
}

export async function setUserPassword(formData: FormData) {
  await requireOwner();
  const id = s(formData, 'userId');
  const password = (formData.get('password') as string) ?? '';
  if (password.length < 12) return redirect(withParam('/users', 'error', 'كلمة السر 12 حرفًا على الأقل') as never);
  const { error } = await createAdminClient().auth.admin.updateUserById(id, { password });
  if (error) return redirect(withParam('/users', 'error', error.message) as never);
  await logEvent('set_user_password', id, {});
  return redirect(withParam('/users', 'ok', 'password') as never);
}

export async function deleteUser(formData: FormData) {
  const me = await requireOwner();
  const id = s(formData, 'userId');
  const email = s(formData, 'email').toLowerCase();
  if (id === me) return redirect(withParam('/users', 'error', 'لا يمكنك حذف حسابك') as never);
  if (s(formData, 'confirmEmail').toLowerCase() !== email) return redirect(withParam('/users', 'error', 'اكتب البريد بالضبط لتأكيد الحذف') as never);
  const supabase = await createClient();
  const { data: owner } = await supabase.from('platform_owners').select('user_id').eq('user_id', id).maybeSingle();
  if (owner) return redirect(withParam('/users', 'error', 'لا يمكن حذف مالك منصة') as never);
  const { error } = await createAdminClient().auth.admin.deleteUser(id);
  if (error) return redirect(withParam('/users', 'error', error.message) as never);
  await logEvent('delete_user', id, { email });
  return redirect(withParam('/users', 'ok', 'deleted') as never);
}
