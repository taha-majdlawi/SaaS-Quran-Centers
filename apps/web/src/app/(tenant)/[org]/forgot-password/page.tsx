import { AuthCard } from '@/components/auth-card';
import { getPublicSite } from '@/lib/tenant/public-site';
import { ForgotPasswordForm } from './forgot-password-form';
import { getI18n } from '@/lib/i18n/server';

export default async function ForgotPasswordPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const site = await getPublicSite(org);
  const { t } = await getI18n();

  return (
    <AuthCard
      title={t.forgot.title}
      brand={site ? { name: site.name, logoUrl: site.logo_url } : undefined}
      subtitle={t.forgot.subtitle}
      footer={
        <a href="/login" className="font-semibold text-brand">
          {t.common.backToLogin}
        </a>
      }
    >
      <ForgotPasswordForm orgSlug={org} t={{ ...t.forgot, identifier: t.common.identifier }} />
    </AuthCard>
  );
}
