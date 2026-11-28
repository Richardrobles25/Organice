-- Cimiento 1.6 · Registro: al crearse una cuenta en Supabase Auth se crean su perfil, su rol y sus
-- consentimientos (RF-001, RF-009 y roles). Ver docs/permisos.md.
--
-- La app manda estos datos en `supabase.auth.signUp({ options: { data } })`:
--   full_name, last_name     nombre y apellidos
--   account_type             'usuario' (por defecto) o 'proveedor'
--   terms_version            versión de los términos que aceptó
--   privacy_version          versión del aviso de privacidad que aceptó
--
-- Esos datos los escribe la persona, así que no se confía en ellos:
--   - El rol solo puede ser 'usuario' o 'proveedor'. 'admin' nunca se asigna al registrarse.
--   - Cada consentimiento se guarda solo si trae su versión. La app no deja registrarse sin aceptar
--     (casilla obligatoria de RF-001); el login con Google o Facebook (bloque B8) los pedirá aparte.

create function private.handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  tipo text := case when meta ->> 'account_type' = 'proveedor' then 'proveedor' else 'usuario' end;
  terminos text := nullif(btrim(meta ->> 'terms_version'), '');
  privacidad text := nullif(btrim(meta ->> 'privacy_version'), '');
begin
  insert into public.profiles (id, full_name, last_name)
  values (new.id,
          nullif(btrim(meta ->> 'full_name'), ''),
          nullif(btrim(meta ->> 'last_name'), ''));

  insert into public.user_roles (profile_id, role) values (new.id, tipo);

  if terminos is not null then
    insert into public.consents (profile_id, document, version) values (new.id, 'terminos', terminos);
  end if;
  if privacidad is not null then
    insert into public.consents (profile_id, document, version) values (new.id, 'privacidad', privacidad);
  end if;

  return new;
end $$;

-- Solo la usa el trigger; nadie la puede llamar desde la API.
revoke execute on function private.handle_new_user() from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();
