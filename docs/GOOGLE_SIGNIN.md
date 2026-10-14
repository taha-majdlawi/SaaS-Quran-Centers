# الدخول بحساب Google (للمعلمين والمدراء)

## كيف بيشتغل
- **صفحة الدخول بالمركز:** زر «الدخول بحساب Google»، مخصّص للمعلمين والمدراء.
  - حساب Google اللي بريده هو بريد معلم أو مدير بالمركز بيدخل **لنفس حسابه**، لأنه Supabase بيربط الاثنين تلقائيًا إذا البريد مؤكد.
  - أي حساب Google ثاني بينرفض برسالة واضحة. وإذا كان Google عامله حساب جديد لهالشخص، بينحذف فورًا، وهيك ما بيضل أثر لغرباء.
  - حساب الطالب بينرفض كمان، والطالب أصلًا بيدخل برقمه.
- **تسجيل مركز جديد:** بتكتب اسم المركز ورابطه، وبتضغط «التسجيل بحساب Google»، فبينعمل المركز وحساب Google بيكون مديره.
- **الدعوة:** المعلم أو المدير المدعو بيقدر يضغط «الانضمام بحساب Google».
- **الأزرار بتظهر لحالها بس لما Google يكون مفعّل بـSupabase.** قبل التفعيل ما بيظهر شي (الفحص بيتجدد كل 5 دقائق).
- **زر Google الرسمي على `bustan-alquran.com/google`** (Google Identity Services): صفحة دخول المركز، والدعوة، والتسجيل بيبعتوا الزائر لهالصفحة. نافذة Google بتكتب «المتابعة إلى bustan-alquran.com» بدل عنوان Supabase، وبعدها الدخول بيكمل بـSupabase (`signInWithIdToken` مع nonce). Google بيطلب كل دومين فيه زره يكون مسجّل عنده، وهيك كل المراكز بتمرّ من صفحة وحدة.
  - بيشتغل إذا `GOOGLE_CLIENT_ID` (`lib/auth/google-config.ts`) معبّى. إذا فاضي، منرجع للطريقة القديمة (التحويل عن طريق Supabase).
- **الكود:**
  - `lib/auth/google.ts`
  - `lib/auth/google-finish.ts`
  - `app/(marketing)/google`
  - `app/(tenant)/[org]/auth/callback`
  - `app/(marketing)/auth/callback`
  - `lib/auth/google-enabled.ts`

## الإعداد (مرة وحدة)

### 1. Google Cloud
1. افتح **console.cloud.google.com**، واعمل مشروع جديد باسم `Bustan Al-Quran`.
2. **Google Auth Platform ← Branding:**
   - App name: `بستان القرآن`
   - User support email: `support@bustan-alquran.com` (لازم يكون إيميل Gmail عندك صلاحية عليه، فاختار إيميلك من القائمة إذا ما قبل غيره)
   - App logo (اختياري)
   - Authorized domains: `bustan-alquran.com`
   - Developer contact: إيميلك
3. **Audience:** External، وبعدين **Publish app**. لأنه منطلب بس الاسم والبريد، ما بيحتاج مراجعة من Google.
4. **Clients ← Create client:**
   - Application type: **Web application**
   - Name: `Bustan web`
   - **Authorized JavaScript origins:** `https://bustan-alquran.com`
   - **Authorized redirect URIs:** الرابط اللي بيعطيك ياه Supabase بالخطوة 2 تحت (Callback URL)، وشكله: `https://<project>.supabase.co/auth/v1/callback`
5. انسخ **Client ID** و**Client Secret**. **لا تبعتهم بالمحادثة.**

### 2. Supabase
1. روح على **Authentication ← Sign In / Providers ← Google**، وفعّل **Enable**.
2. الصق Client ID وClient Secret.
3. انسخ **Callback URL** من نفس الصفحة، وحطه بـGoogle (الخطوة 1.4).
4. **Save**.
5. ضل **URL Configuration ← Redirect URLs** فيها `https://bustan-alquran.com/**` و`https://*.bustan-alquran.com/**`.

### 3. جرّب
- **معلم بريده Gmail:** افتح صفحة دخول مركزه ← «الدخول بحساب Google» ← لازم يفوت على لوحة المركز.
- **حساب Google غريب:** لازم تطلع رسالة «غير مسجّل في هذا المركز».

## ملاحظات
- بالطريقة القديمة (بدون Client ID بالكود)، Google بيكتب «للمتابعة إلى `<project>.supabase.co`». مع زر Google الرسمي بيكتب `bustan-alquran.com`، وبعد التحقق من العلامة (Branding ← Verify branding) بيكتب «بستان القرآن».
- بريد الدعم بشاشة Google لازم يكون حساب Google أو مجموعة Google انت بتديرها. عشان يصير `support@bustan-alquran.com`: اعمل حساب Google بنفس البريد (من «استخدام عنوان بريدك الإلكتروني الحالي»)، وأضفه للمشروع بـIAM كـOwner، فبيظهر بقائمة «User support email».
- إذا المعلم بريده مش Gmail (مثلًا Outlook)، بيضل يدخل بالبريد وكلمة السر.

## بالتطبيق (أندرويد)
- **زر «الدخول بحساب Google» بشاشة الدخول:** بيفتح قائمة حسابات Google على الجوال نفسه (بدون متصفح).
  - الـtoken مع nonce بيروح لـSupabase (`signInWithIdToken`).
  - بعدها التطبيق بيسأل الموقع (`/api/auth/google-check`) إذا الحساب معلم أو مدير بأي مركز. إذا لا، بيطلع منه، والحساب الغريب بينحذف.
- **الكود:** `apps/mobile/lib/features/auth/google_auth.dart`، والتطبيق بيستعمل الـClient ID تبع الويب كـ`serverClientId`.
- **الإعداد بـGoogle Cloud:** لازم تعمل Client من نوع **Android** لكل مفتاح توقيع.
  1. روح على **Clients ← Create client ← Android**.
  2. Package name: `com.bustanalquran.bustan_alquran_app`
  3. **SHA-1:** من مفتاح التوقيع، على اللابتوب:
     - مفتاح الإصدار: `keytool -list -v -keystore <ملف upload-keystore.jks> -alias upload`
     - للتجربة (debug): `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
     - إذا التطبيق على Google Play مع «App signing»: كمان الـSHA-1 من **Play Console ← App integrity**.
  4. ما في شي تحطه بالتطبيق أو بـSupabase من هالـClient. Google بيتعرّف على التطبيق من اسمه وبصمته.
- **الآيفون:** لسا مش مفعّل (بدها Client من نوع iOS، ورابط بـInfo.plist)، فالزر ما بيظهر هناك.
