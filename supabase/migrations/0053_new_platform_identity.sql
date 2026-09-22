-- =========================================================================
-- 0053_new_platform_identity.sql
-- New platform visual identity (garden emerald + illuminated gold, see
-- design/brand/README.md) replaces the placeholder teal/amber used since
-- 0001. Only the column DEFAULT changes - a brand-new center now starts
-- with the platform's own colors, still fully customizable afterwards
-- (settings page). No existing organization's chosen colors are touched.
-- =========================================================================
alter table public.organizations alter column primary_color set default '#1E7A54';
alter table public.organizations alter column secondary_color set default '#D4A24C';

notify pgrst, 'reload schema';
