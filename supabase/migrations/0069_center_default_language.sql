-- =========================================================================
-- 0069_center_default_language.sql
-- i18n phase 3: each center picks the language its people see until they
-- choose one themselves (organization_settings key 'default_language', written
-- by the admin from the settings page like every other center setting).
-- get_public_site() now also returns it, so the sign-in page of a center that
-- works in English opens in English for a first-time visitor. Only 'ar' / 'en'
-- are ever returned; anything else reads as Arabic.
-- =========================================================================

create or replace function public.get_public_site(p_slug text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare o public.organizations%rowtype; s public.site_settings%rowtype; v_lang text;
begin
  select * into o from public.organizations where slug = lower(btrim(coalesce(p_slug, '')));
  if not found then return null; end if;
  select * into s from public.site_settings where organization_id = o.id;
  select value into v_lang from public.organization_settings where organization_id = o.id and key = 'default_language';
  return jsonb_build_object(
    'name', o.name, 'slug', o.slug, 'logo_url', o.logo_url,
    'primary_color', o.primary_color, 'secondary_color', o.secondary_color,
    'enabled', coalesce(s.public_site_enabled, false),
    'default_language', case when v_lang in ('ar', 'en') then v_lang else 'ar' end,
    -- contact details are shown only when the admin published the page
    'hero_title', case when coalesce(s.public_site_enabled, false) then s.hero_title end,
    'hero_body', case when coalesce(s.public_site_enabled, false) then s.hero_body end,
    'contact_email', case when coalesce(s.public_site_enabled, false) then s.contact_email end
  );
end;
$$;

revoke all on function public.get_public_site(text) from public;
grant execute on function public.get_public_site(text) to anon, authenticated, service_role;
