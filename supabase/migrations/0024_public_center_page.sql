-- =========================================================================
-- 0024_public_center_page.sql
-- The center's public face (identity + optional landing page + contact), for a
-- signed-out visitor. 0018 closed anonymous access to every table, so the
-- public page cannot read site_settings directly; this SECURITY DEFINER
-- function is the ONLY door and it returns nothing at all unless the admin
-- turned the public page on. Branding (name, logo, colours) is always public -
-- the login screen has to say which center this is.
-- =========================================================================

create or replace function public.get_public_site(p_slug text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare o public.organizations%rowtype; s public.site_settings%rowtype;
begin
  select * into o from public.organizations where slug = lower(btrim(coalesce(p_slug, '')));
  if not found then return null; end if;
  select * into s from public.site_settings where organization_id = o.id;
  return jsonb_build_object(
    'name', o.name, 'slug', o.slug, 'logo_url', o.logo_url,
    'primary_color', o.primary_color, 'secondary_color', o.secondary_color,
    'enabled', coalesce(s.public_site_enabled, false),
    -- contact details are shown only when the admin published the page
    'hero_title', case when coalesce(s.public_site_enabled, false) then s.hero_title end,
    'hero_body', case when coalesce(s.public_site_enabled, false) then s.hero_body end,
    'contact_email', case when coalesce(s.public_site_enabled, false) then s.contact_email end
  );
end;
$$;

revoke all on function public.get_public_site(text) from public;
grant execute on function public.get_public_site(text) to anon, authenticated, service_role;
