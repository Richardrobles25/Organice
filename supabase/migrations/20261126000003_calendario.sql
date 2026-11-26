-- Calendario y disponibilidad. resource_slots (tabla compartida) se crea junto con las reservas.

create table public.resources (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers,
  name text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.service_resources (
  service_id uuid not null references public.services on delete cascade,
  resource_id uuid not null references public.resources on delete cascade,
  created_at timestamptz not null default now(),
  primary key (service_id, resource_id)
);

-- Bloqueos recurrentes y cierres temporales.
create table public.availability (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references public.resources on delete cascade,
  weekday int check (weekday between 0 and 6),
  shift_id uuid references public.shifts,
  from_date date,
  to_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (from_date is null or to_date is null or from_date <= to_date)
);

create table public.calendar_connections (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  type text not null check (type in ('google', 'ical')),
  tokens_enc bytea,
  ical_url text,
  sync_minutes int not null default 15 check (sync_minutes > 0),
  last_sync_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.external_events (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.calendar_connections on delete cascade,
  external_id text not null,
  during tstzrange not null,
  conflict boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (connection_id, external_id)
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.resources enable row level security;
alter table public.service_resources enable row level security;
alter table public.availability enable row level security;
alter table public.calendar_connections enable row level security;
alter table public.external_events enable row level security;

create trigger resources_updated_at before update on public.resources
  for each row execute function public.set_updated_at();
create trigger availability_updated_at before update on public.availability
  for each row execute function public.set_updated_at();
create trigger calendar_connections_updated_at before update on public.calendar_connections
  for each row execute function public.set_updated_at();
create trigger external_events_updated_at before update on public.external_events
  for each row execute function public.set_updated_at();
