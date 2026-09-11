# apps/web

تطبيق Next.js واحد يخدم ثلاث مناطق حسب الـ hostname (راجع `middleware.ts` و [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md) القسم 4)، ويحل محل موقع `wep-eqraa-center` الثابت.

| Hostname (محليًا) | يعادل |
|---|---|
| `localhost:3000` | `app/(marketing)` - الموقع التسويقي للمنصة |
| `admin.localhost:3000` | `app/(platform)/platform` - لوحة مالك المنصة (بديل `dev/`) |
| `demo.localhost:3000` | `app/(tenant)/[org]` - لوحة إدارة مركز "demo" (بديل `admin/`) |

> لتجربة النطاقات الفرعية محليًا: أضف أسطر مثل `127.0.0.1 admin.localhost` و `127.0.0.1 demo.localhost` لملف `hosts`، أو استخدم `demo.localhost:3000` مباشرة (متصفحات Chromium تحلّه تلقائيًا لـ 127.0.0.1 بدون تعديل).

## البنية

- `middleware.ts` — يحوّل الـ hostname إلى مسار داخلي (`admin.*` → `/platform/*`, `{slug}.*` → `/{slug}/*`).
- `src/lib/supabase/` — عميلا Supabase (متصفح + خادم)، بنفس نمط الثقة القديم: مفتاح anon فقط، والأمان بالكامل عبر RLS.
- `src/lib/tenant/get-org-context.ts` — يحل المركز الحالي من الـ slug + دور المستخدم الحالي فيه. كل صفحة تحت `app/(tenant)/[org]/*` تبدأ باستدعائه.
- `src/components/tenant-sidebar.tsx` — قائمة الموديولات الـ21 (مصدر واحد بدل تكرارها بكل صفحة HTML كما كان بالمشروع القديم).
- `src/app/(tenant)/[org]/*` — كل مجلد يقابل موديولًا كان صفحة HTML مستقلة في `wep-eqraa-center/admin/`. `dashboard/` و `students/` مبنيان كمثال حقيقي (يجلبان بيانات فعلية عبر Supabase مفلترة بـ RLS)، والباقي `ModulePlaceholder` بانتظار نقل المنطق (كل صفحة تذكر مسارها القديم بالتعليق).

## التشغيل محليًا

```
npm install
cp .env.example .env.local   # ثم املأ SUPABASE_URL / ANON_KEY
npm run dev
```
