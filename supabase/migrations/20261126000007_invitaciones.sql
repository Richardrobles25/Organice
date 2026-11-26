-- Invitaciones digitales. El invitado no tiene cuenta: entra con un token.

create table public.invitation_templates (
  id uuid primary key default gen_random_uuid(),
  creator_provider_id uuid references public.providers,
  event_type text not null,
  style text,
  design jsonb not null default '{}',
  price numeric(12, 2) not null default 0 check (price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.events on delete cascade,
  template_id uuid references public.invitation_templates,
  design jsonb not null default '{}',
  place text,
  lat double precision,
  lng double precision,
  public_token text not null unique,
  status text not null default 'borrador' check (status in ('borrador', 'publicada')),
  max_companions int not null default 0 check (max_companions >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.guests (
  id uuid primary key default gen_random_uuid(),
  invitation_id uuid not null references public.invitations on delete cascade,
  name text not null,
  phone text,
  email text,
  token text not null unique,
  rsvp text not null default 'pendiente' check (rsvp in ('pendiente', 'confirmado', 'declinado')),
  companions int not null default 0 check (companions >= 0),
  diet_notes text,
  private_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.invitation_sends (
  id uuid primary key default gen_random_uuid(),
  guest_id uuid not null references public.guests on delete cascade,
  channel text not null check (channel in ('whatsapp', 'email', 'enlace', 'qr')),
  status text not null default 'pendiente',
  sent_at timestamptz,
  created_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.invitation_templates enable row level security;
alter table public.invitations enable row level security;
alter table public.guests enable row level security;
alter table public.invitation_sends enable row level security;

create trigger invitation_templates_updated_at before update on public.invitation_templates
  for each row execute function public.set_updated_at();
create trigger invitations_updated_at before update on public.invitations
  for each row execute function public.set_updated_at();
create trigger guests_updated_at before update on public.guests
  for each row execute function public.set_updated_at();
