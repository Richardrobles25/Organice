-- Eventos y reservas. Toda reserva pertenece a un evento.

create type public.booking_status as enum (
  'esperando_pago', 'confirmada', 'anticipo_pagado', 'pagada', 'completada', 'expirada', 'cancelada'
);

create table public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  kind text not null check (kind in ('fijo', 'porcentaje')),
  value numeric(12, 2) not null check (value > 0),
  starts_at timestamptz,
  ends_at timestamptz,
  max_uses int check (max_uses > 0),
  category_id uuid references public.categories,
  provider_id uuid references public.providers,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (kind <> 'porcentaje' or value <= 100)
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles,
  type text,
  name text,
  date date,
  guest_count int check (guest_count > 0),
  budget numeric(12, 2) check (budget >= 0),
  status text not null default 'borrador' check (status in ('borrador', 'activo', 'pasado', 'cancelado')),
  wizard_step int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Los montos se copian al crear la reserva: un cambio de precio no altera reservas viejas.
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events,
  user_id uuid not null references public.profiles,
  provider_id uuid not null references public.providers,
  service_id uuid not null references public.services,
  resource_id uuid not null references public.resources,
  during tstzrange not null
    check (not isempty(during) and not lower_inf(during) and not upper_inf(during)),
  guest_count int check (guest_count > 0),
  notes text,
  status public.booking_status not null,
  total numeric(12, 2) not null check (total >= 0),
  deposit_amount numeric(12, 2) not null check (deposit_amount >= 0),
  user_fee numeric(12, 2) not null default 0 check (user_fee >= 0),
  commission_rate numeric(5, 4) not null check (commission_rate between 0 and 1),
  commission_amount numeric(12, 2) not null check (commission_amount >= 0),
  discount numeric(12, 2) not null default 0 check (discount >= 0),
  coupon_id uuid references public.coupons,
  confirmed_at timestamptz,
  deposit_due_at timestamptz,
  provider_free_cancel_until timestamptz,
  cancelled_at timestamptz,
  cancelled_by text check (cancelled_by in ('usuario', 'proveedor', 'admin', 'sistema')),
  cancel_reason text,
  policy_snapshot jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (deposit_amount <= total),
  check (status <> 'cancelada' or (cancelled_at is not null and cancelled_by is not null)),
  check (cancelled_by <> 'proveedor' or cancel_reason is not null)
);

-- Cada rango ocupado: reservas, apartados temporales, bloqueos y calendarios externos.
-- La restricción de exclusión hace imposible la doble reserva (RF-068). Solo se escribe por RPC.
-- Al cancelar o expirar una reserva se borra su fila.
create table public.resource_slots (
  id uuid primary key default gen_random_uuid(),
  resource_id uuid not null references public.resources,
  during tstzrange not null
    check (not isempty(during) and not lower_inf(during) and not upper_inf(during)),
  kind text not null check (kind in ('reserva', 'apartado_temporal', 'bloqueo', 'externo')),
  booking_id uuid unique references public.bookings,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (kind <> 'reserva' or booking_id is not null),
  check (kind <> 'apartado_temporal' or expires_at is not null),
  constraint resource_slots_sin_traslape exclude using gist (resource_id with =, during with &&)
);

create table public.event_items (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events on delete cascade,
  service_id uuid not null references public.services,
  booking_id uuid references public.bookings,
  estimated_price numeric(12, 2) check (estimated_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.event_templates (
  id uuid primary key default gen_random_uuid(),
  event_type text not null unique,
  items jsonb not null default '[]',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.event_tasks (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events on delete cascade,
  title text not null,
  essential boolean not null default false,
  done_at timestamptz,
  remind_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.booking_addons (
  booking_id uuid not null references public.bookings on delete cascade,
  addon_id uuid not null references public.service_addons,
  quantity int not null default 1 check (quantity > 0),
  price numeric(12, 2) not null check (price >= 0),
  created_at timestamptz not null default now(),
  primary key (booking_id, addon_id)
);

-- Cambios y reprogramaciones: la reserva conserva su estado y aquí queda el historial.
create table public.booking_changes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings,
  requested_by uuid not null references public.profiles,
  before jsonb not null,
  after jsonb not null,
  status text not null default 'solicitado' check (status in ('solicitado', 'aprobado', 'rechazado')),
  fee numeric(12, 2) not null default 0 check (fee >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.quote_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles,
  provider_id uuid not null references public.providers,
  event_id uuid references public.events,
  date date,
  guest_count int check (guest_count > 0),
  requirements text,
  budget numeric(12, 2) check (budget >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.quote_requests on delete cascade,
  amount numeric(12, 2) not null check (amount >= 0),
  detail text,
  valid_until timestamptz not null,
  status text not null default 'enviada' check (status in ('enviada', 'aceptada', 'rechazada', 'vencida')),
  booking_id uuid references public.bookings,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.visits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles,
  provider_id uuid not null references public.providers,
  scheduled_at timestamptz not null,
  status text not null default 'confirmada' check (status in ('confirmada', 'cancelada', 'realizada')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.visit_hours (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  weekday int not null check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (start_time < end_time)
);

-- user_id vacío = plantilla general.
create table public.visit_questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles on delete cascade,
  category_id uuid references public.categories,
  provider_id uuid references public.providers,
  question text not null,
  asked boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid not null references public.coupons,
  booking_id uuid not null unique references public.bookings,
  user_id uuid not null references public.profiles,
  created_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.coupons enable row level security;
alter table public.events enable row level security;
alter table public.bookings enable row level security;
alter table public.resource_slots enable row level security;
alter table public.event_items enable row level security;
alter table public.event_templates enable row level security;
alter table public.event_tasks enable row level security;
alter table public.booking_addons enable row level security;
alter table public.booking_changes enable row level security;
alter table public.quote_requests enable row level security;
alter table public.quotes enable row level security;
alter table public.visits enable row level security;
alter table public.visit_hours enable row level security;
alter table public.visit_questions enable row level security;
alter table public.coupon_redemptions enable row level security;

create trigger coupons_updated_at before update on public.coupons
  for each row execute function public.set_updated_at();
create trigger events_updated_at before update on public.events
  for each row execute function public.set_updated_at();
create trigger bookings_updated_at before update on public.bookings
  for each row execute function public.set_updated_at();
create trigger resource_slots_updated_at before update on public.resource_slots
  for each row execute function public.set_updated_at();
create trigger event_items_updated_at before update on public.event_items
  for each row execute function public.set_updated_at();
create trigger event_templates_updated_at before update on public.event_templates
  for each row execute function public.set_updated_at();
create trigger event_tasks_updated_at before update on public.event_tasks
  for each row execute function public.set_updated_at();
create trigger booking_changes_updated_at before update on public.booking_changes
  for each row execute function public.set_updated_at();
create trigger quote_requests_updated_at before update on public.quote_requests
  for each row execute function public.set_updated_at();
create trigger quotes_updated_at before update on public.quotes
  for each row execute function public.set_updated_at();
create trigger visits_updated_at before update on public.visits
  for each row execute function public.set_updated_at();
create trigger visit_hours_updated_at before update on public.visit_hours
  for each row execute function public.set_updated_at();
create trigger visit_questions_updated_at before update on public.visit_questions
  for each row execute function public.set_updated_at();
