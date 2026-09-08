// Replaces the legacy static index.html marketing page from
// wep-eqraa-center - but now markets the SaaS platform itself (sign up
// your center), not one specific center. A tenant's own public page (the
// old per-center "site_settings" concept) lives instead at
// app/(tenant)/[org]/(public)/page.tsx once built out.

export default function MarketingHomePage() {
  return (
    <main className="mx-auto flex min-h-screen max-w-3xl flex-col items-center justify-center gap-6 p-8 text-center">
      <h1 className="text-4xl font-bold text-brand">منصة إدارة مراكز تحفيظ القرآن</h1>
      <p className="text-lg text-gray-600">
        الحضور، الحلقات، السرد القرآني، النقاط والشارات، والتواصل مع أولياء الأمور - كل ذلك لمركزك،
        على منصة واحدة.
      </p>
      <a
        href="/signup"
        className="rounded-lg bg-brand px-6 py-3 font-semibold text-white transition hover:opacity-90"
      >
        سجّل مركزك الآن
      </a>
    </main>
  );
}
