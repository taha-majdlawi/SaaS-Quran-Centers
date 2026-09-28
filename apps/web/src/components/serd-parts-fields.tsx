import { JUZ_NAMES, portionOptions, type SerdPart } from '@/lib/serd/format';
import { getI18n } from '@/lib/i18n/server';
import { fmt } from '@/lib/i18n/config';

const field = 'mt-1 w-full rounded border px-3 py-2 text-sm';

/**
 * The juz / amount rows of a serd form: up to `rows` juz, each recited whole
 * or as a half / quarter / eighth (only the amounts the center allows are
 * offered; the server re-checks them against the student's stage).
 */
export async function SerdPartsFields({
  denominators,
  rows = 4,
  initial = [],
}: {
  denominators: number[];
  rows?: number;
  initial?: SerdPart[];
}) {
  const { t: T, locale } = await getI18n();
  const S = T.staff;
  const options = portionOptions(denominators, T.labels);
  return (
    <div className="flex flex-col gap-2">
      {Array.from({ length: rows }, (_, i) => {
        const part = initial[i];
        return (
          <div key={i} className="grid grid-cols-[1fr_9rem] gap-3 rounded bg-gray-50 p-3">
            <label className="text-sm font-medium text-gray-700">
              {i === 0 ? S.serd.juz : fmt(S.serd.extraJuz, { n: i })}
              <select name="juz" defaultValue={part ? String(part.juz) : ''} className={field}>
                <option value="">{i === 0 ? S.serd.pickJuz : '—'}</option>
                {JUZ_NAMES.map((name, idx) => (
                  <option key={idx + 1} value={idx + 1}>
                    {locale === 'ar' ? `${idx + 1} — ${name}` : fmt(T.labels.juz, { n: idx + 1 })}
                  </option>
                ))}
              </select>
            </label>
            <label className="text-sm font-medium text-gray-700">
              {S.serd.amount}
              <select name="portion" defaultValue={part ? `${part.den}:${part.index}` : '1:1'} className={field}>
                {options.map((o) => (
                  <option key={o.value} value={o.value}>
                    {o.label}
                  </option>
                ))}
              </select>
            </label>
          </div>
        );
      })}
    </div>
  );
}
