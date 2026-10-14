import { redirect } from 'next/navigation';
import { cookies } from 'next/headers';
import { AuthCard } from '@/components/auth-card';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';
import { getPublicSite } from '@/lib/tenant/public-site';
import { GOOGLE_CLIENT_ID } from '@/lib/auth/google-config';
import { PENDING_ORG_COOKIE, productUrl, validSlug } from '@/lib/auth/signup';
import { readPendingOrg } from '@/lib/auth/google-finish';
import { GoogleSignIn } from './google-signin';

/**
 * bustan-alquran.com/google: Google's sign-in button in one place for every center (Google wants
 * each site that shows its button listed by name, and centers are added every day). The centers'
 * sign-in pages, the invitation and the sign-up form send their visitors here (lib/auth/google.ts).
 */
export default async function GooglePage({ searchParams }: { searchParams: Promise<{ center?: string; invite?: string; signup?: string }> }) {
  const { center = '', invite, signup } = await searchParams;
  const { t, locale } = await getI18n();
  const isSignup = signup === '1';
  if (!GOOGLE_CLIENT_ID) redirect(isSignup ? '/signup' : center ? (productUrl('/login', center) as never) : '/');
  if (!isSignup && !validSlug(center)) redirect('/login');

  const site = isSignup ? null : await getPublicSite(center);
  const pending = isSignup ? readPendingOrg((await cookies()).get(PENDING_ORG_COOKIE)?.value) : {};
  const subtitle = isSignup ? fmt(t.googlePage.newCenter, { name: pending.orgName ?? '' }) : fmt(t.googlePage.toCenter, { center: site?.name ?? center });
  const back = isSignup ? '/signup' : productUrl(invite ? `/join?token=${invite}` : '/login', center);

  return (
    <AuthCard
      title={t.googlePage.title}
      subtitle={subtitle}
      brand={site ? { name: site.name, logoUrl: site.logo_url } : undefined}
      footer={
        <a href={back} className="font-semibold text-brand">
          {t.googlePage.back}
        </a>
      }
    >
      <GoogleSignIn clientId={GOOGLE_CLIENT_ID} center={center || undefined} invite={invite} signup={isSignup} lang={locale} t={t.googlePage} />
    </AuthCard>
  );
}
