export default function Loading() {
  return (
    <div className="p-6" aria-busy="true" aria-label="جاري التحميل">
      <div className="mb-6 h-8 w-48 animate-pulse rounded bg-gray-200" />
      <div className="grid grid-cols-3 gap-4">
        {[0, 1, 2].map((i) => (
          <div key={i} className="h-24 animate-pulse rounded-lg bg-gray-100" />
        ))}
      </div>
      <div className="mt-6 h-48 animate-pulse rounded-lg bg-gray-100" />
    </div>
  );
}
