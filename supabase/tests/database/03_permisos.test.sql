-- Cimiento 1.4. Usa los datos de supabase/seed.sql y se hace pasar por cada tipo de persona.
begin;
create extension if not exists pgtap with schema extensions;
select plan(44);

-- Quién es quién (se averigua como administrador de la base, antes de cambiar de rol).
create temp table t as
select
  b15.user_id        as pagador,      -- ya pagó el anticipo en la reserva 15
  p15.owner_id       as dueno,        -- dueño del proveedor de la reserva 15
  b15.provider_id    as proveedor,
  b15.id             as reserva_pagada,
  b33.id             as reserva_sin_pago,
  p33.owner_id       as dueno_sin_pago,
  b33.provider_id    as proveedor_sin_pago,
  b33.user_id        as usuario_sin_pago,
  b11.id             as reserva_a_ciegas,
  p11.owner_id       as dueno_a_ciegas,
  '10000000-0000-4000-8000-000000000099'::uuid as admin,
  (select u.profile_id from public.user_roles u
    where u.role = 'usuario'
      and not exists (select 1 from public.bookings x where x.user_id = u.profile_id and x.provider_id = b15.provider_id)
    order by 1 limit 1) as ajeno,
  (select id from public.conversations order by id limit 1) as chat
from public.bookings b15 join public.providers p15 on p15.id = b15.provider_id,
     public.bookings b33 join public.providers p33 on p33.id = b33.provider_id,
     public.bookings b11 join public.providers p11 on p11.id = b11.provider_id
where b15.id = '70000000-0000-4000-8000-000000000015'
  and b33.id = '70000000-0000-4000-8000-000000000033'
  and b11.id = '70000000-0000-4000-8000-000000000011';
grant select on t to anon, authenticated;

create function pg_temp.soy(quien uuid) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object('sub', quien, 'role', 'authenticated')::text, true)
$$;

-- ---------- Estructura
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema = 'public' and grantee in ('anon', 'authenticated')
      and privilege_type in ('TRUNCATE', 'REFERENCES', 'TRIGGER')),
  0, 'la app no puede vaciar tablas ni crearles llaves o disparadores');

-- ---------- Visitante
set local role anon;
select is((select count(*)::int from public.providers), 27, 'visitante: solo proveedores aprobados');
select throws_ok('select cancel_rate from public.providers', '42501', null,
  'visitante: no ve la tasa de cancelación');
select throws_ok('select * from public.profiles', '42501', null, 'visitante: no ve perfiles');
select throws_ok('select * from public.bookings', '42501', null, 'visitante: no ve reservas');
select ok((select count(*) from public.resource_slots) > 0, 'visitante: ve qué está ocupado');
select throws_ok('select booking_id from public.resource_slots', '42501', null,
  'visitante: no sabe quién lo ocupa');
select is((select count(*)::int from public.reviews where published_at is null), 0,
  'visitante: no ve reseñas sin publicar');
select is((select count(*)::int from public.get_invitation('prueba-invitado-1')), 1,
  'invitado: abre su invitación con el enlace');
select lives_ok($$ select public.rsvp_invitation('prueba-invitado-1', 'confirmado', 1) $$,
  'invitado: confirma asistencia');
select throws_ok($$ select public.rsvp_invitation('prueba-invitado-1', 'confirmado', 9) $$,
  '22023', null, 'invitado: no puede llevar más acompañantes de los permitidos');
reset role;

-- ---------- Usuario
select pg_temp.soy((select ajeno from t));
set local role authenticated;
select is((select count(*)::int from public.profiles), 1, 'usuario: solo ve su perfil');
select is((select count(*)::int from public.bookings where user_id <> (select ajeno from t)), 0,
  'usuario: no ve reservas de otros');
select is((select count(*)::int from public.provider_contacts where provider_id = (select proveedor from t)), 0,
  'usuario sin pago: no ve el teléfono del proveedor');
select throws_ok($$ insert into public.user_roles values ((select ajeno from t), 'admin') $$,
  '42501', null, 'usuario: no puede hacerse administrador');
select throws_ok($$ update public.profiles set status = 'activa' $$, '42501', null,
  'usuario: no puede cambiar el estado de su cuenta');
select throws_ok($$ update public.bookings set total = 1 $$, '42501', null,
  'usuario: no puede cambiar reservas directamente');
select throws_ok($$ select commission_rate from public.bookings $$, '42501', null,
  'usuario: no lee la comisión');
select lives_ok($$ insert into public.events (user_id, name) values ((select ajeno from t), 'Mi fiesta') $$,
  'usuario: crea su evento');
select throws_ok($$ insert into public.events (user_id, name) values ((select pagador from t), 'Ajeno') $$,
  '42501', null, 'usuario: no crea eventos a nombre de otro');
