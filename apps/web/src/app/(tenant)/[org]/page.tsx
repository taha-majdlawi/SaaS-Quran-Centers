import { redirect } from 'next/navigation';

// The redirect target is relative to the ROOT domain, not `/[org]` - the
// user's browser is on `{slug}.bustan-alquran.com`, and middleware.ts
// re-derives `org` from that hostname on every request. Redirecting to
// `/${org}/dashboard` here would make middleware prepend the slug a
// second time (`/demo/demo/dashboard`) and 404.
export default async function TenantRootPage() {
  redirect('/dashboard');
}
