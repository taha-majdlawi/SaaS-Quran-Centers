# الدخول بحساب Google (للمعلمين والمدراء)

## كيف بيشتغل
- **صفحة الدخول بالمركز:** زر «الدخول بحساب Google»، مخصّص للمعلمين والمدراء.
  - حساب Google اللي بريده هو بريد معلم أو مدير بالمركز بيدخل **لنفس حسابه**، لأنه Supabase بيربط الاثنين تلقائيًا إذا البريد مؤكد.
  - أي حساب Google ثاني بينرفض برسالة واضحة. وإذا كان Google عامله حساب جديد لهالشخص، بينحذف فورًا، وهيك ما بيضل أثر لغرباء.
  - حساب الطالب بينرفض كمان، والطالب أصلًا بيدخل برقمه.
- **تسجيل مركز جديد:** بتكتب اسم المركز ورابطه، وبتضغط «التسجيل بحساب Google»، فبينعمل المركز وحساب Google بيكون مديره.
- **الدعوة:** المعلم أو المدير المدعو بيقدر يضغط «الانضمام بحساب Google».
- **الأزرار بتظهر لحالها بس لما Google يكون مفعّل بـSupabase.** قبل التفعيل ما بيظهر شي (الفحص بيتجدد كل 5 دقائق).
- **الكود:**
  - `lib/auth/google.ts`
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
- شاشة Google بتكتب «للمتابعة إلى `<project>.supabase.co`». إذا بدك تظهر `bustan-alquran.com` بدالها، هاد بيحتاج «Custom Domain» بـSupabase، وهي ميزة مدفوعة.
- إذا المعلم بريده مش Gmail (مثلًا Outlook)، بيضل يدخل بالبريد وكلمة السر.
