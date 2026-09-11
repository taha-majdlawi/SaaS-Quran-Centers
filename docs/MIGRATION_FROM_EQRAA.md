# قائمة نقل الميزات من مشروعي اقرأ الحاليين

مصدرا الميزات:
- الموبايل: `E:\FLUTTER PROJECTS\eqraa_app`
- الويب: `C:\Users\hp\Desktop\wep-eqraa-center`

هذه القائمة تتبع حالة كل ميزة أثناء النقل إلى `apps/mobile` و `apps/web`. البنية (schema, routing, RLS) جاهزة لكل هذه الميزات؛ ما تبقى هو نقل منطق الواجهة والاستعلامات الفعلية.

## قاعدة البيانات
- [x] مخطط متعدد المستأجرين كامل (7 ملفات ترحيل، `supabase/migrations/`)
- [ ] تصدير بيانات حقيقية من مشروع Supabase الحالي وتحويلها لتناسب المخطط الجديد (سكربت ETL - غير مطلوب الآن)
- [ ] Custom Access Token Hook لوضع `organization_id` النشط داخل الـ JWT (تحسين أداء مستقبلي)

## تطبيق الموبايل (`apps/mobile`)
- [x] هيكل feature-first + طبقة tenant جديدة
- [ ] `features/auth` — نقل شاشات الدخول (طالب/معلم/أدمن) + إضافة اختيار/دعوة مركز
- [ ] `features/student_dashboard`, `features/teacher_dashboard`, `features/admin_dashboard`
- [ ] `features/quran` (قارئ المصحف - لا تغيير جوهري، بيانات عالمية غير مرتبطة بمستأجر)
- [ ] `features/guardian_dashboard` (جديد بالكامل)
- [ ] `core/chat`, `core/calendar`, `core/notifications`, `core/offline`, `core/access`
- [ ] العلامة التجارية الديناميكية: قراءة الشعار/الألوان من `organizations` بدل أصول بناء ثابتة

## تطبيق الويب (`apps/web`)
- [x] Middleware توجيه المستأجرين بالنطاق الفرعي
- [x] `dashboard`, `students` (أمثلة حقيقية تجلب بيانات فعلية)
- [ ] باقي الموديولات الـ19 (راجع `src/components/tenant-sidebar.tsx` للقائمة الكاملة) - كل صفحة حاليًا `ModulePlaceholder` يذكر مسارها القديم
- [ ] مصادقة فعلية (Supabase Auth + middleware يتحقق من الجلسة، وليس فقط شكل الرابط)
- [ ] صفحة عامة لكل مركز مبنية على `site_settings` (تعادل الموقع التسويقي القديم، لكن لكل عميل)
- [ ] صفحات الموافقات القانونية (`privacy`, `parent-consent`, `trip-consent`, `delete-account`, `support`) - يمكن أن تبقى صفحات ثابتة عامة على نطاق المنصة نفسه، أو تُخصَّص لكل مركز عبر `site_settings`

## الفوترة
- [x] جداول `plans` / `subscriptions` (سكيلتون)
- [ ] تكامل Stripe فعلي (checkout, webhooks, تحديث `subscriptions.status`)
