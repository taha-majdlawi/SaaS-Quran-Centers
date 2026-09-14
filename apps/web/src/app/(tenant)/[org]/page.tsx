import { redirect } from 'next/navigation';
import { getOrgContext } from '@/lib/tenant/get-org-context';

// The redirect target is relative to the ROOT domain, not `/[org]` - the
// user's browser is on `{slug}.bustan-alquran.com`, and middleware.ts
// re-derives `org` from that hostname on every request. Redirecting to
// `/${org}/dashboard` here would make middleware prepend the slug a
// second time (`/demo/demo/dashboard`) and 404.
//
// This route also matches any single-segment path on the ROOT domain
// (e.g. bustan-alquran.com/does-not-exist) since `[org]` is a dynamic
// segment Next.js resolves regardless of hostname - middleware.ts only
// scopes it correctly for real subdomains. getOrgContext() 404s on a slug
// that isn't a real organization, so a bad root-domain path renders our
// not-found page instead of blindly redirecting into a loop.
export default async function TenantRootPage({ params }: { params: Promise<{ org: string }> }) {
  const { org } = await params;
  const ctx = await getOrgContext(org);
  redirect(ctx.myRole === 'student' || ctx.myRole === 'guardian' ? '/my' : '/dashboard');
}
