/**
 * The platform's own privacy policy and terms (bustan-alquran.com/privacy, /terms): what the
 * product actually does with data, kept in step with the code. Arabic and English; the other
 * interface languages read the English. Each center also has its own short page
 * ({center}/privacy) in its name.
 */

export interface LegalDoc {
  title: string;
  updated: string;
  intro: string;
  sections: { heading: string; body: string[] }[];
}

const CONTACT = 'support@bustan-alquran.com';

export const privacy: Record<'ar' | 'en', LegalDoc> = {
  ar: {
    title: 'سياسة الخصوصية',
    updated: 'آخر تحديث: أكتوبر 2026',
    intro: 'بستان القرآن منصة لإدارة مراكز تحفيظ القرآن الكريم: موقع (bustan-alquran.com) وتطبيق جوال. توضّح هذه الصفحة البيانات التي نجمعها، وكيف نستخدمها ونحميها، وحقوقك فيها.',
    sections: [
      {
        heading: 'من المسؤول عن البيانات',
        body: [
          'كل مركز يستخدم المنصة هو المسؤول عن بيانات طلابه ومعلميه وأولياء الأمور فيه، ونحن نعالج هذه البيانات نيابة عنه ولتقديم الخدمة له فقط.',
          'بيانات حسابات مديري المراكز وبيانات الاشتراك نتحمّل نحن مسؤوليتها مباشرة.',
        ],
      },
      {
        heading: 'البيانات التي نجمعها',
        body: [
          'بيانات الحساب: الاسم، والبريد الإلكتروني أو رقم الدخول، وكلمة السر (مخزّنة مشفّرة لا نستطيع قراءتها). وعند الدخول بحساب Google: الاسم والبريد فقط.',
          'بيانات التعليم التي يدخلها المركز: أسماء الطلاب وأرقامهم وأرقام التواصل، والحلقات، والحضور، والتسميع والحفظ والمراجعة، والنقاط والشارات، والرسوم إن فعّلها المركز.',
          'التسجيلات الصوتية للتسميع التي يرسلها الطالب لمعلمه، والصور المرسلة في المحادثات.',
          'بيانات تقنية: رمز الإشعارات للجهاز، وتقارير الأعطال (دون محتوى شخصي) لإصلاح المشكلات.',
        ],
      },
      {
        heading: 'كيف نستخدمها',
        body: [
          'لتشغيل الخدمة للمركز فقط: متابعة الحفظ والحضور، وإرسال الإشعارات والتقارير لأصحابها، وفحص التسميع آليًا لمساعدة المعلم.',
          'لا نبيع البيانات، ولا نستخدمها للإعلانات، ولا نشاركها إلا مع مزوّدي الخدمة اللازمين لتشغيل المنصة.',
        ],
      },
      {
        heading: 'مزوّدو الخدمة',
        body: [
          'قاعدة البيانات والتخزين وتسجيل الدخول: Supabase.',
          'استضافة الموقع والفحص الآلي للتسميع: Cloudflare.',
          'إشعارات الجوال: Google Firebase.',
          'تسجيل الدخول بحساب Google لمن يختاره: Google.',
          'رسائل البريد (تأكيد الحساب وإعادة كلمة السر): Resend.',
        ],
      },
      {
        heading: 'الحماية والاحتفاظ',
        body: [
          'الاتصال مشفّر دائمًا (HTTPS)، وكل مركز معزول عن غيره في قاعدة البيانات، والنسخة المحفوظة على الجوال مشفّرة.',
          'التسجيلات الصوتية وصور المحادثات تُحذف تلقائيًا بعد المدة التي يحددها مدير المركز، وتبقى النتائج المكتوبة.',
          'عند حذف حساب أو مركز تُحذف بياناته وفق طلب الحذف.',
        ],
      },
      {
        heading: 'الأطفال',
        body: [
          'كثير من الطلاب أطفال، وتُنشأ حساباتهم من قبل مراكزهم لا من قبلهم. يتولى المركز الحصول على موافقة أولياء الأمور، والمنصة توفر له رابط موافقة وصفحة لطلب حذف البيانات.',
        ],
      },
      {
        heading: 'حقوقك',
        body: [
          'يمكنك طلب الاطلاع على بياناتك أو تصحيحها أو حذفها من مركزك، أو من صفحة «حذف الحساب» في موقع المركز والتطبيق.',
          `للأسئلة أو الطلبات: ${CONTACT}`,
        ],
      },
    ],
  },
  en: {
    title: 'Privacy Policy',
    updated: 'Last updated: October 2026',
    intro: 'Bustan Al-Quran is a platform for running Quran memorization centers: a website (bustan-alquran.com) and a mobile app. This page explains what data we collect, how we use and protect it, and your rights.',
    sections: [
      {
        heading: 'Who is responsible for the data',
        body: [
          'Each center using the platform is responsible for its students’, teachers’ and guardians’ data; we process it on the center’s behalf, only to provide the service to it.',
          'We are directly responsible for center administrators’ account data and subscription data.',
        ],
      },
      {
        heading: 'Data we collect',
        body: [
          'Account data: name, email or sign-in number, and password (stored hashed; we cannot read it). With Google sign-in: name and email only.',
          'Teaching data entered by the center: students’ names, numbers and contact numbers, circles, attendance, recitation, memorization and review, points and badges, and fees if the center turns them on.',
          'Recitation recordings a student sends to their teacher, and pictures sent in conversations.',
          'Technical data: the device’s notification token, and crash reports (without personal content) to fix problems.',
        ],
      },
      {
        heading: 'How we use it',
        body: [
          'Only to run the service for the center: following memorization and attendance, sending notifications and reports to the people concerned, and checking recitations automatically to help the teacher.',
          'We do not sell data, use it for advertising, or share it except with the service providers needed to run the platform.',
        ],
      },
      {
        heading: 'Service providers',
        body: [
          'Supabase (database, storage, sign-in), Cloudflare (website hosting and automatic recitation checks), Google Firebase (mobile notifications), Google (Google sign-in, for those who choose it) and Resend (email: account confirmation and password reset).',
        ],
      },
      {
        heading: 'Security and retention',
        body: [
          'Connections are always encrypted (HTTPS), each center is isolated from the others in the database, and the copy kept on the phone is encrypted.',
          'Recordings and chat pictures are deleted automatically after the period the center’s admin sets; the written results remain.',
          'When an account or a center is deleted, its data is deleted as requested.',
        ],
      },
      {
        heading: 'Children',
        body: [
          'Many students are children; their accounts are created by their centers, not by them. The center obtains guardians’ consent, and the platform gives it a consent link and a data-deletion request page.',
        ],
      },
      {
        heading: 'Your rights',
        body: [
          'You can ask to see, correct or delete your data through your center, or from the “Delete account” page on the center’s site and in the app.',
          `Questions or requests: ${CONTACT}`,
        ],
      },
    ],
  },
};

