/** The platform's own mark (public/icons): the open book with the sprout. */
export const PLATFORM_LOGO = '/icons/icon-192.png';

export function PlatformLogo({ size = 40 }: { size?: number }) {
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={PLATFORM_LOGO} alt="" width={size} height={size} className="rounded-xl" style={{ width: size, height: size }} />
  );
}

/**
 * The center's logo, or the platform's mark when the center has none. The URL
 * is admin-typed (https only, see safeLogoUrl), so a plain <img> is used
 * rather than next/image.
 */
export function OrgLogo({ logoUrl, size = 40 }: { name?: string; logoUrl?: string | null; size?: number }) {
  if (!logoUrl) return <PlatformLogo size={size} />;
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={logoUrl} alt="" width={size} height={size} className="rounded-xl object-cover" style={{ width: size, height: size }} />
  );
}
