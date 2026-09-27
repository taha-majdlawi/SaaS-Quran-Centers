import { LegalPage } from '@/components/legal-page';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

export default async function SupportPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const { t } = await getI18n();
  return (
    <LegalPage orgSlug={org} title={t.legal.supportTitle}>
      {({ name, contactEmail }) => (
        <>
          <p>
            {fmt(t.legal.support1, { name })}
            {contactEmail ? (
              <>
                {' '}
                {t.legal.viaEmail}{' '}
                <a href={`mailto:${contactEmail}`} className="text-brand hover:underline" dir="ltr">
                  {contactEmail}
                </a>
              </>
            ) : (
              ` ${t.legal.directly}`
            )}
            .
          </p>
          <p>{t.legal.support2}</p>
        </>
      )}
    </LegalPage>
  );
}
