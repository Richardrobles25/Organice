-- Pagos y dinero. Nunca se guardan datos de tarjetas, solo referencias de la pasarela.

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings,
  kind text not null check (kind in ('anticipo', 'saldo', 'total')),
  method text not null check (method in ('tarjeta', 'oxxo', 'spei')),
  msi int check (msi in (3, 6, 9, 12)),
  amount numeric(12, 2) not null check (amount > 0),
  platform_fee numeric(12, 2) not null default 0 check (platform_fee >= 0),
  gateway_fee numeric(12, 2) not null default 0 check (gateway_fee >= 0),
  provider_amount numeric(12, 2) not null default 0 check (provider_amount >= 0),
  gateway text not null check (gateway in ('stripe', 'conekta')),
  gateway_ref text,
  status text not null default 'pendiente'
    check (status in ('pendiente', 'pagado', 'fallido', 'reembolsado', 'reembolso_parcial', 'contracargo')),
  due_at timestamptz,
  paid_at timestamptz,
  release_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (gateway, gateway_ref)
);

create table public.payment_attempts (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments,
  attempt int not null check (attempt > 0),
  status text not null,
  error text,
  created_at timestamptz not null default now(),
  unique (payment_id, attempt)
);

create table public.refunds (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payments,
  amount numeric(12, 2) not null check (amount > 0),
  reason text not null,
  requested_by uuid references public.profiles,
  status text not null default 'pendiente' check (status in ('pendiente', 'procesado', 'fallido')),
  gateway_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Webhooks recibidos, para no procesar dos veces.
create table public.gateway_events (
  id uuid primary key default gen_random_uuid(),
  gateway text not null check (gateway in ('stripe', 'conekta')),
  event_id text not null,
  payload jsonb not null,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (gateway, event_id)
);

create table public.billing_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles,
  rfc_enc bytea not null,
  legal_name text not null,
  cfdi_use text,
  tax_regime text,
  zip text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Solo lo que factura ORGANICE (RF-036); el servicio lo factura el proveedor.
create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  concept text not null check (concept in ('comision', 'tarifa_servicio', 'premium')),
  receiver_id uuid not null references public.profiles,
  payment_id uuid references public.payments,
  cfdi_uuid text unique,
  xml_path text,
  pdf_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payouts (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers,
  amount numeric(12, 2) not null check (amount >= 0),
  scheduled_for date,
  paid_at timestamptz,
  gateway_ref text,
  status text not null default 'programado' check (status in ('programado', 'pagado', 'fallido')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.claims (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers,
  payout_id uuid references public.payouts,
  description text not null,
  status text not null default 'abierta' check (status in ('abierta', 'en_proceso', 'resuelta')),
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Multa por cancelar después de 24 h (monto por definir, regla X02).
create table public.provider_penalties (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers,
  booking_id uuid not null unique references public.bookings,
  amount numeric(12, 2) not null check (amount >= 0),
  status text not null default 'pendiente' check (status in ('pendiente', 'aplicada', 'condonada')),
  applied_to_payout_id uuid references public.payouts,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null unique references public.providers,
  plan text not null default 'gratuito' check (plan in ('gratuito', 'premium')),
  status text not null default 'activa' check (status in ('activa', 'suspendida', 'cancelada')),
  current_period_end timestamptz,
  next_plan text check (next_plan in ('gratuito', 'premium')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscription_charges (
  id uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions,
  amount numeric(12, 2) not null check (amount >= 0),
  attempt int not null default 1 check (attempt between 1 and 3),
  status text not null default 'pendiente' check (status in ('pendiente', 'pagado', 'fallido')),
  gateway_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings,
  opened_by uuid not null references public.profiles,
  description text not null,
  status text not null default 'abierta' check (status in ('abierta', 'en_revision', 'resuelta')),
  resolution text check (resolution in ('reembolso_total', 'reembolso_parcial', 'favor_proveedor')),
  refund_id uuid references public.refunds,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.dispute_evidence (
  id uuid primary key default gen_random_uuid(),
  dispute_id uuid not null references public.disputes on delete cascade,
  uploaded_by uuid not null references public.profiles,
  file_path text,
  note text,
  created_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.payments enable row level security;
alter table public.payment_attempts enable row level security;
alter table public.refunds enable row level security;
alter table public.gateway_events enable row level security;
alter table public.billing_profiles enable row level security;
alter table public.invoices enable row level security;
alter table public.payouts enable row level security;
alter table public.claims enable row level security;
alter table public.provider_penalties enable row level security;
alter table public.subscriptions enable row level security;
alter table public.subscription_charges enable row level security;
alter table public.disputes enable row level security;
alter table public.dispute_evidence enable row level security;

create trigger payments_updated_at before update on public.payments
  for each row execute function public.set_updated_at();
create trigger refunds_updated_at before update on public.refunds
  for each row execute function public.set_updated_at();
create trigger billing_profiles_updated_at before update on public.billing_profiles
  for each row execute function public.set_updated_at();
create trigger invoices_updated_at before update on public.invoices
  for each row execute function public.set_updated_at();
create trigger payouts_updated_at before update on public.payouts
  for each row execute function public.set_updated_at();
create trigger claims_updated_at before update on public.claims
  for each row execute function public.set_updated_at();
create trigger provider_penalties_updated_at before update on public.provider_penalties
  for each row execute function public.set_updated_at();
create trigger subscriptions_updated_at before update on public.subscriptions
  for each row execute function public.set_updated_at();
create trigger subscription_charges_updated_at before update on public.subscription_charges
  for each row execute function public.set_updated_at();
create trigger disputes_updated_at before update on public.disputes
  for each row execute function public.set_updated_at();
