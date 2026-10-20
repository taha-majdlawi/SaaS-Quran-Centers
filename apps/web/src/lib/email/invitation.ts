import type { Email } from './send';

const esc = (s: string) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);

/**
 * The invitation email: same look as supabase/templates/*.html. The link opens the center's
 * /join page, where the invited person sets their own password (or enters it, if the email
 * already has an account) - the link alone never signs anyone in.
 */
export function invitationEmail(input: { to: string; orgName: string; roleLabel: string; link: string; days: number }): Email {
  const org = esc(input.orgName);
  const role = esc(input.roleLabel);
  const link = esc(input.link);
  const subject = `دعوة للانضمام إلى ${input.orgName} - بستان القرآن`;
  const html = `<!doctype html>
<html lang="ar" dir="rtl">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${esc(subject)}</title></head>
<body style="margin:0;padding:0;background:#FBF8F1;font-family:Tahoma,Arial,sans-serif;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background:#FBF8F1;padding:32px 12px;">
<tr><td align="center">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#ffffff;border:1px solid #E7E2D6;border-radius:16px;overflow:hidden;">
<tr><td align="center" style="background:#1E7A54;border-radius:16px 16px 0 0;padding:28px 28px 22px;">
<img src="https://bustan-alquran.com/email/logo.png" width="72" height="72" alt="بستان القرآن" style="display:block;width:72px;height:72px;border:0;border-radius:36px;">
<p style="margin:12px 0 0;color:#ffffff;font-size:17px;font-weight:bold;letter-spacing:0.3px;">بستان القرآن</p>
<p style="margin:2px 0 0;color:#CFE7DA;font-size:12px;">منصة إدارة مراكز تحفيظ القرآن الكريم</p>
</td></tr>
<tr><td align="center" style="padding:28px 28px 0;">
<h1 style="margin:0;color:#111827;font-size:20px;">دعوة للانضمام إلى ${org}</h1>
</td></tr>
<tr><td style="padding:16px 28px 0;color:#374151;font-size:15px;line-height:1.8;text-align:right;">السلام عليكم ورحمة الله،<br>دعاك مدير <b>${org}</b> للانضمام إلى المركز على بستان القرآن بصفة <b>${role}</b>. اضغط الزر، ثم اختر كلمة سر لحسابك (أو أدخل كلمة سرك إن كان لهذا البريد حساب).</td></tr>
<tr><td align="center" style="padding:24px 28px;">
<a href="${link}" style="display:inline-block;background:#1E7A54;color:#ffffff;text-decoration:none;font-size:15px;font-weight:bold;padding:12px 28px;border-radius:10px;">قبول الدعوة</a>
</td></tr>
<tr><td style="padding:0 28px 16px;color:#9CA3AF;font-size:12px;line-height:1.7;text-align:right;">إذا لم يعمل الزر، انسخ هذا الرابط في المتصفح:<br><a href="${link}" style="color:#1E7A54;word-break:break-all;" dir="ltr">${link}</a></td></tr>
<tr><td style="padding:0 28px 8px;color:#6B7280;font-size:13px;line-height:1.7;text-align:right;">الدعوة صالحة ${input.days} أيام، ولهذا البريد فقط. إذا لم تكن تتوقعها فتجاهل هذه الرسالة.</td></tr>
<tr><td style="padding:8px 28px 24px;color:#9CA3AF;font-size:12px;line-height:1.6;text-align:left;" dir="ltr">Assalamu alaikum. You were invited to join ${org} on Bustan Al-Quran. Tap the button and choose a password for your account. The invitation is valid for ${input.days} days and for this email only.</td></tr>
<tr><td style="border-top:1px solid #F0EBE0;background:#FBF8F1;border-radius:0 0 16px 16px;padding:16px 28px;color:#9CA3AF;font-size:12px;text-align:center;">
بستان القرآن — منصة إدارة مراكز تحفيظ القرآن الكريم<br>
<a href="https://bustan-alquran.com" style="color:#1E7A54;text-decoration:none;">bustan-alquran.com</a> · <a href="mailto:support@bustan-alquran.com" style="color:#1E7A54;text-decoration:none;">support@bustan-alquran.com</a>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;
  const text = `السلام عليكم ورحمة الله،
دعاك مدير ${input.orgName} للانضمام إلى المركز على بستان القرآن بصفة ${input.roleLabel}.
افتح الرابط واختر كلمة سر لحسابك: ${input.link}
الدعوة صالحة ${input.days} أيام، ولهذا البريد فقط.

You were invited to join ${input.orgName} on Bustan Al-Quran: ${input.link}`;
  return { to: input.to, subject, html, text };
}
