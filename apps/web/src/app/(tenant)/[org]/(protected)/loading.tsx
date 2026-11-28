import { SeedlingLoader } from '@/components/seedling-loader';

export default function Loading() {
  return (
    <div className="p-6" aria-busy="true">
      <SeedlingLoader label="جاري التحميل" />
      <div className="mx-auto grid max-w-4xl gap-4 opacity-60 sm:grid-cols-3">
        {[0, 1, 2].map((i) => (
          <div key={i} className="h-24 animate-pulse rounded-lg bg-brand/5" />
        ))}
      </div>
    </div>
  );
}
