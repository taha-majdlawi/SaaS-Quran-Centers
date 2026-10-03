# تطبيق الآيفون — البناء على Codemagic

الكود جاهز للآيفون: نفس تطبيق Flutter، ومعرّف الحزمة (Bundle ID) هو
`com.bustanalquran.bustanAlquranApp`. البناء يصير على Codemagic (أجهزة Mac)
من الملف `codemagic.yaml` بجذر المستودع، وفيه مساران:

| المسار | شو بيعمل | بده حساب أبل؟ |
|---|---|---|
| `ios-check` | يبني التطبيق بدون توقيع — يتأكد إن الكود بيترجم على iOS | لا |
| `ios-testflight` | يوقّع بحسابك ويرفع على TestFlight | نعم |

> ⚠️ المفاتيح والملفات السرية (مفتاح API، الشهادات) توضع في Codemagic نفسه فقط — لا في
> المستودع ولا في أي محادثة.

## مرة واحدة: حساب أبل

1. **Apple Developer → Certificates, IDs & Profiles → Identifiers → +**
   - App IDs → App → Bundle ID (Explicit): `com.bustanalquran.bustanAlquranApp`
   - إذا بدك إشعارات الجوال الفورية: فعّل **Push Notifications** هون.
2. **App Store Connect → Apps → +** تطبيق جديد بنفس الـ Bundle ID، الاسم «بستان القرآن».
   بعد الإنشاء: App Information → **Apple ID** (رقم) — بنحطه بالملف تحت.
3. **App Store Connect → Users and Access → Integrations → App Store Connect API → +**
   مفتاح جديد بصلاحية **App Manager**. نزّل ملف `.p8` (بينزل مرة وحدة بس)، واحفظ
   **Issuer ID** و **Key ID**.

## مرة واحدة: Codemagic

1. سجّل دخول على codemagic.io بحساب GitHub، و **Add application** → المستودع
   `SaaS-Quran-Centers` → نوع المشروع Flutter → اختر **codemagic.yaml**.
2. **Team settings → Integrations → Developer Portal → Connect**:
   الاسم بالضبط `Bustan App Store Connect`، وارفع ملف `.p8` مع Issuer ID و Key ID.
3. **Team settings → codemagic.yaml settings → Code signing identities**:
   - تبويب iOS certificates → **Generate certificate** (نوع Apple Distribution) — بيعمله من حسابك.
   - تبويب iOS provisioning profiles → **Fetch profiles** واختر بروفايل App Store للـ Bundle ID.
4. بالملف `codemagic.yaml` غيّر `APP_STORE_APPLE_ID: "0000000000"` لرقم التطبيق من الخطوة 2 فوق
   (هذا الرقم مش سري).

## البناء

1. شغّل **ios-check** أول مرة — إذا نجح فالكود سليم على iOS.
2. شغّل **ios-testflight** — بيبني ويوقّع ويرفع، وبعد ربع ساعة تقريبًا بيظهر في
   TestFlight. رقم البناء بيزيد تلقائيًا عن آخر رقم على TestFlight.
3. على الآيفون: تطبيق **TestFlight** → التطبيق بيظهر لحسابك → تثبيت.

## إشعارات الجوال الفورية (اختياري)

بدونها التطبيق بيشتغل عادي والإشعارات بتظهر داخله بس.

1. Apple Developer → Keys → + → **Apple Push Notifications service (APNs)** → نزّل الـ `.p8`.
2. Firebase (نفس مشروع أندرويد) → Project settings → **Add app → iOS** بنفس الـ Bundle ID.
   ثم Cloud Messaging → Apple app configuration → ارفع مفتاح APNs (مع Key ID و Team ID).
3. من إعدادات تطبيق iOS في Firebase خذ: `API_KEY`، `GOOGLE_APP_ID`، `GCM_SENDER_ID`، `PROJECT_ID`.
4. Codemagic → التطبيق → **Environment variables** → مجموعة جديدة اسمها `firebase_ios` فيها:
   `FIREBASE_IOS_API_KEY`، `FIREBASE_IOS_APP_ID`، `FIREBASE_MESSAGING_SENDER_ID`، `FIREBASE_PROJECT_ID`.
5. بالملف `codemagic.yaml` شيل علامة `#` عن سطري `groups:` و `- firebase_ios`.

الكود بيقرأ هالقيم وقت البناء (`--dart-define`) فما في ملف لازم ينضاف لمشروع Xcode،
وصلاحية Push بتنضاف للتوقيع بس لما المجموعة موجودة.

## ملاحظات تقنية

- أقل نسخة iOS: 15.0. ملف `Podfile` بيتولّد تلقائيًا وقت البناء (ما في داعي نحفظه بالمستودع).
- `Info.plist`: نصوص إذن الكاميرا والصور (للمحادثة وشعار المركز)، اللغات الأربع،
  و `ITSAppUsesNonExemptEncryption = false` (ما بيسألك أسئلة التشفير مع كل رفع).
- الإشعار على الآيفون وهو مفتوح بيعرضه النظام نفسه؛ الخادم بيبعت صوت افتراضي للآيفون (apns).
- الجهاز بيتسجل بالخادم بنوع `ios` (جدول `device_tokens`).
