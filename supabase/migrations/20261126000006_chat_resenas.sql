-- Chat, reseñas y favoritos.

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles,
  provider_id uuid not null references public.providers,
  event_id uuid references public.events,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, provider_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations on delete cascade,
  sender_id uuid not null references public.profiles,
  body text,
  attachment_path text,
  read_at timestamptz,
  contact_filtered boolean not null default false,
  created_at timestamptz not null default now(),
  check (body is not null or attachment_path is not null)
);

-- published_at vacío hasta que ambas partes califiquen o pasen 14 días.
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings,
  rating int not null check (rating between 1 and 5),
  punctuality int check (punctuality between 1 and 5),
  quality int check (quality between 1 and 5),
  service int check (service between 1 and 5),
  value int check (value between 1 and 5),
  comment text not null check (char_length(comment) between 20 and 500),
  photos text[] not null default '{}' check (cardinality(photos) <= 5),
  published_at timestamptz,
  reply text,
  replied_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Nunca pública.
create table public.client_reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings,
  rating int not null check (rating between 1 and 5),
  payment_punctuality int check (payment_punctuality between 1 and 5),
  respect int check (respect between 1 and 5),
  agreements int check (agreements between 1 and 5),
  comment text check (char_length(comment) <= 300),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.review_reports (
  id uuid primary key default gen_random_uuid(),
  review_id uuid references public.reviews on delete cascade,
  client_review_id uuid references public.client_reviews on delete cascade,
  reporter_id uuid not null references public.profiles,
  reason text not null check (reason in ('ofensivo', 'falso', 'spam', 'competencia_desleal')),
  status text not null default 'abierto' check (status in ('abierto', 'resuelto')),
  action text check (action in ('mantener', 'editar', 'eliminar')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (num_nonnulls(review_id, client_review_id) = 1)
);

create table public.favorites (
  user_id uuid not null references public.profiles on delete cascade,
  provider_id uuid not null references public.providers on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, provider_id)
);

create table public.favorite_shares (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles on delete cascade,
  token text not null unique,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.activity_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles on delete set null,
  type text not null,
  provider_id uuid references public.providers on delete cascade,
  query text,
  source text,
  created_at timestamptz not null default now()
);

-- Seguridad por fila activada; sin políticas nadie lee ni escribe (se definen en el cimiento 1.4).
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;
alter table public.client_reviews enable row level security;
alter table public.review_reports enable row level security;
alter table public.favorites enable row level security;
alter table public.favorite_shares enable row level security;
alter table public.activity_events enable row level security;

create trigger conversations_updated_at before update on public.conversations
  for each row execute function public.set_updated_at();
create trigger reviews_updated_at before update on public.reviews
  for each row execute function public.set_updated_at();
create trigger client_reviews_updated_at before update on public.client_reviews
  for each row execute function public.set_updated_at();
create trigger review_reports_updated_at before update on public.review_reports
  for each row execute function public.set_updated_at();
