# guardian_dashboard (جديد)

لا يوجد له نظير مباشر في `eqraa_app` — النظام القديم كان يخدم أولياء الأمور فقط عبر صفحات ويب منفصلة وثابتة (`parent-consent/`, `parent-consent/progress.html` في wep-eqraa-center) بدون حساب حقيقي أو تطبيق موبايل.

مع إضافة دور `guardian` كعضوية كاملة في `organization_members` (انظر `docs/DATA_MODEL.md`)، هذه الميزة تحتاج:

- شاشة تسجيل دخول/ربط بأبناء متعددين (طالب واحد قد يكون له أكثر من ولي أمر، وولي الأمر قد يكون له أكثر من طالب/مركز).
- عرض تقدم القراءة (`daily_achievements`, `serd_sessions`) للقراءة فقط.
- موافقة على فعاليات التقويم التي تتطلب موافقة ولي أمر (`center_calendar.requires_guardian_consent`) - يعادل صفحة `trip-consent/` القديمة.
- عرض/رد على إشعارات الطالب (`notification_log` مفلترة).

مرجع تصميم واجهة إضافي: `student_dashboard` (بنية مشابهة، لكن للقراءة فقط في أغلب الشاشات).
