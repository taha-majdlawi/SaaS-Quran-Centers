'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { Dictionary } from '@/lib/i18n/dictionaries/ar';
import { fmt } from '@/lib/i18n/config';

const TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const MAX_SIDE = 512;

/** Shrinks a big logo in the browser (keeps transparency for PNG/WebP) so it stays under the 1 MB bucket limit. */
async function shrink(file: File): Promise<{ blob: Blob; type: string; ext: string }> {
  const ext = TYPES[file.type];
  if (file.size <= 300 * 1024) return { blob: file, type: file.type, ext };
  const bmp = await createImageBitmap(file);
  const scale = Math.min(1, MAX_SIDE / Math.max(bmp.width, bmp.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bmp.width * scale);
  canvas.height = Math.round(bmp.height * scale);
  canvas.getContext('2d')!.drawImage(bmp, 0, 0, canvas.width, canvas.height);
  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, file.type === 'image/jpeg' ? 'image/jpeg' : 'image/png', 0.9));
  if (!blob) return { blob: file, type: file.type, ext };
  return { blob, type: blob.type, ext: blob.type === 'image/png' ? 'png' : 'jpg' };
}

/**
 * The center's logo: upload one from the device (previewed at once, stored in the
 * center's own folder of the public `org-logos` bucket) OR paste a link. Both fill
 * the `logoUrl` field of the settings form; press "save" to apply it everywhere.
 */
export function LogoField({ orgId, initialUrl, name, labels: L }: { orgId: string; initialUrl: string | null; name: string; labels: Dictionary['staff']['image'] }) {
  const [url, setUrl] = useState(initialUrl ?? '');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [uploaded, setUploaded] = useState(false);

  const onFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setError('');
    if (!TYPES[file.type]) {
      setError(L.types);
      return;
    }
    setBusy(true);
    try {
      const { blob, type, ext } = await shrink(file);
      if (blob.size > 1024 * 1024) throw new Error(fmt(L.tooBig, { n: 1 }));
      const supabase = createClient();
      const path = `${orgId}/${crypto.randomUUID()}.${ext}`;
      const { error: upError } = await supabase.storage.from('org-logos').upload(path, blob, { contentType: type });
      if (upError) throw new Error(upError.message.includes('row-level security') ? L.logoAdminOnly : L.logoFailed);
      setUrl(supabase.storage.from('org-logos').getPublicUrl(path).data.publicUrl);
      setUploaded(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : L.logoFailed);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="text-sm font-medium text-gray-700">
      {L.logo}
      <div className="mt-1 flex items-start gap-3">
        {url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={url} alt="" className="h-20 w-20 rounded-xl border object-cover" />
        ) : (
          <span className="flex h-20 w-20 items-center justify-center rounded-xl bg-brand text-2xl font-bold text-white">{name.trim().charAt(0) || 'ب'}</span>
        )}
        <div className="flex flex-1 flex-col gap-2">
          <div className="flex flex-wrap items-center gap-2">
            <label className="cursor-pointer rounded border px-3 py-1.5 text-xs font-semibold text-brand hover:bg-gray-50">
              {busy ? L.uploading : L.uploadLogo}
              <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={onFile} disabled={busy} />
            </label>
            {url && (
              <button
                type="button"
                onClick={() => {
                  setUrl('');
                  setUploaded(false);
                }}
                className="rounded border px-3 py-1.5 text-xs text-red-600 hover:bg-red-50"
              >
                {L.removeLogo}
              </button>
            )}
          </div>
          <input
            name="logoUrl"
            type="url"
            dir="ltr"
            value={url}
            onChange={(e) => {
              setUrl(e.target.value);
              setUploaded(false);
            }}
            placeholder={L.pasteLogo}
            className="w-full rounded border px-3 py-2 text-sm font-normal"
          />
          {uploaded && <p className="text-xs text-green-700">{L.logoUploaded}</p>}
          {error && <p className="text-xs text-red-600">{error}</p>}
        </div>
      </div>
    </div>
  );
}
