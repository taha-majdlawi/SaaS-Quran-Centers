import { Amiri_Quran } from 'next/font/google';

// Amiri Quran - SIL Open Font License 1.1 (self-hosted by Next at build time).
const amiri = Amiri_Quran({ weight: '400', subsets: ['arabic'], variable: '--font-quran', display: 'swap' });

/** Wraps the Quran pages so `font-quran` resolves to Amiri Quran. */
export function QuranFont({ children }: { children: React.ReactNode }) {
  return <div className={amiri.variable}>{children}</div>;
}
