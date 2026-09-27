import { LegalPage } from '@/components/legal-page';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

export default async function PrivacyPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const { t } = await getI18n();
  return (
    <LegalPage orgSlug={org} title={t.legal.privacyTitle}>
      {({ name }) => (
        <>
          <p>{fmt(t.legal.privacy1, { name })}</p>
          <p>{t.legal.privacy2}</p>
          <p>
            {t.legal.privacy3Before}{' '}
            <a href="/delete-account" className="text-brand hover:underline">
              {t.legal.privacy3Link}
            </a>{' '}
            {t.legal.privacy3After}
          </p>
        </>
      )}
    </LegalPage>
  );
}
