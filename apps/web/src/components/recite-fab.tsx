import { Mic } from 'lucide-react';

/** The floating "recite" button on the student's pages: opens the live recite screen. */
export function ReciteFab({ href, label }: { href: string; label: string }) {
  return (
    <a
      href={href as never}
      className="fixed bottom-5 right-4 z-30 flex items-center gap-2 rounded-full bg-brand px-5 py-3 font-semibold text-white shadow-lg shadow-brand/30 transition hover:brightness-110 print:hidden"
    >
      <Mic size={18} /> {label}
    </a>
  );
}
