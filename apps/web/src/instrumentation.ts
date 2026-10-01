// Server-side crashes (rendering, server actions, route handlers) go to the same
// error log as the browser's (0076 report_client_error), as source 'server'.
export async function register() {}

export async function onRequestError(
  err: unknown,
  request: { path: string; method: string; headers: Record<string, string | string[] | undefined> },
  context: { routerKind: string; routePath: string; routeType: string },
) {
  try {
    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    if (!url || !key) return;
    const e = err instanceof Error ? err : new Error(String(err));
    // redirects and not-found are how Next.js navigates, not failures
    if (/NEXT_REDIRECT|NEXT_NOT_FOUND|NEXT_HTTP_ERROR_FALLBACK/.test(`${e.message} ${(e as { digest?: string }).digest ?? ''}`)) return;
    const ua = request.headers['user-agent'];
    await fetch(`${url}/rest/v1/rpc/report_client_error`, {
      method: 'POST',
      headers: { apikey: key, Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        p_source: 'server',
        p_message: `${e.name && e.name !== 'Error' ? `${e.name}: ` : ''}${e.message}`,
        p_stack: e.stack ?? null,
        p_screen: context.routePath,
        p_url: `${request.method} ${request.path}`.slice(0, 500),
        p_device: (Array.isArray(ua) ? ua[0] : ua)?.slice(0, 120) ?? null,
        p_extra: { routeType: context.routeType, routerKind: context.routerKind, digest: (e as { digest?: string }).digest },
      }),
    });
  } catch {
    // never let reporting fail the request
  }
}
