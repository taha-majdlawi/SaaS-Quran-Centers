# بستان القرآن (Bustan Al-Quran)

هيكلية أساسية (سكيلتون كود فعلي) لـ **بستان القرآن** — منصة SaaS متعددة المستأجرين (multi-tenant) تجمع كل مميزات منتج "اقرأ" الحالي — تطبيق الموبايل [`eqraa_app`](E:\FLUTTER%20PROJECTS\eqraa_app) ولوحة الويب [`wep-eqraa-center`](C:\Users\hp\Desktop\wep-eqraa-center) — في قاعدة كود ومنصة واحدة تخدم عدة مراكز، بدل نشر منفصل كامل لكل عميل كما هو الحال اليوم.

اقرأ [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) أولًا — يشرح كل قرار معماري ولماذا.

## البنية

```
supabase/               مخطط قاعدة البيانات متعدد المستأجرين (المصدر الوحيد للحقيقة)
  migrations/            7 ملفات SQL مرتبة: tenancy → identity → attendance/recitation
                          → engagement → communication → calendar → platform/admin
  seed.sql               بيانات تجريبية للتطوير المحلي (مركز "demo" + أجزاء القرآن الـ30)

apps/
  mobile/                تطبيق Flutter (يعيد استخدام أنماط eqraa_app + طبقة tenant جديدة)
  web/                   تطبيق Next.js واحد: تسويق + لوحة مالك المنصة + لوحات كل المراكز

docs/
  ARCHITECTURE.md         القرارات المعمارية (tenancy, الأدوار, تدفق الطلب)
  DATA_MODEL.md            خريطة تحويل كل جدول من النظام القديم للجديد
  MIGRATION_FROM_EQRAA.md  قائمة تتبع نقل كل ميزة من المشروعين الحاليين
```

## أهم قرار: تعدد المستأجرين

النظام الحالي (كلا المشروعين) **single-tenant بالكامل**: كل مركز = مشروع Supabase منفصل + بناء تطبيق منفصل بعلامة تجارية خاصة. هذا يمنعه من كونه SaaS فعليًا. القرار هنا: **قاعدة بيانات واحدة، عزل بيانات كامل عبر `organization_id` + Row Level Security**، بحيث نفس الكود (تطبيق موبايل واحد، تطبيق ويب واحد) يخدم كل عميل جديد بدون أي نشر إضافي. التفاصيل الكاملة في `docs/ARCHITECTURE.md` §1.

## البدء

```bash
# 1) قاعدة البيانات (يتطلب Supabase CLI)
supabase start
supabase db reset   # يطبّق كل الترحيلات + seed.sql

# 2) تطبيق الويب
cd apps/web && npm install && cp .env.example .env.local
npm run dev

# 3) تطبيق الموبايل
cd apps/mobile && flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## الحالة الحالية

هذا سكيلتون هيكلي: المخطط، سياسات RLS، التوجيه متعدد المستأجرين، وبنية المجلدات جاهزة وقابلة للتشغيل. منطق كل ميزة (شاشات، نماذج، تقارير) لم يُنقل بعد من المشروعين الأصليين — راجع `docs/MIGRATION_FROM_EQRAA.md` لقائمة تتبع النقل.
