import Stripe from 'stripe';

/**
 * Server-only - STRIPE_SECRET_KEY must never reach the browser bundle.
 * Uses Stripe's fetch-based HTTP client rather than the Node default so
 * this works unmodified under the Cloudflare Workers runtime this app
 * deploys to (see apps/web/wrangler.jsonc) as well as in local dev.
 */
export function createStripeClient() {
  return new Stripe(process.env.STRIPE_SECRET_KEY!, {
    httpClient: Stripe.createFetchHttpClient(),
  });
}
