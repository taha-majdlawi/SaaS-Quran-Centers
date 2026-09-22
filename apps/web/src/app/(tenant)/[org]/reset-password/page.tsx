import { AuthCard } from '@/components/auth-card';
import { getPublicSite } from '@/lib/tenant/public-site';
import { ResetPasswordForm } from './reset-password-form';

export default async function ResetPasswordPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const site = await getPublicSite(org);

  return (
    <AuthCard
      title="كلمة سر جديدة"
      brand={site ? { name: site.name, logoUrl: site.logo_url } : undefined}
      subtitle="أدخل كلمة السر الجديدة لحسابك"
    >
      <ResetPasswordForm />
    </AuthCard>
  );
}
