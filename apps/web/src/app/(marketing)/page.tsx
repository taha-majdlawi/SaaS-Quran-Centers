import { GrowingTree } from '@/components/growing-tree';
import type { Metadata } from 'next';
import { getI18n } from '@/lib/i18n/server';
import { LanguageSwitcher } from '@/lib/i18n/client';
import { LOCALES, fmt } from '@/lib/i18n/config';
import { createClient } from '@/lib/supabase/server';
import { QuranFont } from '@/components/quran-font';
import { RevealOnScroll } from '@/components/reveal-on-scroll';
import {
  Award,
  BarChart3,
  Bell,
  BookOpen,
  BookOpenCheck,
  Check,
  ClipboardCheck,
  Globe,
  GraduationCap,
  Handshake,
  HeartHandshake,
  Landmark,
  LayoutDashboard,
  Leaf,
  Lock,
  type LucideIcon,
  MapPin,
  Plus,
  Smartphone,
  Sprout,
  Star,
  TreeDeciduous,
  Trees,
  Users,
} from 'lucide-react';

// The page's icons - line icons in the brand colour (the texts name them by key).
const ICONS: Record<string, LucideIcon> = {
  book: BookOpen, attendance: ClipboardCheck, award: Award, family: Users, phone: Smartphone, chart: BarChart3, bell: Bell,
  globe: Globe, admin: LayoutDashboard, teacher: GraduationCap, student: BookOpenCheck, guardian: HeartHandshake,
  sprout: Sprout, leaf: Leaf, tree: TreeDeciduous, trees: Trees, lock: Lock, landmark: Landmark, handshake: Handshake, star: Star,
};
function Icon({ name, size = 22, className = '' }: { name: string; size?: number; className?: string }) {
  const C = ICONS[name] ?? BookOpen;
  return <C size={size} strokeWidth={1.75} className={className} aria-hidden />;
}

// The platform's own marketing page (a center's public page lives at
// app/(tenant)/[org]/page.tsx). Written in the platform's garden voice:
// بذرة -> غرسة -> شجرة -> بستان. Plan prices come live from public_plans()
// (0068), so they always match what the owner set in the console.

// search engines index every language version (?lang= also renders directly in it)
export const metadata: Metadata = {
  alternates: { languages: Object.fromEntries(LOCALES.map((l) => [l, `/?lang=${l}`])) },
};

interface PublicPlan {
  code: string;
  name: string;
  price_cents: number;
  yearly_price_cents: number | null;
  currency: string;
  max_students: number | null;
  max_teachers: number | null;
}

const price = (cents: number, currency: string) =>
  currency === 'USD' ? `$${(cents / 100).toLocaleString('en-US', { maximumFractionDigits: 2 })}` : `${(cents / 100).toLocaleString('en-US')} ${currency}`;

const container = 'mx-auto w-full max-w-6xl px-5 sm:px-8';

