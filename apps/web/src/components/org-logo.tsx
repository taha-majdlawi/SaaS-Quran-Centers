/**
 * The center's logo, or its first letter on the brand colour when no logo is
 * set. The URL is admin-typed (https only, see safeLogoUrl), so a plain <img>
 * is used rather than next/image.
 */
export function OrgLogo({ name, logoUrl, size = 40 }: { name: string; logoUrl?: string | null; size?: number }) {
  if (logoUrl) {
    return (
      // eslint-disable-next-line @next/next/no-img-element
      <img src={logoUrl} alt="" width={size} height={size} className="rounded-xl object-cover" style={{ width: size, height: size }} />
    );
  }
  return (
    <span
      className="flex items-center justify-center rounded-xl bg-brand font-bold text-white"
      style={{ width: size, height: size, fontSize: size * 0.42 }}
    >
      {name.trim().charAt(0) || 'ب'}
    </span>
  );
}