export const terms: Record<'ar' | 'en', LegalDoc> = {
  ar: {
    title: 'شروط الاستخدام',
    updated: 'آخر تحديث: أكتوبر 2026',
    intro: 'باستخدامك منصة بستان القرآن (الموقع والتطبيق) فأنت توافق على هذه الشروط.',
    sections: [
      {
        heading: 'الخدمة',
        body: ['منصة لإدارة مراكز تحفيظ القرآن الكريم: الطلاب والحلقات والحضور والتسميع والتواصل والتقارير. نعمل على استمرار الخدمة وتحسينها، وقد تتغيّر ميزاتها مع الوقت.'],
      },
      {
        heading: 'الحسابات',
        body: [
          'حافظ على سرية كلمة السر، وأنت مسؤول عما يتم من خلال حسابك.',
          'مدير المركز مسؤول عن الحسابات التي ينشئها لمعلميه وطلابه، وعن صحة بياناتهم والحصول على موافقة أولياء الأمور.',
        ],
      },
      {
        heading: 'الاستخدام المقبول',
        body: ['يُمنع استخدام المنصة لأي غرض مخالف للقانون أو للآداب، أو محاولة الوصول إلى بيانات مراكز أخرى، أو تعطيل الخدمة، أو إرسال محتوى مسيء.'],
      },
      {
        heading: 'المحتوى والبيانات',
        body: ['بيانات المركز ملك للمركز، ويمكنه تصديرها أو طلب حذفها. نعالجها لتقديم الخدمة فقط كما توضح سياسة الخصوصية.'],
      },
      {
        heading: 'الاشتراكات',
        body: ['بعض الخطط مدفوعة وفق الأسعار المعلنة. عند انتهاء الاشتراك قد تصبح البيانات للاطلاع فقط حتى التجديد، ولا تُحذف بسبب ذلك.'],
      },
      {
        heading: 'إيقاف الحساب',
        body: ['يحق لنا إيقاف حساب أو مركز يخالف هذه الشروط، بعد التنبيه متى أمكن.'],
      },
      {
        heading: 'حدود المسؤولية',
        body: ['تُقدَّم الخدمة «كما هي». الفحص الآلي للتسميع وسيلة مساعدة، والحكم فيه للمعلم. لا نتحمل مسؤولية الأضرار غير المباشرة الناتجة عن استخدام الخدمة.'],
      },
      {
        heading: 'التعديلات والتواصل',
        body: [`قد نعدّل هذه الشروط، ونعلن التعديلات المهمة في المنصة. للتواصل: ${CONTACT}`],
      },
    ],
  },
  en: {
    title: 'Terms of Use',
    updated: 'Last updated: October 2026',
    intro: 'By using the Bustan Al-Quran platform (website and app) you agree to these terms.',
    sections: [
      {
        heading: 'The service',
        body: ['A platform for running Quran memorization centers: students, circles, attendance, recitation, communication and reports. We work to keep the service running and improving; its features may change over time.'],
      },
      {
        heading: 'Accounts',
        body: [
          'Keep your password secret; you are responsible for what is done through your account.',
          'A center’s admin is responsible for the accounts they create for their teachers and students, for the accuracy of their data and for obtaining guardians’ consent.',
        ],
      },
      {
        heading: 'Acceptable use',
        body: ['Do not use the platform for anything unlawful or indecent, try to reach other centers’ data, disrupt the service, or send abusive content.'],
      },
      {
        heading: 'Content and data',
        body: ['A center’s data belongs to the center, which can export it or ask for it to be deleted. We process it only to provide the service, as the privacy policy explains.'],
      },
      {
        heading: 'Subscriptions',
        body: ['Some plans are paid at the published prices. When a subscription ends, the data may become read-only until renewal; it is not deleted because of that.'],
      },
      {
        heading: 'Suspension',
        body: ['We may suspend an account or a center that breaks these terms, after a warning where possible.'],
      },
      {
        heading: 'Limitation of liability',
        body: ['The service is provided “as is”. The automatic recitation check is an aid; the teacher’s judgment decides. We are not liable for indirect damages arising from the use of the service.'],
      },
      {
        heading: 'Changes and contact',
        body: [`We may change these terms and will announce important changes on the platform. Contact: ${CONTACT}`],
      },
    ],
  },
};
