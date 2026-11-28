/** The garden's "please wait": a stem grows and three leaves open, again and again. */
export function SeedlingLoader({ label }: { label: string }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-brand" role="status" aria-label={label}>
      <svg width="56" height="56" viewBox="0 0 40 40" fill="none" aria-hidden>
        <path className="seedling-stem" d="M20 37 C20 30 20 22 20 12" stroke="currentColor" strokeWidth="2.4" strokeLinecap="round" />
        <path className="seedling-leaf l" d="M20 28 C14 28 10 25 9 20 C14 20 18 23 20 28 Z" fill="currentColor" />
        <path className="seedling-leaf r" d="M20 21 C26 21 30 18 31 13 C26 13 22 16 20 21 Z" fill="currentColor" opacity="0.85" />
        <path className="seedling-leaf t" d="M20 13 C17 10 17 5 20 2 C23 5 23 10 20 13 Z" fill="#D4A24C" />
      </svg>
    </div>
  );
}
