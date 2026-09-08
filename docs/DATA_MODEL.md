# خريطة تحويل نموذج البيانات: من single-tenant إلى SaaS

جدول يربط كل جدول في المخطط الجديد بمصدره في مشروعي `eqraa_app` و `wep-eqraa-center` القديمين، مع أهم تغيير بنيوي (إن وجد).

| ملف الترحيل | الجداول | المصدر القديم | التغيير الجوهري |
|---|---|---|---|
| `0001_core_tenancy.sql` | `organizations`, `plans`, `subscriptions`, `platform_owners`, `organization_members`, `organization_invitations`, `account_admin_grants` | لا يوجد مكافئ مباشر (كان single-tenant) — `platform_owners` و `account_admin_grants` كانا موجودين لكن بدون مفهوم مستأجر | جداول جديدة كليًا تمثل جوهر التحول إلى SaaS |
| `0002_identity_academic_core.sql` | `profiles`, `stages`, `circles`, `students_profile` | نفس الأسماء تقريبًا | `profiles.role` (كان يخزَّن عالميًا) انتقل إلى `organization_members.role` |
| `0003_attendance_recitation.sql` | `attendance`, `attendance_gatherings(+entries)`, `daily_achievements`, `juz_reference`, `student_notes`, `serd_*` (5 جداول) | نفس الأسماء | `juz_reference` أصبح جدولًا عالميًا غير مرتبط بمستأجر (بيانات مرجعية موحّدة للقرآن) |
| `0004_engagement.sql` | `points_config`, `currency_config`, `badges`, `student_badges`, `student_wallets`, `market_items`, `market_purchases`, `circle_challenges(+entries)` | نفس الأسماء | لا تغيير جوهري بخلاف إضافة `organization_id` |
| `0005_communication.sql` | `chat_threads(+participants)`, `chat_messages`, `announcements`, `notification_templates`, `notification_log`, `notification_prefs`, `device_tokens` | نفس الأسماء | أُضيف `chat_thread_participants` كجدول صريح (كان ضمنيًا) لدعم عزل RLS للمحادثات |
| `0006_calendar_activities.sql` | `calendar_entry_types`, `center_calendar`, `calendar_registrations`, `activity_types`, `activities` | `center_calendar`, `calendar_entry_types`, `calendar_registrations`, `calendar_waitlist`, `activities`, `activity_types`, `gatherings` (موديول ويب) | **دُمج** `calendar_waitlist` داخل `calendar_registrations.status = 'waitlisted'` (تبسيط). **دُمج** موديول "gatherings" الإداري مع `attendance_gatherings` الموجود أصلًا في `0003` بدل تكرار مفهومين متطابقين |
| `0007_platform_and_admin.sql` | `feature_flags`, `account_access`, `deletion_requests`, `audit_log`, `site_settings` | نفس الأسماء، عدا `audit_log` (جديد — كان تسجيلًا مبعثرًا لكل موديول ويب على حدة، الآن جدول مركزي واحد) | — |

## أدوار قاعدة البيانات الأربعة الجديدة

| الدور | القديم | الجديد |
|---|---|---|
| `student` | `profiles.role = 'student'` | `organization_members.role = 'student'` |
| `teacher` | `profiles.role = 'teacher'` | `organization_members.role = 'teacher'` |
| `admin` | `profiles.role = 'admin'` | `organization_members.role = 'admin'` |
| `guardian` | غير رسمي (`requester_type` في `deletion_requests` فقط، وصفحات ويب `parent-consent`/`parent-progress` بدون حساب مستقل) | دور كامل، عضو في `organization_members`، مرتبط بالطالب عبر `students_profile.guardian_member_id` |

## اصطلاح RLS الموحّد

كل جدول تشغيلي (باستثناء الجداول المرجعية العالمية مثل `juz_reference`) يتبع:

```sql
alter table public.<table> enable row level security;

create policy "<table>_select_org" on public.<table>
  for select using (public.is_org_member(organization_id));

create policy "<table>_write_staff" on public.<table> for all
  using (public.is_org_staff(organization_id)) with check (public.is_org_staff(organization_id));
```

مع استثناءات موثّقة داخل كل ملف عندما يحتاج الجدول صلاحيات أدق (مثال: `deletion_requests` يسمح للمُرسِل بقراءة طلبه فقط، `student_notes` يكشف السجلات `guardian_visible` فقط لولي الأمر المرتبط).