select lives_ok($$ insert into public.conversations (user_id, provider_id)
    values ((select ajeno from t), (select proveedor from t))
    on conflict (user_id, provider_id) do nothing $$, 'usuario: abre un chat con un proveedor');
select lives_ok($$ insert into public.messages (conversation_id, sender_id, body)
    select id, user_id, 'Hola' from public.conversations
     where user_id = (select ajeno from t) and provider_id = (select proveedor from t) $$,
  'usuario: escribe a un proveedor');
select lives_ok($$ update public.profiles set full_name = 'Nombre nuevo' where id = (select ajeno from t) $$,
  'usuario: edita su perfil');
reset role;

select pg_temp.soy((select pagador from t));
set local role authenticated;
select is((select count(*)::int from public.provider_contacts where provider_id = (select proveedor from t)), 1,
  'usuario con anticipo pagado: sí ve el teléfono');
select is((select count(*)::int from public.client_reviews), 0,
  'cliente: no lee lo que los proveedores opinan de él');
select lives_ok('select public.my_client_rating()', 'cliente: sí puede ver su promedio');
reset role;

-- ---------- Proveedor
select pg_temp.soy((select dueno from t));
set local role authenticated;
select is((select count(*)::int from public.bookings where provider_id <> (select proveedor from t)
    and user_id <> (select dueno from t)), 0, 'proveedor: solo ve las reservas de su negocio');
select isnt((select phone from public.booking_client((select reserva_pagada from t))), null,
  'proveedor: ve el teléfono del cliente que pagó');
select is((select count(*)::int from public.profiles where id = (select pagador from t)), 0,
  'proveedor: no lee la tabla de perfiles de sus clientes');
select lives_ok($$ update public.providers set description = 'Nueva' where id = (select proveedor from t) $$,
  'proveedor: edita su descripción');
select lives_ok($$ update public.prices set amount = amount
    where service_id in (select id from public.services where provider_id = (select proveedor from t)) $$,
  'proveedor: edita sus precios');
select throws_ok($$ update public.providers set premium_badge = true $$, '42501', null,
  'proveedor: no se pone solo el distintivo Premium');
select is((select count(*)::int from public.my_provider_internal((select proveedor from t))), 1,
  'proveedor: ve sus datos internos');
select is((select count(*)::int from public.my_provider_internal((select proveedor_sin_pago from t))), 0,
  'proveedor: no ve los datos internos de otro');
reset role;

select pg_temp.soy((select dueno_sin_pago from t));
set local role authenticated;
select is((select phone from public.booking_client((select reserva_sin_pago from t))), null,
  'proveedor: sin anticipo no ve el teléfono del cliente');
select isnt((select full_name from public.booking_client((select reserva_sin_pago from t))), null,
  'proveedor: sin anticipo sí ve el nombre');
select is((select count(*)::int from public.booking_client((select reserva_pagada from t))),
  (select case when dueno = dueno_sin_pago then 1 else 0 end from t),
  'proveedor: no consulta clientes de reservas ajenas');
reset role;

select pg_temp.soy((select dueno_a_ciegas from t));
set local role authenticated;
select is((select count(*)::int from public.reviews where booking_id = (select reserva_a_ciegas from t)), 0,
  'a ciegas: el proveedor no ve la reseña antes de publicarse');
reset role;

-- ---------- Administración
select pg_temp.soy((select admin from t));
set local role authenticated;
select is((select count(*)::int from public.bookings), 50, 'admin: ve todas las reservas');
select is((select count(*)::int from public.messages), 0, 'admin: no lee chats directo');
select throws_ok($$ select * from public.admin_read_conversation((select chat from t)) $$,
  '42501', null, 'admin: sin disputa no puede abrir un chat');
reset role;

insert into public.disputes (booking_id, opened_by, description)
select b.id, b.user_id, 'Disputa de prueba'
  from public.conversations c
  join public.bookings b on b.user_id = c.user_id
 where c.id = (select chat from t) limit 1;
update public.bookings set provider_id = (select provider_id from public.conversations where id = (select chat from t))
 where id = (select booking_id from public.disputes order by created_at desc limit 1);

set local role authenticated;
select ok((select count(*) from public.admin_read_conversation((select chat from t))) > 0,
  'admin: con disputa sí puede');
select is((select count(*)::int from public.audit_logs where action = 'leer_chat'), 1,
  'admin: queda anotado en la bitácora');
reset role;

select pg_temp.soy((select ajeno from t));
set local role authenticated;
select throws_ok($$ select * from public.admin_read_conversation((select chat from t)) $$,
  '42501', null, 'usuario: no puede usar la función de administración');
reset role;

select * from finish();
rollback;
