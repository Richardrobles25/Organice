-- Cimiento 1.9: comprueba lo que carga supabase/seed.sql (`npm run db:reset`).
begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

select is((select count(*)::int from public.providers), 30, '30 proveedores');
select is((select count(*)::int from public.user_roles where role = 'usuario'), 20, '20 usuarios');
select is((select count(*)::int from public.bookings), 50, '50 reservas');
select is((select count(distinct status)::int from public.bookings), 7,
  'hay reservas en los 7 estados');
select is((select count(distinct category_id)::int from public.services), 7,
  'hay servicios en las 7 categorías');
select is(
  (select count(*)::int from public.bookings b
    where b.status not in ('cancelada', 'expirada')
      and not exists (select 1 from public.resource_slots s where s.booking_id = b.id)),
  0, 'toda reserva vigente tiene su horario ocupado');
select is(
  (select count(*)::int from public.resource_slots s join public.bookings b on b.id = s.booking_id
    where b.status in ('cancelada', 'expirada')),
  0, 'las canceladas y expiradas liberan la fecha');
select is(
  (select count(*)::int from public.bookings
    where deposit_amount < least(500, total) or deposit_amount > total),
  0, 'los anticipos respetan el mínimo');
select is(
  (select count(*)::int from public.bookings b join public.events e on e.id = b.event_id
    where b.user_id <> e.user_id or (lower(b.during) at time zone 'America/Mazatlan')::date <> e.date),
  0, 'cada reserva coincide con el usuario y la fecha de su evento');

select * from finish();
rollback;
