import { AuthCard } from '@/components/auth-card';
import { getPublicSite } from '@/lib/tenant/public-site';
import { ResetPasswordForm } from './reset-password-form';
import { getI18n } from '@/lib/i18n/server';

export default async function ResetPasswordPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const site = await getPublicSite(org);
  const { t } = await getI18n();

  return (
    <AuthCard
      title={t.reset.title}
      brand={site ? { name: site.name, logoUrl: site.logo_url } : undefined}
      subtitle={t.reset.subtitle}
    >
      <ResetPasswordForm t={t.reset} />
    </AuthCard>
  );
}
