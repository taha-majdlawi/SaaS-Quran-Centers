'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';

const TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const MAX_SIDE = 1200;

/** Shrinks a big photo in the browser before uploading (keeps it well under the 3 MB bucket limit). */
async function shrink(file: File): Promise<{ blob: Blob; type: string; ext: string }> {
  const ext = TYPES[file.type];
  if (file.size <= 600 * 1024) return { blob: file, type: file.type, ext };
  const bmp = await createImageBitmap(file);
  const scale = Math.min(1, MAX_SIDE / Math.max(bmp.width, bmp.height));
  const canvas = document.createElement('canvas');
  canvas.width = Math.round(bmp.width * scale);
  canvas.height = Math.round(bmp.height * scale);
  canvas.getContext('2d')!.drawImage(bmp, 0, 0, canvas.width, canvas.height);
  const blob = await new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.85));
  if (!blob) return { blob: file, type: file.type, ext };
  return { blob, type: 'image/jpeg', ext: 'jpg' };
}

/**
 * The item's picture: upload one from the device (shown as a preview at once,
 * stored in the center's own folder) OR paste a link - both write the same
 * `imageUrl` field the form submits.
 */
export function MarketImageField({ orgId, initialUrl }: { orgId: string; initialUrl: string | null }) {
  const [url, setUrl] = useState(initialUrl ?? '');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const onFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';
    if (!file) return;
    setError('');
    if (!TYPES[file.type]) {
      setError('الصور المسموحة: JPG أو PNG أو WebP');
      return;
    }
    setBusy(true);
    try {
      const { blob, type, ext } = await shrink(file);
      if (blob.size > 3 * 1024 * 1024) throw new Error('الصورة كبيرة (الحد 3 ميغابايت)');
      const supabase = createClient();
      const path = `${orgId}/${crypto.randomUUID()}.${ext}`;
      const { error: upError } = await supabase.storage.from('market-images').upload(path, blob, { contentType: type });
      if (upError) throw new Error(upError.message.includes('row-level security') ? 'لا تملك صلاحية رفع الصور' : 'تعذّر رفع الصورة');
      setUrl(supabase.storage.from('market-images').getPublicUrl(path).data.publicUrl);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'تعذّر رفع الصورة');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="text-sm font-medium text-gray-700">
      صورة العنصر (اختياري)
      <div className="mt-1 flex items-start gap-3">
        {url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={url} alt="" className="h-24 w-24 rounded border object-cover" />
        ) : (
          <div className="flex h-24 w-24 items-center justify-center rounded border border-dashed text-xs text-gray-400">بلا صورة</div>
        )}
        <div className="flex flex-1 flex-col gap-2">
          <div className="flex flex-wrap items-center gap-2">
            <label className="cursor-pointer rounded border px-3 py-1.5 text-xs font-semibold text-brand hover:bg-gray-50">
              {busy ? 'جاري الرفع...' : 'رفع من الجهاز'}
              <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={onFile} disabled={busy} />
            </label>
            {url && (
              <button type="button" onClick={() => setUrl('')} className="rounded border px-3 py-1.5 text-xs text-red-600 hover:bg-red-50">
                إزالة الصورة
              </button>
            )}
          </div>
          <input
            name="imageUrl"
            dir="ltr"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="أو الصق رابط صورة https://..."
            className="w-full rounded border px-3 py-2 text-sm font-normal"
          />
          {error && <p className="text-xs text-red-600">{error}</p>}
        </div>
      </div>
    </div>
  );
}
