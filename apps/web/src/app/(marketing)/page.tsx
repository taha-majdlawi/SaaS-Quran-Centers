// Replaces the legacy static index.html marketing page from
// wep-eqraa-center - but now markets the SaaS platform itself (sign up
// your center), not one specific center. A tenant's own public page (the
// old per-center "site_settings" concept) lives instead at
// app/(tenant)/[org]/(public)/page.tsx once built out.

const STEPS = [
  {
    title: '1. سجّل مركزك',
    body: 'اسم مركزك ورابط خاص به - دقيقة واحدة، وحسابك جاهز كمدير له.',
  },
  {
    title: '2. جهّز بياناته',
    body: 'أضف المعلمين والمراحل والحلقات، واضبط النقاط والشارات كما يناسب مركزك.',
  },
  {
    title: '3. تحكّم بكل شيء',
    body: 'الحضور، التسميع، التواصل مع أولياء الأمور - كل ذلك من لوحة واحدة أنت المتحكم بها بالكامل.',
  },
];

export default function MarketingHomePage() {
  return (
    <div className="min-h-screen bg-white">
      <header className="flex items-center justify-between border-b px-6 py-4">
        <span className="text-lg font-bold text-brand">بستان القرآن</span>
        <nav className="flex items-center gap-4 text-sm">
          <a href="/login" className="text-gray-600 hover:text-brand">
            تسجيل الدخول
          </a>
          <a href="/signup" className="rounded-lg bg-brand px-4 py-2 font-semibold text-white hover:opacity-90">
            سجّل مركزك
          </a>
        </nav>
      </header>

      <main className="mx-auto flex max-w-3xl flex-col items-center gap-6 px-8 py-20 text-center">
        <h1 className="text-4xl font-bold text-brand">بستان القرآن</h1>
        <p className="text-lg text-gray-600">
          منصة إدارة مراكز تحفيظ القرآن الكريم — سجّل مركزك، وابدأ بالتحكم الكامل بمعلميك وطلابك وحلقاتك من
          لوحة واحدة، بدون أي تعقيد تقني.
        </p>
        <a
          href="/signup"
          className="rounded-lg bg-brand px-6 py-3 font-semibold text-white transition hover:opacity-90"
        >
          سجّل مركزك الآن
        </a>

        <div className="mt-12 grid gap-6 text-right sm:grid-cols-3">
          {STEPS.map((step) => (
            <div key={step.title} className="rounded-xl border border-gray-100 p-5">
              <h2 className="mb-2 font-bold text-brand">{step.title}</h2>
              <p className="text-sm text-gray-600">{step.body}</p>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
