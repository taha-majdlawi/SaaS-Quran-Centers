-- the market-image trigger function (0036) kept the default PUBLIC execute; close it like every other internal function
revoke all on function public._check_market_image() from public, anon, authenticated;
grant execute on function public.get_invitation(uuid) to anon;
