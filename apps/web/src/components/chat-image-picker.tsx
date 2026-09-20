'use client';

import { useRef, useState } from 'react';

const MAX = 5 * 1024 * 1024;

/**
 * The 📷 button of the chat composer. The chosen picture is shown as a preview
 * (with a remove button) BEFORE sending, so it is clear the message carries one.
 * The <input name="image"> lives inside the form, so the server action gets the file.
 */
export function ChatImagePicker() {
  const input = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [error, setError] = useState('');

  const clear = () => {
    if (input.current) input.current.value = '';
    if (preview) URL.revokeObjectURL(preview);
    setPreview(null);
    setName('');
  };

  const onChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    setError('');
    if (preview) URL.revokeObjectURL(preview);
    if (!file) {
      setPreview(null);
      setName('');
      return;
    }
    if (file.size > MAX) {
      setError('حجم الصورة الأقصى 5 ميغابايت');
      clear();
      return;
    }
    setPreview(URL.createObjectURL(file));
    setName(file.name);
  };

  return (
    <>
      <label className="cursor-pointer rounded border px-3 py-2 text-sm text-gray-600 hover:bg-gray-50" title="إرفاق صورة">
        📷
        <input ref={input} type="file" name="image" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={onChange} />
      </label>
      {(preview || error) && (
        <div className="flex w-full items-center gap-3 rounded border bg-gray-50 p-2 text-xs">
          {preview && (
            <>
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src={preview} alt="" className="h-16 w-16 rounded object-cover" />
              <span className="flex-1 truncate text-gray-600">{name}</span>
              <button type="button" onClick={clear} className="rounded border px-2 py-1 text-red-600 hover:bg-red-50">
                إزالة
              </button>
            </>
          )}
          {error && <span className="text-red-600">{error}</span>}
        </div>
      )}
    </>
  );
}
