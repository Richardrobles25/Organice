-- Notificaciones y administración.

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  category text not null check (category in ('reservas', 'mensajes', 'promociones', 'sistema')),
  type text not null,
  data jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  notification_id uuid not null references public.notifications on delete cascade,
  channel text not null check (channel in ('email', 'push', 'sms', 'whatsapp')),
  status text not null default 'pendiente',
  attempts int not null default 0,
  opened_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notification_preferences (
  user_id uuid not null references public.profiles on delete cascade,
  category text not null check (category in ('reservas', 'mensajes', 'promociones', 'sistema')),
  channel text not null check (channel in ('email', 'push', 'sms', 'whatsapp')),
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, category, channel)
);

create table public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  token text not null unique,
  platform text,
  created_at timestamptz not null default now()
);

create table public.notification_templates (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  channel text not null check (channel in ('email', 'push', 'sms', 'whatsapp')),
  subject text,
  body text not null,
  provider_status text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (type, channel)
);

create table public.banners (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  image_path text,
  link text,
  provider_id uuid references public.providers,
  category_id uuid references public.categories,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_by uuid references public.profiles,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Solo se agrega: no se edita ni se borra.
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles,
  action text not null,
  entity text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  ip inet,
  created_at timestamptz not null default now()
);

create function public.audit_logs_solo_insertar() returns trigger
language plpgsql set search_path = '' as $$
begin
  raise exception 'audit_logs no se puede modificar ni borrar';
end $$;

create trigger audit_logs_inmutable before update or delete on public.audit_logs
for each row execute function public.audit_logs_solo_insertar();

create table public.api_keys (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  key_hash text not null unique,
  scopes text[] not null default '{}',
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.webhooks (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers on delete cascade,
  url text not null check (url like 'https://%'),
  secret_enc bytea not null,
  events text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.webhook_deliveries (
  id uuid primary key default gen_random_uuid(),
  webhook_id uuid not null references public.webhooks on delete cascade,
  event text not null,
  status text not null default 'pendiente',
  attempts int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.notifications enable row level security;
alter table public.notification_deliveries enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.notification_templates enable row level security;
alter table public.banners enable row level security;
alter table public.app_settings enable row level security;
alter table public.audit_logs enable row level security;
alter table public.api_keys enable row level security;
alter table public.webhooks enable row level security;
alter table public.webhook_deliveries enable row level security;

create trigger notification_deliveries_updated_at before update on public.notification_deliveries
  for each row execute function public.set_updated_at();
create trigger notification_preferences_updated_at before update on public.notification_preferences
  for each row execute function public.set_updated_at();
create trigger notification_templates_updated_at before update on public.notification_templates
  for each row execute function public.set_updated_at();
create trigger banners_updated_at before update on public.banners
  for each row execute function public.set_updated_at();
create trigger app_settings_updated_at before update on public.app_settings
  for each row execute function public.set_updated_at();
create trigger webhooks_updated_at before update on public.webhooks
  for each row execute function public.set_updated_at();
create trigger webhook_deliveries_updated_at before update on public.webhook_deliveries
  for each row execute function public.set_updated_at();
