import type { SupabaseClient } from '@supabase/supabase-js';
import { emailConfigured, sendEmail } from '@/lib/email/send';
import { invitationEmail } from '@/lib/email/invitation';
import { productUrl } from '@/lib/auth/signup';

const ROLE_AR: Record<string, string> = { admin: 'مدير', teacher: 'معلم', guardian: 'ولي أمر', student: 'طالب' };

/**
 * Creates (or renews) an invitation as the signed-in admin - create_invitation checks they are
 * one - and emails its link when the platform can send email. Shared by the web members page
 * and /api/accounts (the app), so both behave the same.
 */
export async function inviteMember(
  supabase: SupabaseClient,
  input: { orgId: string; email: string; role: string },
): Promise<{ token: string | null; sent: boolean; error?: string }> {
  const email = input.email.trim().toLowerCase();
  const { data, error } = await supabase.rpc('create_invitation', { org_id: input.orgId, invite_email: email, invite_role: input.role });
  if (error) return { token: null, sent: false, error: error.message };
  const token = (data as { token: string }[] | null)?.[0]?.token ?? null;
  if (!token || !emailConfigured()) return { token, sent: false };

  const { data: org } = await supabase.from('organizations').select('name, slug').eq('id', input.orgId).single();
  if (!org) return { token, sent: false };
  const sent = await sendEmail(
    invitationEmail({
      to: email,
      orgName: org.name as string,
      // the email is Arabic, like the platform's other emails
      roleLabel: ROLE_AR[input.role] ?? input.role,
      link: productUrl(`/join?token=${token}`, org.slug as string),
      days: 7,
    }),
  );
  return { token, sent };
}
