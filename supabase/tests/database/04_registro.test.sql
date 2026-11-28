-- Cimiento 1.6. Al crearse una cuenta en Supabase Auth se crean su perfil, su rol y sus consentimientos.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

-- Crea una cuenta como lo hace Supabase Auth con signUp, con los datos que manda la app.
create function pg_temp.registrar(n int, datos jsonb) returns uuid language sql as $$
  insert into auth.users (instance_id, id, aud, role, email, raw_user_meta_data, created_at, updated_at)
  values ('00000000-0000-0000-0000-000000000000',
          ('90000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid,
          'authenticated', 'authenticated', 'registro' || n || '@ejemplo.test', datos, now(), now())
  returning id
$$;

create temp table r as select
  pg_temp.registrar(1, '{"full_name": " Ana ", "last_name": "Ramírez", "terms_version": "2026-11",
                         "privacy_version": "2026-11"}') as usuario,
  pg_temp.registrar(2, '{"full_name": "Luis", "account_type": "proveedor", "terms_version": "2026-11",
                         "privacy_version": "2026-11"}') as proveedor,
  pg_temp.registrar(3, '{"full_name": "Intruso", "account_type": "admin"}') as quiere_admin,
  pg_temp.registrar(4, null) as sin_datos;

-- Usuario normal
select is((select full_name from public.profiles where id = (select usuario from r)), 'Ana',
  'usuario: se crea su perfil con el nombre sin espacios de más');
select is((select last_name from public.profiles where id = (select usuario from r)), 'Ramírez',
  'usuario: guarda los apellidos');
select is((select status from public.profiles where id = (select usuario from r)), 'activa',
  'usuario: la cuenta nace activa');
select results_eq($$ select role from public.user_roles where profile_id = (select usuario from r) $$,
  $$ values ('usuario') $$, 'usuario: recibe solo el rol usuario');
select results_eq(
  $$ select document, version from public.consents where profile_id = (select usuario from r) order by document $$,
  $$ values ('privacidad', '2026-11'), ('terminos', '2026-11') $$,
  'usuario: guarda términos y aviso de privacidad con su versión');

-- Proveedor
select results_eq($$ select role from public.user_roles where profile_id = (select proveedor from r) $$,
  $$ values ('proveedor') $$, 'proveedor: recibe el rol proveedor');
select is((select count(*)::int from public.consents where profile_id = (select proveedor from r)), 2,
  'proveedor: guarda sus dos consentimientos');
select is((select count(*)::int from public.providers where owner_id = (select proveedor from r)), 0,
  'proveedor: el negocio todavía no se crea (es del bloque B1)');

-- Nadie se vuelve admin al registrarse
select results_eq($$ select role from public.user_roles where profile_id = (select quiere_admin from r) $$,
  $$ values ('usuario') $$, 'pedir account_type admin da el rol usuario');
select is((select count(*)::int from public.user_roles where role = 'admin'
            and profile_id in (select quiere_admin from r)), 0, 'nadie se vuelve admin al registrarse');

-- Sin datos (por ejemplo, un login social futuro)
select isnt((select id from public.profiles where id = (select sin_datos from r)), null,
  'sin datos: igual se crea el perfil');
select is((select full_name from public.profiles where id = (select sin_datos from r)), null,
  'sin datos: el nombre queda vacío');
select results_eq($$ select role from public.user_roles where profile_id = (select sin_datos from r) $$,
  $$ values ('usuario') $$, 'sin datos: recibe el rol usuario');
select is((select count(*)::int from public.consents where profile_id = (select sin_datos from r)), 0,
  'sin datos: no inventa consentimientos');

-- La función solo la usa el trigger
select ok(not has_function_privilege('authenticated', 'private.handle_new_user()', 'execute'),
  'la app no puede llamar la función del registro');

select * from finish();
rollback;
