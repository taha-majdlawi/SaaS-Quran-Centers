-- Local development seed data. Not applied in production.

insert into public.plans (code, name, price_cents, currency, limits, features) values
  ('starter', 'Starter', 0, 'USD', '{"max_students": 50, "max_teachers": 5}', '{"chat": true, "market": false}'),
  ('growth', 'Growth', 2900, 'USD', '{"max_students": 300, "max_teachers": 25}', '{"chat": true, "market": true}'),
  ('enterprise', 'Enterprise', 9900, 'USD', '{"max_students": null, "max_teachers": null}', '{"chat": true, "market": true, "custom_domain": true}')
on conflict (code) do nothing;

insert into public.juz_reference (number, name) values
  (1, 'الجزء الأول'), (2, 'الجزء الثاني'), (3, 'الجزء الثالث'), (4, 'الجزء الرابع'),
  (5, 'الجزء الخامس'), (6, 'الجزء السادس'), (7, 'الجزء السابع'), (8, 'الجزء الثامن'),
  (9, 'الجزء التاسع'), (10, 'الجزء العاشر'), (11, 'الجزء الحادي عشر'), (12, 'الجزء الثاني عشر'),
  (13, 'الجزء الثالث عشر'), (14, 'الجزء الرابع عشر'), (15, 'الجزء الخامس عشر'), (16, 'الجزء السادس عشر'),
  (17, 'الجزء السابع عشر'), (18, 'الجزء الثامن عشر'), (19, 'الجزء التاسع عشر'), (20, 'الجزء العشرون'),
  (21, 'الجزء الحادي والعشرون'), (22, 'الجزء الثاني والعشرون'), (23, 'الجزء الثالث والعشرون'), (24, 'الجزء الرابع والعشرون'),
  (25, 'الجزء الخامس والعشرون'), (26, 'الجزء السادس والعشرون'), (27, 'الجزء السابع والعشرون'), (28, 'الجزء الثامن والعشرون'),
  (29, 'الجزء التاسع والعشرون'), (30, 'الجزء الثلاثون')
on conflict (number) do nothing;

-- Demo tenant for local development against `apps/web` and `apps/mobile`.
insert into public.organizations (id, name, slug, status, plan_id)
select '00000000-0000-0000-0000-000000000001', 'مركز اقرأ التجريبي', 'demo',
       'active', (select id from public.plans where code = 'growth')
where not exists (select 1 from public.organizations where slug = 'demo');
