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
- [x] `features/auth` — تسجيل الدخول (شاشة موحدة لكل الأدوار، كباقي التطبيق) + `/signup` (تسجيل مركز جديد،
      يعادل `(marketing)/signup` بالويب: `auth.signUp` ثم `create_organization_with_owner` RPC بخطوة وحدة)
      + `/join` (قبول دعوة عبر كود). `/join` يختلف عمدًا عن `[org]/join` بالويب: الموبايل ما عنده توجيه
      نطاقات فرعية ولا deep links مُعدّة بعد، فبدل رابط قابل للنقر، الأدمن يشارك الـ token الخام كـ"كود دعوة"
      (زر مشاركة جديد بكل دعوة معلّقة بـ `members_list_screen` عبر `share_plus`) والمدعو يدخله يدويًا.
      نفس RPCs الويب (`get_invitation`/`accept_invitation`، migration 0011) بالضبط، بدون تغيير بقاعدة البيانات.
      ناقص لاحقًا: deep link حقيقي (`bustan-alquran://join?token=...`) بدل الإدخال اليدوي.
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
- [x] `core/chat`: تسليم رسائل فوري عبر Supabase Realtime (`core/chat/chat_realtime.dart`، Postgres Changes
      على `chat_messages` مفلترة بـ `thread_id`) بدل الاعتماد على إعادة الجلب بعد كل إرسال فقط. رسالتي أنا
      تُضاف محليًا فور نجاح الإدخال (استجابة فورية بالواجهة)، ورسائل الطرف التاني توصل عبر الاشتراك مباشرة.
      تطلّب migration (`0017_enable_chat_realtime.sql`) لإضافة `chat_messages` لـ publication
      `supabase_realtime` - بدونها الاشتراك ما كان رح يستقبل أي حدث بصمت. RLS الموجودة أصلًا
      (`chat_messages_select_participant`) تبقى تحكم مين يستقبل التغييرات، تمامًا متل select عادي.
      نفس الفجوة موجودة بالويب (`chat/actions.ts` لسا reload-after-send بس) - ما لمستها هون.
- [x] نقطة غير مقروءة بقائمة المحادثات (`chat_list_screen`): تطلّب migration
      (`0019_chat_read_tracking.sql`) لإضافة `last_read_at` على `chat_thread_participants` - ما كان موجود
      إطلاقًا. `chat_thread_screen` يحدّثه عند فتح المحادثة، وعند وصول كل رسالة جديدة وهي مفتوحة، وبعد إرسالي
      أنا لرسالة (وإلا كانت هاي المحادثة تظهر "غير مقروءة" عندي حتى وأنا اللي بعتها). ما احتاج تعديل RLS -
      `chat_participants_manage_self` (0005) أصلًا يسمح لعضو المحادثة يعدّل صفّه هو بس.
- [x] `core/calendar`: نفس معاملة `core/chat` - `calendar_realtime.dart` يشترك بتغييرات `center_calendar`
      (إدخال/تعديل/حذف، مش إدخال بس متل الشات) مفلترة بـ `organization_id`، و`calendar_list_screen` يعيد
      الجلب تلقائيًا عند أي تغيير بدل الاعتماد على pull يدوي فقط. تطلّب migration
      (`0018_enable_calendar_realtime.sql`): إضافة الجدول لـ publication `supabase_realtime` (متل 0017)،
      + `REPLICA IDENTITY FULL` على `center_calendar` تحديدًا - لأن فلترة أحداث الحذف بعمود غير العمود
      الأساسي (`organization_id`) بدون FULL ما بتوصل أصلًا (الـ WAL ما يحمل غير الـ primary key افتراضيًا).
- [x] `core/offline`: كاش قراءة بسيط (`offline_cache.dart`، جدول sqflite key→JSON) كبداية - مش عمل offline-first
      كامل: الشاشة تحاول القراءة الحيّة أولًا وتخزّنها بالكاش عند النجاح، وترجع لآخر نسخة محفوظة بس لو
      القراءة الحيّة فشلت (مافي اتصال). طبّقتها على `dashboard_screen` (أول شاشة يشوفها أي موظف) و`my_portal`
      (أول شاشة يشوفها أي طالب/ولي أمر) مع بانر "غير متصل" لما البيانات من الكاش. بـ`my_portal` تحديدًا ما
      خزّنت حالة الموافقة على الفعاليات (التسجيلات، عضوية ولي الأمر) - الموافقة أصلًا تحتاج اتصال لتنفّذ،
      فكاش يوهم إنها "متاحة" بدون نت كان رح يضلل. باقي الشاشات ممكن تتبع نفس النمط لاحقًا لو احتجنا.
- [ ] `core/notifications` - **مؤجّلة عمدًا**: push حقيقي (يوصل والتطبيق مسكّر) بيحتاج مشروع Firebase فعلي
      (`google-services.json`/`GoogleService-Info.plist`) مش موجودين بالريبو - رح نرجعلها لما يجهز.
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
