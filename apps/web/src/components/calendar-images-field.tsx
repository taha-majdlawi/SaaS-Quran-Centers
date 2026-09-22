'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import type { CalImage } from '@/lib/calendar/format';
import { addEntryImage, deleteEntryImage, reorderEntryImages } from '@/app/(tenant)/[org]/(protected)/(staff)/calendar/actions';

const TYPES: Record<string, string> = { 'image/jpeg': 'jpg', 'image/png': 'png', 'image/webp': 'webp' };
const MAX_SIDE = 1600;

/** Shrinks a big photo in the browser before uploading (keeps it well under the 3 MB bucket limit). */
async function shrink(file: File): Promise<{ blob: Blob; type: string; ext: string }> {
  const ext = TYPES[file.type];
  if (file.size <= 900 * 1024) return { blob: file, type: file.type, ext };
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
 * Photo gallery on an event, admin-only. Each add/remove/reorder is its own
 * RPC round trip (see calendar/actions.ts) so the page just reflects
 * whatever calendar_entry_details returns after the redirect - no separate
 * client-side image state to keep in sync.
 */
export function CalendarImagesField({
  orgId,
  entryId,
  images,
  back,
}: {
  orgId: string;
  entryId: string;
  images: CalImage[];
  back: string;
}) {
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
      const { error: upError } = await supabase.storage.from('event-images').upload(path, blob, { contentType: type });
      if (upError) throw new Error(upError.message.includes('row-level security') ? 'لا تملك صلاحية رفع الصور' : 'تعذّر رفع الصورة');
      const url = supabase.storage.from('event-images').getPublicUrl(path).data.publicUrl;

      const fd = new FormData();
      fd.set('orgId', orgId);
      fd.set('entryId', entryId);
      fd.set('imageUrl', url);
      fd.set('back', back);
      await addEntryImage(fd);
    } catch (err) {
      setBusy(false);
      setError(err instanceof Error ? err.message : 'تعذّر رفع الصورة');
    }
  };

  const move = async (index: number, dir: -1 | 1) => {
    const next = [...images];
    const swap = index + dir;
    if (swap < 0 || swap >= next.length) return;
    [next[index], next[swap]] = [next[swap], next[index]];
    const fd = new FormData();
    fd.set('orgId', orgId);
    fd.set('entryId', entryId);
    fd.set('ids', next.map((i) => i.id).join(','));
    fd.set('back', back);
    await reorderEntryImages(fd);
  };

  const remove = async (id: string) => {
    const fd = new FormData();
    fd.set('orgId', orgId);
    fd.set('id', id);
    fd.set('back', back);
    await deleteEntryImage(fd);
  };

  return (
    <div className="text-sm font-medium text-gray-700">
      صور الفعالية (اختياري)
      {images.length > 0 && (
        <div className="mt-2 grid grid-cols-2 gap-3 sm:grid-cols-3">
          {images.map((img, i) => (
            // eslint-disable-next-line @next/next/no-img-element
            <div key={img.id} className="relative overflow-hidden rounded border">
              <img src={img.image_url} alt={img.caption ?? ''} className="h-28 w-full object-cover" />
              <div className="flex items-center justify-between gap-1 bg-white/90 px-1.5 py-1 text-xs">
                <div className="flex gap-1">
                  <button type="button" onClick={() => move(i, -1)} disabled={i === 0} className="disabled:opacity-30">
                    ▶
                  </button>
                  <button type="button" onClick={() => move(i, 1)} disabled={i === images.length - 1} className="disabled:opacity-30">
                    ◀
                  </button>
                </div>
                <button type="button" onClick={() => remove(img.id)} className="font-semibold text-red-600">
                  حذف
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
      <label className="mt-2 inline-block cursor-pointer rounded border px-3 py-1.5 text-xs font-semibold text-brand hover:bg-gray-50">
        {busy ? 'جاري الرفع...' : 'إضافة صورة'}
        <input type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={onFile} disabled={busy} />
      </label>
      {error && <p className="mt-1 text-xs font-normal text-red-600">{error}</p>}
    </div>
  );
}
