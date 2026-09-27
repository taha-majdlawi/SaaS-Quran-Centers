import { LegalPage } from '@/components/legal-page';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

export default async function DeleteAccountPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const { t } = await getI18n();
  return (
    <LegalPage orgSlug={org} title={t.legal.deleteTitle}>
      {({ name, contactEmail }) => (
        <>
          <p>
            {fmt(t.legal.delete1, { name })}
            {contactEmail ? (
              <>
                {' '}
                {t.legal.viaEmail}{' '}
                <a href={`mailto:${contactEmail}`} className="text-brand hover:underline" dir="ltr">
                  {contactEmail}
                </a>
              </>
            ) : (
              ` ${t.legal.viaChannels}`
            )}
            .
          </p>
          <p>{t.legal.delete2}</p>
          <p>{t.legal.delete3}</p>
        </>
      )}
    </LegalPage>
  );
}
