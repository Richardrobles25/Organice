-- Proveedores y catálogo.

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles,
  name text not null,
  slug text not null unique,
  description text,
  history text,
  founded_year int check (founded_year between 1900 and 2100),
  colonia text,
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  coverage_km numeric(6, 1) check (coverage_km >= 0),
  business_hours jsonb,
  status text not null default 'pendiente'
    check (status in ('pendiente', 'aprobado', 'rechazado', 'falta_info', 'suspendido')),
  verified_at timestamptz,
  premium_badge boolean not null default false,
  is_founder boolean not null default false,
  deposit_pct int not null default 30 check (deposit_pct between 20 and 50),
  requires_deposit_to_book boolean not null default true,
  -- Las opciones de política siguen por definir (regla X01).
  cancellation_policy text,
  payment_account_id text,
  payout_frequency text not null default 'semanal' check (payout_frequency in ('semanal', 'quincenal')),
  rating_avg numeric(3, 2) check (rating_avg between 1 and 5),
  -- Solo internas: nunca se muestran al público.
  cancel_rate numeric(5, 4) not null default 0 check (cancel_rate between 0 and 1),
  closing_rate numeric(5, 4) check (closing_rate between 0 and 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Aparte de providers para que RLS lo muestre solo a quien apartó con el anticipo pagado.
create table public.provider_contacts (
  provider_id uuid primary key references public.providers on delete cascade,
  phone text,
  whatsapp text,
  email text,
  social jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.provider_documents (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  type text not null,
  file_path text not null,
  status text not null default 'pendiente' check (status in ('pendiente', 'aprobado', 'rechazado')),
  reviewed_by uuid references public.profiles,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RFC y CLABE cifrados a nivel de campo.
create table public.provider_billing (
  provider_id uuid primary key references public.providers on delete cascade,
  rfc_enc bytea,
  clabe_enc bytea,
  bank text,
  holder text,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.provider_contracts (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers,
  version text not null,
  signed_at timestamptz not null default now(),
  ip inet,
  pdf_path text,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories,
  name text not null,
  slug text not null unique,
  icon text,
  color text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.provider_categories (
  provider_id uuid not null references public.providers on delete cascade,
  category_id uuid not null references public.categories,
  created_at timestamptz not null default now(),
  primary key (provider_id, category_id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers,
  category_id uuid not null references public.categories,
  name text not null,
  description text,
  capacity_min int check (capacity_min > 0),
  capacity_max int check (capacity_max > 0),
  duration_min int check (duration_min > 0),
  attributes jsonb not null default '{}',
  included_items text[] not null default '{}',
  search_vector tsvector generated always as (
    to_tsvector('spanish'::regconfig, name || ' ' || coalesce(description, ''))
  ) stored,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (capacity_min is null or capacity_max is null or capacity_min <= capacity_max)
);
create index services_search_idx on public.services using gin (search_vector);

create table public.service_addons (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services on delete cascade,
  name text not null,
  price numeric(12, 2) not null check (price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.amenities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references public.categories,
  created_at timestamptz not null default now()
);

create table public.service_amenities (
  service_id uuid not null references public.services on delete cascade,
  amenity_id uuid not null references public.amenities on delete cascade,
  created_at timestamptz not null default now(),
  primary key (service_id, amenity_id)
);

create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  name text not null,
  start_time time not null,
  -- Puede ser menor que start_time si el turno termina después de medianoche.
  end_time time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.prices (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services on delete cascade,
  unit text not null check (unit in ('fijo', 'persona', 'hora', 'dia')),
  amount numeric(12, 2) not null check (amount >= 0),
  season_start date,
  season_end date,
  weekday int check (weekday between 0 and 6),
  shift_id uuid references public.shifts,
  early_discount_pct int check (early_discount_pct between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.media (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  service_id uuid references public.services on delete cascade,
  type text not null check (type in ('foto', 'video', 'tour360')),
  url text not null,
  section text,
  position int not null default 0,
  is_main boolean not null default false,
  moderation_status text not null default 'pendiente'
    check (moderation_status in ('pendiente', 'aprobado', 'rechazado')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.floor_plans (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  owner_id uuid not null references public.profiles,
  layout jsonb not null default '{}',
  capacity int check (capacity >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.providers enable row level security;
alter table public.provider_contacts enable row level security;
alter table public.provider_documents enable row level security;
alter table public.provider_billing enable row level security;
alter table public.provider_contracts enable row level security;
alter table public.categories enable row level security;
alter table public.provider_categories enable row level security;
alter table public.services enable row level security;
alter table public.service_addons enable row level security;
alter table public.amenities enable row level security;
alter table public.service_amenities enable row level security;
alter table public.shifts enable row level security;
alter table public.prices enable row level security;
alter table public.media enable row level security;
alter table public.floor_plans enable row level security;

create trigger providers_updated_at before update on public.providers
  for each row execute function public.set_updated_at();
create trigger provider_contacts_updated_at before update on public.provider_contacts
  for each row execute function public.set_updated_at();
create trigger provider_documents_updated_at before update on public.provider_documents
  for each row execute function public.set_updated_at();
create trigger provider_billing_updated_at before update on public.provider_billing
  for each row execute function public.set_updated_at();
create trigger categories_updated_at before update on public.categories
  for each row execute function public.set_updated_at();
create trigger services_updated_at before update on public.services
  for each row execute function public.set_updated_at();
create trigger service_addons_updated_at before update on public.service_addons
  for each row execute function public.set_updated_at();
create trigger shifts_updated_at before update on public.shifts
  for each row execute function public.set_updated_at();
create trigger prices_updated_at before update on public.prices
  for each row execute function public.set_updated_at();
create trigger media_updated_at before update on public.media
  for each row execute function public.set_updated_at();
create trigger floor_plans_updated_at before update on public.floor_plans
  for each row execute function public.set_updated_at();
