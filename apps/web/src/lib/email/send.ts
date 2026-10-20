// Platform emails that are not Supabase Auth's (those go through Supabase's SMTP): sent with the
// Resend API, the same provider (docs/EMAIL.md). RESEND_API_KEY lives only in the deploy secrets
// (WEB_ENV); without it nothing is sent and the caller falls back (e.g. the invite link to copy).

export interface Email {
  to: string;
  subject: string;
  html: string;
  text: string;
}

export function emailConfigured(): boolean {
  return !!process.env.RESEND_API_KEY;
}

/** True when the provider accepted the email. Never throws: a failed send must not break the page. */
export async function sendEmail(email: Email): Promise<boolean> {
  const key = process.env.RESEND_API_KEY;
  if (!key) return false;
  try {
    const res = await fetch(process.env.RESEND_API_URL || 'https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: process.env.EMAIL_FROM || 'بستان القرآن <noreply@bustan-alquran.com>',
        reply_to: 'support@bustan-alquran.com',
        to: [email.to],
        subject: email.subject,
        html: email.html,
        text: email.text,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    return res.ok;
  } catch {
    return false;
  }
}
