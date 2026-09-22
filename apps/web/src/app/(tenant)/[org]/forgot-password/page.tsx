import { AuthCard } from '@/components/auth-card';
import { getPublicSite } from '@/lib/tenant/public-site';
import { ForgotPasswordForm } from './forgot-password-form';

export default async function ForgotPasswordPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const site = await getPublicSite(org);

  return (
    <AuthCard
      title="نسيت كلمة السر"
      brand={site ? { name: site.name, logoUrl: site.logo_url } : undefined}
      subtitle="إذا كان لحسابك بريد إلكتروني، سنرسل له رابط إعادة التعيين"
      footer={
        <a href="/login" className="font-semibold text-brand">
          رجوع لتسجيل الدخول
        </a>
      }
    >
      <ForgotPasswordForm orgSlug={org} />
    </AuthCard>
  );
}
