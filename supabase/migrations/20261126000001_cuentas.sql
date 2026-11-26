-- Cimiento 1.3 · Base: extensiones, utilidades, cuentas y privacidad.
-- La contraseña, el login social, la verificación, el 2FA y las sesiones viven en auth.* (Supabase Auth).

create extension if not exists btree_gist with schema extensions;

create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

-- id = auth.users.id. Sin llave foránea a propósito: al eliminar la cuenta (RF-012) se borra el
-- usuario de Auth y el perfil queda anonimizado para no perder el historial de reservas.
create table public.profiles (
  id uuid primary key,
  full_name text,
  last_name text,
  phone text,
  phone_verified_at timestamptz,
  avatar_url text,
  birth_date date,
  favorite_event_type text,
  status text not null default 'activa'
    check (status in ('activa', 'suspendida', 'bloqueada', 'eliminada')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_roles (
  profile_id uuid not null references public.profiles on delete cascade,
  role text not null check (role in ('usuario', 'proveedor', 'admin')),
  created_at timestamptz not null default now(),
  primary key (profile_id, role)
);

create table public.consents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles,
  document text not null check (document in ('terminos', 'privacidad', 'cookies')),
  version text not null,
  accepted_at timestamptz not null default now(),
  ip inet,
  created_at timestamptz not null default now()
);

create table public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles,
  type text not null
    check (type in ('acceso', 'rectificacion', 'cancelacion', 'oposicion', 'portabilidad', 'eliminacion')),
  status text not null default 'abierta' check (status in ('abierta', 'en_proceso', 'resuelta', 'rechazada')),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_sanctions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles,
  type text not null check (type in ('advertencia', 'suspension', 'bloqueo')),
  reason text not null,
  ends_at timestamptz,
  admin_id uuid not null references public.profiles,
  created_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.profiles enable row level security;
alter table public.user_roles enable row level security;
alter table public.consents enable row level security;
alter table public.privacy_requests enable row level security;
alter table public.user_sanctions enable row level security;

create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
create trigger privacy_requests_updated_at before update on public.privacy_requests
  for each row execute function public.set_updated_at();