export default async function MarketingHomePage() {
  const { t, locale } = await getI18n();
  const m = t.marketing;
  const supabase = await createClient();
  const { data } = await supabase.rpc('public_plans');
  const plans = (data ?? []) as PublicPlan[];

  return (
    <div className="relative isolate min-h-screen overflow-x-hidden text-gray-800">
      {/* the photo stays put behind the whole page; the sections scroll over it */}
      <div aria-hidden className="fixed inset-0 -z-10 bg-[#5a1414]">
        <picture>
          <source media="(min-width: 1024px)" srcSet="/marketing/hero-wide.webp" type="image/webp" />
          <source media="(min-width: 1024px)" srcSet="/marketing/hero-wide.jpg" />
          <source srcSet="/marketing/hero-phone.webp" type="image/webp" />
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/marketing/hero-phone.jpg"
            alt=""
            fetchPriority="high"
            decoding="async"
            className="ken-burns h-full w-full object-cover object-[50%_30%] lg:object-[15%_50%]"
          />
        </picture>
      </div>
      <span className="sr-only">{m.heroImageAlt}</span>
      <RevealOnScroll />
      <GrowingTree />
      {/* header */}
      <header className="sticky top-0 z-20 border-b border-black/5 bg-[#FBFAF6]/90 backdrop-blur">
        <div className={`${container} flex items-center justify-between gap-3 py-3`}>
          <a href="/" className="flex items-center gap-2">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/icons/icon-192.png" alt="" width={36} height={36} className="rounded-lg" />
            <span className="whitespace-nowrap text-lg font-bold text-brand">{t.common.brand}</span>
          </a>
          <nav className="hidden items-center gap-6 text-sm text-gray-600 md:flex">
            <a href="#features" className="link-underline hover:text-brand">{m.nav.features}</a>
            <a href="#how" className="link-underline hover:text-brand">{m.nav.how}</a>
            <a href="#pricing" className="link-underline hover:text-brand">{m.nav.pricing}</a>
            <a href="#faq" className="link-underline hover:text-brand">{m.nav.faq}</a>
          </nav>
          <div className="flex items-center gap-3 text-sm">
            <LanguageSwitcher />
            <a href="/login" className="whitespace-nowrap text-gray-600 hover:text-brand">
              {t.common.login}
            </a>
            <a href="/signup" className="hidden whitespace-nowrap rounded-md bg-brand px-4 py-2 font-semibold text-white hover:bg-brand/90 sm:inline-block">
              {t.common.registerCenter}
            </a>
          </div>
        </div>
      </header>

      <main>
        {/* hero: a teacher hearing his student, the photo filling the screen */}
        {/* phones: the photo, then the words on the page colour; wide screens: the words over the photo */}
        <section className="relative">
          {/* phones: the photo shows through this space, with where it was taken */}
          <div className="relative h-[62svh] lg:hidden">
            <p className="absolute bottom-3 right-3 max-w-[85%] rounded-full bg-black/55 px-3 py-1 text-[11px] text-white">
              <MapPin size={12} className="-mt-0.5 me-1 inline" aria-hidden />
              {m.heroImageCaption}
            </p>
          </div>
          <p className="absolute bottom-5 right-6 z-10 hidden rounded-full bg-black/55 px-3 py-1 text-xs text-white lg:block">
            <MapPin size={12} className="-mt-0.5 me-1 inline" aria-hidden />
            {m.heroImageCaption}
          </p>
          {/* shade only behind the words (right on wide screens); the two people on the left stay bright */}
          <div aria-hidden className="pointer-events-none absolute inset-0 -z-0 hidden bg-[linear-gradient(to_left,rgba(28,10,26,0.82)_0%,rgba(28,10,26,0.62)_26%,rgba(28,10,26,0.22)_44%,transparent_56%)] lg:block" />
          <div aria-hidden className="pointer-events-none absolute inset-x-0 bottom-0 hidden h-24 bg-gradient-to-t from-black/25 to-transparent lg:block" />

          <div className="bg-[#FBFAF6] lg:bg-transparent">
          <div className={`${container} relative lg:flex lg:min-h-[calc(100svh-4rem)] lg:items-center`}>
            {/* the words keep to the right, over the carpet, so the two people stay clear on the left */}
            <div className="flex flex-col items-start gap-5 py-10 lg:ml-auto lg:max-w-[min(32rem,38vw)] lg:py-20 lg:text-white">
              <span style={{ '--d': '80ms' } as React.CSSProperties} className="hero-in border-s-2 border-brand ps-3 text-sm font-semibold text-brand lg:border-white/70 lg:text-white/90">{m.badge}</span>
              <h1 style={{ '--d': '180ms' } as React.CSSProperties} className="hero-in text-4xl font-extrabold leading-tight text-gray-900 sm:text-5xl sm:leading-tight lg:text-white lg:drop-shadow-[0_2px_12px_rgba(0,0,0,0.45)]">
                {m.heroTitle}
              </h1>
              <p style={{ '--d': '300ms' } as React.CSSProperties} className="hero-in text-lg leading-8 text-gray-600 lg:text-white/90 lg:drop-shadow-[0_1px_6px_rgba(0,0,0,0.5)]">{m.heroBody}</p>
              <div style={{ '--d': '420ms' } as React.CSSProperties} className="hero-in flex flex-wrap gap-3">
                <a href="/signup" className="rounded-md bg-brand px-6 py-3 text-base font-bold text-white transition hover:bg-brand/90">
                  {m.ctaPrimary}
                </a>
                <a href="/login" className="rounded-md border border-gray-300 bg-white px-6 py-3 text-base font-semibold text-gray-800 transition hover:border-gray-500 lg:border-white/70 lg:bg-transparent lg:text-white lg:hover:bg-white/10">
                  {m.ctaSecondary}
                </a>
              </div>
              <p style={{ '--d': '520ms' } as React.CSSProperties} className="hero-in text-sm text-gray-500 lg:text-white/75">{m.heroNote}</p>
            </div>
          </div>
          </div>
        </section>

        {/* everything below passes over the photo: a light veil lets it show faintly through */}
        <div className="bg-[#FBFAF6]/[0.86]">

        {/* the product, right under the photo */}
        <section className="relative">
          <div className={`${container} relative py-14 md:py-20`}>
            <div data-reveal className="mx-auto max-w-3xl">
              <DashboardPreview m={m} />
            </div>
          </div>
        </section>

        {/* verse */}
        <section className="border-y border-black/10 bg-white/70">
          <QuranFont>
            <div data-reveal className={`${container} flex flex-col items-center gap-2 py-10 text-center`}>
              <p dir="rtl" lang="ar" className="font-quran text-2xl leading-[2.4] text-ink sm:text-3xl">
                {m.verse}
              </p>
              <p className="mt-3 text-sm text-gray-500">{m.verseRef}</p>
            </div>
          </QuranFont>
        </section>

        {/* features */}
        <section id="features" className={`${container} scroll-mt-20 py-20`}>
          <SectionHead title={m.featuresTitle} body={m.featuresBody} />
          <div className="grid gap-x-10 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
            {m.features.map((f, i) => (
              <div key={f.title} data-reveal style={{ '--d': `${(i % 4) * 90}ms` } as React.CSSProperties} className="border-t border-black/15 pt-5">
                <h3 className="mb-2 flex items-center gap-2 font-bold text-gray-900">
                  <Icon name={f.icon} size={18} className="shrink-0 text-brand" />
                  {f.title}
                </h3>
                <p className="text-sm leading-7 text-gray-600">{f.body}</p>
              </div>
            ))}
          </div>
        </section>

        {/* roles */}
        <section className="border-y border-black/10 bg-white/60 py-20">
          <div className={container}>
            <SectionHead title={m.rolesTitle} />
            <div className="grid gap-x-10 gap-y-8 sm:grid-cols-2 lg:grid-cols-4">
              {m.roles.map((r, i) => (
                <div key={r.title} data-reveal style={{ '--d': `${i * 90}ms` } as React.CSSProperties} className="border-t border-black/15 pt-5">
                  <Icon name={r.icon} size={22} className="mb-3 text-brand" />
                  <h3 className="mb-2 text-lg font-bold text-gray-900">{r.title}</h3>
                  <p className="text-sm leading-7 text-gray-600">{r.body}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* how it works */}
        <section id="how" className={`${container} scroll-mt-20 py-20`}>
          <SectionHead title={m.stepsTitle} />
          <ol className="grid gap-x-10 gap-y-8 md:grid-cols-3">
            {m.steps.map((s, i) => (
              <li key={s.title} data-reveal style={{ '--d': `${i * 120}ms` } as React.CSSProperties} className="border-t-2 border-gray-900 pt-5">
                <span className="mb-3 block text-sm font-bold tabular-nums text-gray-400">{String(i + 1).padStart(2, '0')}</span>
                <h3 className="mb-2 text-xl font-bold text-gray-900">{s.title}</h3>
                <p className="text-sm leading-7 text-gray-600">{s.body}</p>
              </li>
            ))}
          </ol>
        </section>

        {/* pricing */}
        {plans.length > 0 && (
          <section id="pricing" className="scroll-mt-20 border-y border-black/10 bg-white/60 py-20">
            <div className={container}>
              <SectionHead title={m.pricingTitle} body={m.pricingBody} />
              <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
                {plans.map((p, i) => {
                  const stage = m.stages[Math.min(i, m.stages.length - 1)];
                  const highlight = i === 1;
                  const free = p.price_cents === 0;
                  const save = p.yearly_price_cents != null && p.price_cents > 0 ? Math.round((1 - p.yearly_price_cents / (p.price_cents * 12)) * 100) : 0;
                  return (
                    <div
                      key={p.code}
                      data-reveal
                      style={{ '--d': `${i * 90}ms` } as React.CSSProperties}
                      className={`relative flex flex-col rounded-lg border bg-white p-6 ${highlight ? 'border-brand ring-1 ring-brand' : 'border-black/15'}`}
                    >
                      {highlight && (
                        <span className="mb-3 text-xs font-bold text-brand">{m.recommended}</span>
                      )}
                      <Icon name={stage.icon} size={22} className="mb-3 text-brand" />
                      <h3 className="text-2xl font-extrabold text-gray-900">{locale === 'ar' ? p.name : stage.name}</h3>
                      <p className="mt-1 min-h-[3rem] text-sm text-gray-500">{stage.tagline}</p>
                      <div className="my-5">
                        {free ? (
                          <p className="text-3xl font-extrabold text-brand">{m.free}</p>
                        ) : (
                          <>
                            <p>
                              <span dir="ltr" className="text-3xl font-extrabold text-gray-900">
                                {price(p.price_cents, p.currency)}
                              </span>{' '}
                              <span className="text-sm text-gray-500">{m.perMonth}</span>
                            </p>
                            {p.yearly_price_cents != null && save > 0 && (
                              <p className="mt-1 text-xs font-semibold text-gray-600">{fmt(m.perYear, { price: price(p.yearly_price_cents, p.currency), pct: save })}</p>
                            )}
                          </>
                        )}
                      </div>
                      <ul className="mb-6 flex flex-col gap-2 text-sm text-gray-700">
                        <li className="flex items-start gap-2"><Check size={16} className="mt-0.5 shrink-0 text-brand" aria-hidden />{p.max_students != null ? fmt(m.students, { n: p.max_students }) : m.unlimitedStudents}</li>
                        <li className="flex items-start gap-2"><Check size={16} className="mt-0.5 shrink-0 text-brand" aria-hidden />{p.max_teachers != null ? fmt(m.teachers, { n: p.max_teachers }) : m.unlimitedTeachers}</li>
                        <li className="flex items-start gap-2"><Check size={16} className="mt-0.5 shrink-0 text-brand" aria-hidden />{m.allFeatures}</li>
                      </ul>
                      <a
                        href="/signup"
                        className={`mt-auto rounded-md px-4 py-2.5 text-center text-sm font-bold transition ${highlight ? 'bg-brand text-white hover:bg-brand/90' : 'border border-gray-300 text-gray-800 hover:border-gray-500'}`}
                      >
                        {stage.cta}
                      </a>
                    </div>
                  );
                })}
              </div>
            </div>
          </section>
        )}

        {/* trust */}
        <section className={`${container} py-20`}>
          <SectionHead title={m.trustTitle} />
          <div className="grid gap-x-10 gap-y-8 md:grid-cols-3">
            {m.trust.map((x, i) => (
              <div key={x.title} data-reveal style={{ '--d': `${i * 100}ms` } as React.CSSProperties} className="flex gap-3 border-t border-black/15 pt-5">
                <Icon name={x.icon} size={20} className="mt-0.5 shrink-0 text-brand" />
                <div>
                  <h3 className="mb-1 font-bold text-gray-900">{x.title}</h3>
                  <p className="text-sm leading-7 text-gray-600">{x.body}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* faq */}
        <section id="faq" className="scroll-mt-20 border-y border-black/10 bg-white/60 py-20">
          <div className="mx-auto max-w-3xl px-5 sm:px-8">
            <SectionHead title={m.faqTitle} />
            <div className="flex flex-col border-b border-black/15">
              {m.faq.map((f, i) => (
                <details key={f.q} data-reveal style={{ '--d': `${i * 70}ms` } as React.CSSProperties} className="group border-t border-black/15 py-5">
                  <summary className="flex cursor-pointer list-none items-center justify-between gap-4 font-bold text-gray-900">
                    {f.q}
                    <Plus size={18} className="shrink-0 text-gray-500 transition group-open:rotate-45" aria-hidden />
                  </summary>
                  <p className="mt-3 text-sm leading-7 text-gray-600">{f.a}</p>
                </details>
              ))}
            </div>
          </div>
        </section>

        {/* final call */}
        <section className={`${container} py-20`}>
          <div data-reveal className="flex flex-col items-start gap-6 border-t-2 border-gray-900 pt-10 md:flex-row md:items-end md:justify-between">
            <div className="max-w-2xl">
              <h2 className="text-3xl font-extrabold leading-snug text-gray-900 sm:text-4xl">{m.finalTitle}</h2>
              <p className="mt-4 leading-8 text-gray-600">{m.finalBody}</p>
            </div>
            <a href="/signup" className="shrink-0 rounded-md bg-brand px-7 py-3.5 font-bold text-white transition hover:bg-brand/90">
              {m.ctaPrimary}
            </a>
          </div>
        </section>
        </div>
      </main>

      <footer className="border-t border-black/5 bg-[#FBFAF6]/[0.94]">
        <div className={`${container} flex flex-col items-center justify-between gap-3 py-8 text-sm text-gray-500 sm:flex-row`}>
          <span>{m.footer}</span>
          <div className="flex gap-4">
            <a href="/login" className="hover:text-brand">{t.common.login}</a>
            <a href="/signup" className="hover:text-brand">{t.common.registerCenter}</a>
            <a href="/privacy" className="hover:text-brand">{locale === 'ar' ? 'الخصوصية' : 'Privacy'}</a>
            <a href="/terms" className="hover:text-brand">{locale === 'ar' ? 'الشروط' : 'Terms'}</a>
          </div>
        </div>
      </footer>
    </div>
  );
}

function SectionHead({ title, body }: { title: string; body?: string }) {
  return (
    <div data-reveal className="mb-10 max-w-2xl">
      <h2 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">{title}</h2>
      {body && <p className="mt-3 leading-8 text-gray-600">{body}</p>}
    </div>
  );
}

/** A static illustration of a center's day - not live data. */
function DashboardPreview({ m }: { m: Awaited<ReturnType<typeof getI18n>>['t']['marketing'] }) {
  return (
    <div aria-hidden className="relative mx-auto w-full max-w-md">
      <div className="relative rounded-xl border border-black/15 bg-white p-5 shadow-sm">
        <div className="mb-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/icons/icon-192.png" alt="" width={32} height={32} className="rounded-md" />
            <span className="text-sm font-bold text-gray-900">{m.preview.center}</span>
          </div>
          <span className="text-xs font-semibold text-gray-500">{m.preview.today}</span>
        </div>
        <div className="mb-4 grid grid-cols-3 gap-2">
          {m.preview.stats.map((s) => (
            <div key={s.label} className="rounded-md border border-black/10 p-3 text-center">
              <p className="text-xl font-extrabold text-gray-900">{s.value}</p>
              <p className="text-[11px] text-gray-500">{s.label}</p>
            </div>
          ))}
        </div>
        <ul className="flex flex-col gap-2">
          {m.preview.rows.map((r) => (
            <li key={r.name} className="flex items-center justify-between rounded-md border border-black/10 px-3 py-2.5">
              <div>
                <p className="text-sm font-semibold text-gray-900">{r.name}</p>
                <p className="text-xs text-gray-500">{r.detail}</p>
              </div>
              <span className="text-gray-400"><Icon name={r.badge} size={18} /></span>
            </li>
          ))}
        </ul>
        <div className="mt-4 h-1.5 overflow-hidden rounded-sm bg-gray-100">
          <div className="grow-bar h-full w-3/4 bg-brand" />
        </div>
      </div>
    </div>
  );
}
