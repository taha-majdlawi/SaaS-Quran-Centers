# النشر التلقائي (GitHub Actions)

لا حاجة لتشغيل أي أمر على الجهاز: كل دمج في `main` يُنشر وحده.

## ماذا يحدث
| الحدث | ما يعمل |
|---|---|
| أي دفع إلى أي فرع (وتظهر نتيجته في طلب الدمج) | **CI** (`.github/workflows/ci.yml`): بناء الموقع (مع فحص الأنواع والـ lint)، تحليل تطبيق الموبايل واختباراته، مطابقة ملفات الترجمة لمواصفاتها، وتطبيق كل الترحيلات على قاعدة جديدة فارغة ثم فحص `invariants`. |
| دمج في `main` (أو تشغيل يدوي) | **Deploy** (`.github/workflows/deploy.yml`): يعيد CI، ثم يرفع ترحيلات القاعدة إلى Supabase ويعيد فحص `invariants` عليها (دون حفظ أي شيء)، ثم يبني الموقع وينشره على Cloudflare ويتأكد أنه يجيب. |

إن فشل أي خطوة يتوقف ما بعدها: ترحيل فاشل لا يُنشر معه موقع، و CI أحمر لا يصل إلى الإنتاج.

## الإعداد مرة واحدة
في GitHub: **Settings ← Secrets and variables ← Actions ← New repository secret**، أضف:

| الاسم | القيمة |
|---|---|
| `SUPABASE_DB_URL` | نفس قيمة `SUPABASE_DB_URL` في ملف `supabase/.env` على جهازك |
| `WEB_ENV` | محتوى ملف `apps/web/.env.local` كاملًا (انسخ الملف كله والصقه) |
| `CLOUDFLARE_API_TOKEN` | من Cloudflare: **My Profile ← API Tokens ← Create Token ← قالب "Edit Cloudflare Workers"** (اختر حسابك ونطاق `bustan-alquran.com`) |
| `CLOUDFLARE_ACCOUNT_ID` | من لوحة Cloudflare: صفحة **Workers & Pages**، في العمود الجانبي «Account ID» |

لا تضع هذه القيم في أي ملف داخل المستودع ولا في المحادثات؛ مكانها أسرار GitHub فقط.

## الاستخدام
- اعمل تغييراتك في فرع وافتح طلب دمج: ينتظر CI، وإن ظهر ✅ ادمج.
- بعد الدمج افتح تبويب **Actions ← Deploy** لترى التقدّم (5–10 دقائق عادة).
- للنشر اليدوي دون تغيير: **Actions ← Deploy ← Run workflow**.

## فحص القاعدة محليًا (اختياري)
`DATABASE_URL=postgres://postgres:pw@localhost:5432/postgres bash supabase/tests/ci/run.sh` — يحتاج Postgres فارغًا؛ يطبّق كل الترحيلات ويشغّل `invariants`.
