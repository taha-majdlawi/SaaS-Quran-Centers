'use server';

import { runRpc, safeBack } from '@/lib/calendar/actions-shared';

const text = (f: FormData, k: string) => ((f.get(k) as string) ?? '').trim();

export async function issueCertificate(formData: FormData) {
  await runRpc(
    'issue_certificate',
    {
      p_org: text(formData, 'orgId'),
      p_student: text(formData, 'studentId'),
      p_kind: text(formData, 'kind') || 'custom',
      p_title: text(formData, 'title'),
      p_description: text(formData, 'description') || null,
    },
    '/certificates',
    'issued',
  );
}

export async function issueSerdCertificate(formData: FormData) {
  await runRpc(
    'issue_serd_certificate',
    { p_org: text(formData, 'orgId'), p_session: text(formData, 'sessionId') },
    safeBack(formData.get('back'), '/serd'),
    'certificate',
  );
}

export async function revokeCertificate(formData: FormData) {
  await runRpc(
    'revoke_certificate',
    { p_org: text(formData, 'orgId'), p_id: text(formData, 'id'), p_reason: text(formData, 'reason') || null },
    '/certificates',
    'revoked',
  );
}

export async function saveCertificateSettings(formData: FormData) {
  await runRpc(
    'set_certificate_settings',
    {
      p_org: text(formData, 'orgId'),
      p_signer_name: text(formData, 'signerName'),
      p_signer_title: text(formData, 'signerTitle'),
      p_footer: text(formData, 'footer'),
      p_serd_title: text(formData, 'serdTitle'),
      p_auto_serd: formData.get('autoSerd') === 'on',
    },
    '/certificates',
    'settings',
  );
}

/** Admin: turn a member's account into a viewing (read-only) account, or back. */
export async function setAccountAccess(formData: FormData) {
  const memberId = text(formData, 'memberId');
  await runRpc(
    'set_account_access',
    {
      p_org: text(formData, 'orgId'),
      p_user: text(formData, 'userId'),
      p_read_only: formData.get('readOnly') === 'on',
      p_note: text(formData, 'note') || null,
    },
    `/members/${memberId}`,
    'access',
  );
}
