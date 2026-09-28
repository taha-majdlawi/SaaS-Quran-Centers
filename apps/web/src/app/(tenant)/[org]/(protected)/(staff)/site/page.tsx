import { getOrgContext } from '@/lib/tenant/get-org-context';
import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { updateSiteSettings } from './actions';
import { getI18n } from '@/lib/i18n/server';

export default async function SitePage({
  params,
  searchParams,
}: {
  params: Promise<{ org: string }>;
  searchParams: Promise<{ error?: string; saved?: string }>;
}) {
  const { org: slug } = await params;
  const { error, saved } = await searchParams;
  const org = await getOrgContext(slug);
  const { t: T } = await getI18n();
  const S = T.staff;
  const supabase = await createClient();
  const isAdmin = org.myRole === 'admin';

  const { data: site } = await supabase
    .from('site_settings')
    .select('public_site_enabled, hero_title, hero_body, contact_email')
    .eq('organization_id', org.id)
    .maybeSingle();

  return (
    <div className="max-w-lg">
      <h1 className="mb-1 text-2xl font-bold">{S.site.heading}</h1>
      <p className="mb-3 text-sm text-gray-500">{S.site.intro}</p>
      <p className="mb-6 text-sm">
        <a href={'/?preview=1' as never} target="_blank" rel="noreferrer" className="text-brand hover:underline">
          {S.site.preview}
        </a>
        <span className="ms-1 text-xs text-gray-400">{S.site.previewHint}</span>
      </p>

      {error && <p className="mb-4 rounded bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>}
      {saved && <p className="mb-4 rounded bg-green-50 px-3 py-2 text-sm text-green-700">{S.settings.saved}</p>}

      <form action={updateSiteSettings} className="flex flex-col gap-3 rounded-lg border bg-white p-6">
        <input type="hidden" name="orgId" value={org.id} />
        <fieldset disabled={!isAdmin} className="flex flex-col gap-3">
          <label className="flex items-center gap-2 text-sm font-medium text-gray-700">
            <input type="checkbox" name="publicSiteEnabled" defaultChecked={site?.public_site_enabled ?? false} />
            {S.site.enable}
          </label>

          <label className="text-sm font-medium text-gray-700">
            {S.site.heroTitle}
            <input
              name="heroTitle"
              defaultValue={site?.hero_title ?? org.name}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            {S.site.heroBody}
            <textarea
              name="heroBody"
              rows={4}
              defaultValue={site?.hero_body ?? ''}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          <label className="text-sm font-medium text-gray-700">
            {S.site.email}
            <input
              type="email"
              name="contactEmail"
              defaultValue={site?.contact_email ?? ''}
              className="mt-1 w-full rounded border px-3 py-2 text-sm"
            />
          </label>

          {isAdmin && (
            <SubmitButton
              className="mt-2 rounded bg-brand px-4 py-2 text-sm font-semibold text-white disabled:opacity-50"
              pendingText={S.common.saving}
            >
              {S.settings.saveSettings}
            </SubmitButton>
          )}
        </fieldset>
      </form>

      {!isAdmin && <p className="mt-3 text-xs text-gray-400">{S.site.adminOnly}</p>}
    </div>
  );
}
