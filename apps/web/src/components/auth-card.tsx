import { OrgLogo } from '@/components/org-logo';

export function AuthCard({
  title,
  subtitle,
  error,
  children,
  footer,
  brand,
}: {
  title: string;
  subtitle?: string;
  error?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  /** The center this screen belongs to (name + logo) - replaces the platform mark. */
  brand?: { name: string; logoUrl?: string | null };
}) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50 p-6">
      <div className="w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 shadow-sm">
        <div className="mb-6 text-center">
          <div className="mx-auto mb-3 flex justify-center">
            <OrgLogo name={brand?.name ?? 'ب'} logoUrl={brand?.logoUrl} size={56} />
          </div>
          {brand && <p className="mb-1 text-sm font-semibold text-brand">{brand.name}</p>}
          <h1 className="text-xl font-bold text-gray-900">{title}</h1>
          {subtitle && <p className="mt-1 text-sm text-gray-500">{subtitle}</p>}
        </div>

        {error && (
          <p className="mb-4 rounded-lg bg-red-50 px-3 py-2 text-center text-sm text-red-600">{error}</p>
        )}

        {children}

        {footer && <div className="mt-6 text-center text-sm text-gray-500">{footer}</div>}
      </div>
    </main>
  );
}
