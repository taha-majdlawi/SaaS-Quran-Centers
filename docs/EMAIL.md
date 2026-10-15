# البريد الإلكتروني للمنصة

## العناوين (مُعدّة)

| العنوان | الاستقبال | الإرسال |
|---|---|---|
| `info@`، `support@`، `taha@` | Cloudflare Email Routing ← Gmail | Gmail «إرسال بريد باسم» عبر SMTP لـResend |
| `noreply@` | — (للإرسال فقط) | إيميلات المنصة من Supabase عبر SMTP لـResend |

سجلات DNS بـCloudflare:
- **MX وSPF على الدومين الرئيسي:** حطّها Email Routing، ومقفولة.
- **سجلات Resend:** على `send` و`resend._domainkey`.
- **`_dmarc`:** للحماية من التزوير.

## إيميلات المنصة (تأكيد البريد وإعادة كلمة السر)

### كيف بتشتغل
- **التسجيل (مركز جديد أو دعوة):** إذا «Confirm email» مفعّل، اختيار الزائر (اسم المركز ورابطه، أو رمز الدعوة) بيتخزّن بـ`user_metadata` لحسابه. رابط الإيميل بيفتح `https://bustan-alquran.com/confirm`، وهاي الصفحة:
  1. بتتحقق من الرمز بالمتصفح؛
  2. بتنشئ المركز أو بتقبل الدعوة؛
  3. بتنقل المستخدم على مركزه.

  إذا رابط المركز انحجز بالفترة بين التسجيل والتأكيد، الصفحة بتطلب رابط ثاني.
- **إعادة كلمة السر:** الرابط بيفتح صفحة `reset-password` بالمركز، وفيه `token_hash` بيتحقق منه المتصفح.
- **بالحالتين:** الرابط بيشتغل **على أي جهاز**، ولمرة واحدة. والرمز بينشال من شريط العنوان أول ما ينقرأ. وبرامج فحص البريد اللي بتفتح الرابط لحالها ما بتستهلكه، لأنه التحقق بيصير بالـJavaScript.
- **إذا «Confirm email» مطفي:** كل شي بيشتغل متل قبل، والمركز بينعمل فورًا.

### الإعداد بـSupabase (مرة وحدة، بهالترتيب)
1. **Authentication ← Emails ← SMTP Settings ← Enable custom SMTP:**
   - Sender email: `noreply@bustan-alquran.com`
   - Sender name: `بستان القرآن`
   - Host: `smtp.resend.com`
   - Port: `465`
   - Username: `resend`
   - Password: مفتاح API **جديد** من Resend، خاص بـSupabase
2. **Authentication ← Rate Limits:** بعد الـSMTP المخصّص، ارفع «Emails sent per hour» لـ100 مثلًا.
3. **Authentication ← URL Configuration:**
   - **Site URL:** `https://bustan-alquran.com`
   - **Redirect URLs:** `https://bustan-alquran.com/**` و`https://*.bustan-alquran.com/**`
4. **Authentication ← Emails ← Templates:** لكل قالب، انسخ العنوان ومحتوى الملف:

   | القالب | العنوان (Subject) | الملف |
   |---|---|---|
   | Confirm signup | تأكيد بريدك في بستان القرآن | `supabase/templates/confirmation.html` |
   | Reset Password | إعادة تعيين كلمة السر - بستان القرآن | `supabase/templates/recovery.html` |
   | Change Email Address | تأكيد تغيير بريدك الإلكتروني - بستان القرآن | `supabase/templates/email_change.html` |

5. **جرّب إعادة كلمة السر** من صفحة دخول أي مركز («نسيت كلمة السر»)، وافتح الرابط من جوال ثاني.
6. **بعد ما تنجح الخطوة 5:** روح على Authentication ← Sign In / Providers ← Email، وفعّل **Confirm email**، وجرّب تسجيل مركز جديد ببريد حقيقي.

### الحسابات اللي بيعملها مدير المركز
المعلمين والطلاب اللي بيضيفهم مدير المركز بينعملوا وبريدهم مؤكد مسبقًا (`email_confirm: true`)، فما بيوصلهم إيميل تأكيد. والحسابات اللي بتدخل برقم بس، ما إلها بريد حقيقي، وكلمة سرها بيرجّعها مدير المركز.

### الشعار والصورة
- **الشعار جوّا الإيميل:** القوالب بتعرض `https://bustan-alquran.com/email/logo.png` (`apps/web/public/email/logo.png`). لا تغيّر هالمسار، لأنه الإيميلات القديمة بتضل تطلبه.
- **صورة المرسل بقائمة الرسائل (الدائرة جنب الاسم):**
  - **Gmail:** بيعرض صورة حساب Google تبع المرسل. فإذا المرسل حساب Google عليه صورة الشعار، بتظهر الصورة عند مستخدمي Gmail. عشان هيك: Sender email = `support@bustan-alquran.com` (إله حساب Google)، وحط صورة الشعار لهالحساب من **myaccount.google.com ← Personal info ← Photo**.
  - **لكل البرامج (BIMI):** بدها سجل DMARC بـ`p=quarantine` أو `reject` وشهادة شعار مدفوعة (VMC). مش ضرورية هلأ.
