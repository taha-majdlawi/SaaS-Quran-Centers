-- =========================================================================
-- 0021_stripe_billing.sql
-- Backs the real Stripe checkout + webhook integration (apps/web's
-- /api/stripe/webhook and (staff)/billing) - 0001_core_tenancy.sql already
-- has `plans`/`subscriptions` as a skeleton, this just adds what the
-- webhook's upsert needs.
-- =========================================================================

-- The webhook upserts by organization_id (checkout.session.completed can, in
-- principle, fire more than once for the same session on Stripe's retries) -
-- needs a real constraint to target, and the data model is one active
-- subscription row per org regardless.
alter table public.subscriptions
  add constraint subscriptions_organization_id_key unique (organization_id);
