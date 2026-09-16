# قائمة نقل الميزات من مشروعي اقرأ الحاليين

مصدرا الميزات:
- الموبايل: `E:\FLUTTER PROJECTS\eqraa_app`
- الويب: `C:\Users\hp\Desktop\wep-eqraa-center`

هذه القائمة تتبع حالة كل ميزة أثناء النقل إلى `apps/mobile` و `apps/web`. البنية (schema, routing, RLS) جاهزة لكل هذه الميزات؛ ما تبقى هو نقل منطق الواجهة والاستعلامات الفعلية.

## قاعدة البيانات
- [x] مخطط متعدد المستأجرين كامل (16 ملف ترحيل، `supabase/migrations/`)
- [ ] تصدير بيانات حقيقية من مشروع Supabase الحالي وتحويلها لتناسب المخطط الجديد (سكربت ETL - غير مطلوب الآن)
- [ ] Custom Access Token Hook لوضع `organization_id` النشط داخل الـ JWT (تحسين أداء مستقبلي)

## تطبيق الموبايل (`apps/mobile`)
- [x] هيكل feature-first + طبقة tenant جديدة
- [ ] `features/auth` — نقل شاشات الدخول (طالب/معلم/أدمن) + إضافة اختيار/دعوة مركز
- [x] `features/dashboard` (أدمن/معلم، شاشة موحدة) و `features/my_portal` (طالب/ولي أمر، شاشة موحدة) —
      قرار معماري متعمد (`app_router.dart`): الفروقات بالدور تُعالج داخل الشاشة نفسها بدل مسارات منفصلة لكل
      دور، فألغى الحاجة لمجلدات `student_dashboard`/`teacher_dashboard`/`admin_dashboard`/`guardian_dashboard`
      المنفصلة المذكورة بالخطة الأصلية. `my_portal` توسّعت لتشمل إنجازات الحفظ الأخيرة (`daily_achievements`)
      والفعاليات القادمة (`center_calendar`) فوق النقاط/الشارات/الحضور/جلسات السرد.
- [x] موافقة ولي الأمر على فعاليات التقويم التي تتطلبها (`center_calendar.requires_guardian_consent` +
      `calendar_registrations`) من داخل `my_portal` - يعادل صفحة `trip-consent/` القديمة. ولي الأمر (مش
      الطالب نفسه) يوافق/يلغي الموافقة لكل ابن على حدة؛ الموافقة/الإلغاء = إدخال/حذف صف بـ
      `calendar_registrations` (`consented_by` يسجّل عضوية ولي الأمر). تطلّب migration جديدة
      (`0016_guardian_calendar_consent.sql`): سياسة SELECT كانت لسا `is_org_member` بدون تحديد نطاق العائلة
      (نفس فئة الثغرة اللي صلّحتها 0015 لجداول ثانية بس فاتت على هاد الجدول)، وأضفنا سياسة DELETE لولي
      الأمر ليقدر يسحب موافقته على تسجيله هو فقط.
      ما زال ناقص: نفس التدفق على تطبيق الويب (`/my` هناك للقراءة فقط بعد).
- [ ] `features/quran` (قارئ المصحف - لا تغيير جوهري، بيانات عالمية غير مرتبطة بمستأجر) - **مؤجّلة عمدًا**:
      عندنا بيانات نص/تلاوة جاهزة بقاعدة بيانات منفصلة، رح نرجعلها ونحدد مصدر البيانات (حزمة جاهزة أو API أو
      نقل من القاعدة الحالية) لما تجهز.
- [ ] `core/chat`, `core/calendar`, `core/notifications`, `core/offline`
- [x] العلامة التجارية الديناميكية: `Organization.primaryColorValue`/`.secondaryColorValue` (يحوّلوا الـ hex
      المخزّن بـ`organizations` إلى `Color`) يغذّوا `ThemeData` كامل التطبيق (`core/theme/app_theme.dart`،
      مبني بـ`ColorScheme.fromSeed` مع تثبيت `primary`/`secondary` الحرفيين)، فبيرجع يشتغل تلقائيًا بكل
      `FilledButton`/`TextButton` بدون لمس كل شاشة. الشعار (`logo_url`) يظهر بـ`OrgAvatar` (شعار حقيقي عبر
      `cached_network_image`، أو دائرة بأول حرف الاسم بلون المركز كـ fallback) بالـ drawer وشاشة اختيار
      المركز. أضفنا حقل تعديل رابط الشعار بـ`settings_screen` كمان - ما كان موجود أصلًا (حتى على الويب).
      ناقص: نفس حقل الشعار على تطبيق الويب (`/settings` هناك لسا بدون `logo_url`).

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
