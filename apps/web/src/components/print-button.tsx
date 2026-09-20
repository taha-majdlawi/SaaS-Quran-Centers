'use client';

/** Opens the browser's print dialog ("save as PDF" from there). */
export function PrintButton({ label = 'طباعة / حفظ PDF' }: { label?: string }) {
  return (
    <button type="button" onClick={() => window.print()} className="rounded bg-brand px-4 py-2 text-sm font-semibold text-white print:hidden">
      {label}
    </button>
  );
}
