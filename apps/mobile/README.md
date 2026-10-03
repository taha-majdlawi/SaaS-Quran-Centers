# apps/mobile

هيكلية Flutter لتطبيق SaaS متعدد المراكز، مبنية على نفس أنماط `eqraa_app` (feature-first, Provider, go_router, Supabase, sqflite offline sync) مع إضافة طبقة مستأجر (tenant) جديدة بالكامل.

## الجديد مقارنة بـ eqraa_app

- `lib/core/tenant/` — نموذج `Organization`/`OrganizationMembership`، `TenantRepository` (يقرأ عضويات المستخدم عبر RLS)، و`TenantController` (يدير المركز النشط حاليًا ويُبقيه محفوظًا محليًا).
- `lib/core/router/app_router.dart` — نفس نمط الحراسة (guard) المبني على الدور في eqraa_app، مع طبقة إضافية: مستخدم بدون مركز نشط يُوجَّه لشاشة اختيار/انضمام لمركز.
- `lib/core/supabase/supabase_client.dart` — تهيئة مشروع Supabase **واحد** يخدم كل المراكز (بدل مشروع منفصل لكل عميل).
- دور `guardian` أصبح مسارًا كاملًا (`lib/features/guardian_dashboard/`) بدل صفحات ويب منفصلة فقط.

## خطة نقل الميزات من eqraa_app (E:\FLUTTER PROJECTS\eqraa_app)

كل مجلد ميزة هنا فاضي حاليًا (سكيلتون فقط) وينتظر نقل المنطق من نظيره في eqraa_app **مع** إضافة فلترة `organization_id` الضمنية (تأتي تلقائيًا من RLS، لا حاجة لتغيير الاستعلامات نفسها غالبًا):

| هنا | ينقل من |
|---|---|
| `features/auth` | `eqraa_app/lib/features/auth` |
| `features/student_dashboard` | `eqraa_app/lib/features/student_dashboard` |
| `features/teacher_dashboard` | `eqraa_app/lib/features/teacher_dashboard` |
| `features/admin_dashboard` | `eqraa_app/lib/features/admin_dashboard` |
| `features/guardian_dashboard` | جديد — انظر صفحات `parent-consent`/`parent-progress` بمشروع الويب القديم كمرجع للمتطلبات |
| `features/quran` | `eqraa_app/lib/features/quran` |
| `core/chat`, `core/calendar`, `core/notifications`, `core/offline`, `core/access` | نفس المسارات في `eqraa_app/lib/core/*` — منطقها لا يتغير جوهريًا، فقط يحتاج تمرير `organization_id` النشط من `TenantController` عند إنشاء أي صف جديد |

## التشغيل محليًا

القيمتان اللي التطبيق يحتاجهم (`SUPABASE_URL` و `SUPABASE_PUBLISHABLE_KEY`) محفوظتان جاهزتان في `env.json` بهذا المجلد - نفس المفتاح العام (anon/publishable) المستخدم أصلاً بحزمة الويب، وليس سرًا يحتاج حماية.

```
flutter pub get
flutter run --dart-define-from-file=env.json
```

بـ VS Code: بس دوس F5 (أو "Run and Debug") - إعداد التشغيل الجاهز بـ `.vscode/launch.json` بيمرّر نفس الملف تلقائيًا.

⚠️ لا تشغّل `flutter run` بدون `--dart-define-from-file=env.json` (أو بدون تعبية `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...` يدويًا) - بدونها بيفتح التطبيق على شاشة "إعدادات الاتصال بالخادم مفقودة" فقط، لأنه ما يقدر يتصل بسوبا بيز أصلاً.

## الآيفون

نفس الكود يبني للآيفون على Codemagic (`codemagic.yaml` بجذر المستودع) — الخطوات كاملة في [docs/IOS.md](../../docs/IOS.md).
