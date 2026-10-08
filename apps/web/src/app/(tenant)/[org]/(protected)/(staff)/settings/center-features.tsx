import { createClient } from '@/lib/supabase/server';
import { SubmitButton } from '@/components/submit-button';
import { staffStrings } from '@/lib/i18n/server';
import { saveCenterFeatures, saveRecitationAudioDays } from './actions';

interface Feature {
  key: string;
  available: boolean;
  enabled: boolean;
}

/** The admin switches the center's features (center_features / set_center_features, 0088). What the plan does not include stays off. */
export async function CenterFeaturesForm({ orgId }: { orgId: string }) {
  const supabase = await createClient();
  const [{ data }, S] = await Promise.all([supabase.rpc('center_features', { p_org: orgId }), staffStrings()]);
  const features = (data ?? []) as Feature[];
  const C = S.cfeat;
  return (
    <form action={saveCenterFeatures} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
      <input type="hidden" name="orgId" value={orgId} />
      <input type="hidden" name="available" value={features.filter((f) => f.available).map((f) => f.key).join(',')} />
      <h2 className="font-semibold">{C.title}</h2>
      <p className="text-sm text-gray-500">{C.hint}</p>
      <ul className="divide-y rounded-md border">
        {features.map((f) => (
          <li key={f.key}>
            <label className={`flex items-center justify-between gap-3 px-3 py-2.5 text-sm ${f.available ? 'cursor-pointer' : 'cursor-not-allowed opacity-60'}`}>
              <span>
                {C.names[f.key as keyof typeof C.names] ?? f.key}
                {!f.available && <span className="ms-2 rounded bg-gray-100 px-1.5 py-0.5 text-xs text-gray-500">{C.notInPlan}</span>}
              </span>
              <input type="checkbox" name={`f_${f.key}`} defaultChecked={f.enabled} disabled={!f.available} className="h-5 w-5 accent-[var(--brand,#1E7A54)]" />
            </label>
          </li>
        ))}
      </ul>
      <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={S.common.saving}>
        {C.save}
      </SubmitButton>
    </form>
  );
}

const RETENTION_DAYS = [7, 14, 30, 60, 90, 180, 365];

/** How long reviewed recitations' recordings (0090) and chat pictures (0091) are kept. */
export async function RecitationAudioForm({ orgId }: { orgId: string }) {
  const supabase = await createClient();
  const [{ data, error }, S] = await Promise.all([supabase.rpc('media_retention', { p_org: orgId }), staffStrings()]);
  if (error || !data) return null;
  const C = S.cfeat;
  const { audio_days, chat_days } = data as { audio_days: number | null; chat_days: number | null };
  const select = (name: string, days: number | null) => (
    <select name={name} defaultValue={days === null ? 'never' : String(days)} className="max-w-xs rounded-md border px-3 py-2 text-sm">
      {[...new Set([...RETENTION_DAYS, ...(days === null ? [] : [days])])]
        .sort((a, b) => a - b)
        .map((n) => (
          <option key={n} value={n}>
            {C.audioDays.replace('{n}', String(n))}
          </option>
        ))}
      <option value="never">{C.audioNever}</option>
    </select>
  );
  return (
    <form action={saveRecitationAudioDays} className="flex flex-col gap-3 rounded-lg border bg-white p-4">
      <input type="hidden" name="orgId" value={orgId} />
      <h2 className="font-semibold">{C.audioTitle}</h2>
      <p className="text-sm text-gray-500">{C.audioHint}</p>
      {select('days', audio_days)}
      <h2 className="mt-2 font-semibold">{C.chatTitle}</h2>
      <p className="text-sm text-gray-500">{C.chatHint}</p>
      {select('chatDays', chat_days)}
      <SubmitButton className="self-start rounded bg-brand px-4 py-2 text-sm font-semibold text-white" pendingText={S.common.saving}>
        {C.audioSave}
      </SubmitButton>
    </form>
  );
}
