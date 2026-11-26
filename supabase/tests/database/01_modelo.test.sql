begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

select is(
  (select count(*)::int from pg_tables where schemaname = 'public'),
  76, 'están las 76 tablas del modelo');
select is(
  (select count(*)::int from pg_class
     where relnamespace = 'public'::regnamespace and relkind = 'r' and not relrowsecurity),
  0, 'todas las tablas tienen seguridad por fila');

insert into public.profiles (id) values ('00000000-0000-0000-0000-000000000001');
insert into public.providers (id, owner_id, name, slug) values
  ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Salón de prueba', 'salon-prueba');
insert into public.provider_contacts (provider_id, phone) values
  ('00000000-0000-0000-0000-000000000002', '3110000000');
insert into public.resources (id, provider_id, name) values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000002', 'Salón 1'),
  ('00000000-0000-0000-0000-0000000000a2', '00000000-0000-0000-0000-000000000002', 'Salón 2');

select lives_ok($$
  insert into public.resource_slots (resource_id, during, kind) values
  ('00000000-0000-0000-0000-0000000000a1', '[2027-06-19 14:00-07, 2027-06-19 20:00-07)', 'bloqueo')
$$, 'se puede ocupar un horario libre');
select throws_ok($$
  insert into public.resource_slots (resource_id, during, kind) values
  ('00000000-0000-0000-0000-0000000000a1', '[2027-06-19 14:00-07, 2027-06-19 20:00-07)', 'bloqueo')
$$, '23P01', null, 'no se puede ocupar dos veces el mismo horario');
select throws_ok($$
  insert into public.resource_slots (resource_id, during, kind) values
  ('00000000-0000-0000-0000-0000000000a1', '[2027-06-19 00:00-07, 2027-06-20 00:00-07)', 'bloqueo')
$$, '23P01', null, 'un día completo choca con un turno de ese día');
select lives_ok($$
  insert into public.resource_slots (resource_id, during, kind) values
  ('00000000-0000-0000-0000-0000000000a1', '[2027-06-19 20:00-07, 2027-06-20 02:00-07)', 'bloqueo')
$$, 'un turno que empieza cuando termina el otro sí cabe');
select lives_ok($$
  insert into public.resource_slots (resource_id, during, kind) values
  ('00000000-0000-0000-0000-0000000000a2', '[2027-06-19 14:00-07, 2027-06-19 20:00-07)', 'bloqueo')
$$, 'otro recurso puede ocuparse a la misma hora');

insert into public.audit_logs (action, entity) values ('prueba', 'prueba');
select throws_ok($$ delete from public.audit_logs $$,
  'P0001', null, 'la bitácora no se puede borrar');

set local role anon;
select is((select count(*)::int from public.provider_contacts), 0,
  'un visitante no ve el contacto de ningún proveedor');
select throws_ok($$
  insert into public.resource_slots (resource_id, during, kind) values
  ('00000000-0000-0000-0000-0000000000a1', '[2028-01-01 10:00-07, 2028-01-01 12:00-07)', 'bloqueo')
$$, '42501', null, 'un visitante no puede ocupar fechas directamente');
reset role;

select * from finish();
rollback;
