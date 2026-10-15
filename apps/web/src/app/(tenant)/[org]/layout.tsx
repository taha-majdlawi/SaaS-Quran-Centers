import { notFound } from 'next/navigation';
import { getPublicSite } from '@/lib/tenant/public-site';

// A center's address that leads nowhere (a typo, a deleted center) is "not found" on every page:
// before, its sign-in, forgot-password and join pages opened as if the center existed.
export default async function TenantLayout({ children, params }: { children: React.ReactNode; params: Promise<{ org: string }> }) {
  const { org } = await params;
  if (!(await getPublicSite(org))) notFound();
  return children;
}
