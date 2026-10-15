import { OrgLogo } from '@/components/org-logo';
import { LanguageSwitcher } from '@/lib/i18n/client';

export function AuthCard({
  title,
  subtitle,
  error,
  children,
  footer,
  brand,
  languages = true,
}: {
  title: string;
  subtitle?: string;
  error?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  /** The center this screen belongs to (name + logo) - replaces the platform mark. */
  brand?: { name: string; logoUrl?: string | null };
  /** Show the language picker (off for the Arabic-only platform console). */
  languages?: boolean;
}) {
  return (
    <main className="flex min-h-screen items-center justify-center bg-page p-6">
      <div className="relative z-10 w-full max-w-sm rounded-2xl border border-gray-200 bg-white p-8 shadow-sm">
        {languages && <LanguageSwitcher className="absolute end-3 top-3" />}
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
