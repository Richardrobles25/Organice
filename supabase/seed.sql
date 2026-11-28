-- Cimiento 1.9 · Datos de prueba SOLO para la base local. Se cargan con `npm run db:reset`.
-- NO subir a la nube: nunca usar `supabase db push --include-seed`.
-- Todo es ficticio. Las fechas son relativas a hoy para que siempre haya reservas pasadas y futuras.
--
-- Cuentas para iniciar sesión en local (contraseña de todas: Organice-Local1):
--   usuario01@ejemplo.test … usuario20@ejemplo.test      organizadores
--   proveedor01@ejemplo.test … proveedor30@ejemplo.test  dueños de proveedores
--   admin@ejemplo.test                                    administración

create schema seed;

-- Identificadores fijos: el primer dígito dice qué es (1 usuario, 2 dueño, 3 proveedor,
-- 4 servicio, 5 recurso, 6 evento, 7 reserva).
create function seed.id(kind int, n int) returns uuid language sql immutable as $$
  select (kind || '0000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;

create function seed.account(account_id uuid, mail text, nombre text, apellido text, rol text)
returns void language plpgsql as $$
begin
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change)
  values ('00000000-0000-0000-0000-000000000000', account_id, 'authenticated', 'authenticated', mail,
    extensions.crypt('Organice-Local1', extensions.gen_salt('bf')), now(),
    '{"provider": "email", "providers": ["email"]}', '{}', now(), now(), '', '', '', '');
  insert into auth.identities (provider_id, user_id, identity_data, provider, created_at, updated_at)
  values (account_id::text, account_id,
    jsonb_build_object('sub', account_id::text, 'email', mail, 'email_verified', true),
    'email', now(), now());
  insert into public.profiles (id, full_name, last_name, phone)
  values (account_id, nombre, apellido, '311555' || lpad((abs(hashtext(mail)) % 10000)::text, 4, '0'));
  insert into public.user_roles (profile_id, role) values (account_id, rol);
  insert into public.consents (profile_id, document, version) values
    (account_id, 'terminos', 'prueba'), (account_id, 'privacidad', 'prueba');
end $$;

-- ---------------------------------------------------------------- Cuentas
do $$
declare
  nombres text[] := array['Ana','Luis','María','Jorge','Sofía','Carlos','Valeria','Diego','Fernanda','Miguel',
                          'Daniela','Raúl','Paola','Iván','Renata','Héctor','Ximena','Óscar','Lucía','Andrés'];
  apellidos text[] := array['Ramírez','López','García','Hernández','Torres','Flores','Cruz','Navarro','Ibarra','Salas'];
  n int;
begin
  for n in 1..20 loop
    perform seed.account(seed.id(1, n), 'usuario' || lpad(n::text, 2, '0') || '@ejemplo.test',
      nombres[n], apellidos[(n - 1) % 10 + 1], 'usuario');
  end loop;
  for n in 1..30 loop
    perform seed.account(seed.id(2, n), 'proveedor' || lpad(n::text, 2, '0') || '@ejemplo.test',
      nombres[(n * 3) % 20 + 1], apellidos[(n * 7) % 10 + 1], 'proveedor');
  end loop;
  perform seed.account(seed.id(1, 99), 'admin@ejemplo.test', 'Equipo', 'ORGANICE', 'admin');
end $$;

-- ---------------------------------------------------------------- Proveedores y catálogo
do $$
declare
  -- nombre | categoría
  lista text[] := array[
    'Salón Las Jacarandas|salones','Terraza Cerro Azul|salones','Jardín El Pirul|salones',
    'Quinta Los Naranjos|salones','Salón Cantera|salones','Hacienda Los Arcos|salones',
    'Jardín Los Rosales|salones','Terraza Edison|salones',
    'Banquetes Doña Chuy|catering','Taquizas Don Beto|catering','Banquetes Del Valle|catering',
    'Cocina de Autor Aurora|catering','Sabores del Nayar|catering',
    'DJ Marea|espectaculos','Mariachi Sol de Tepic|espectaculos','Banda La Cumbre|espectaculos',
    'Show Infantil Burbujas|espectaculos',
    'Rentas El Toldo|mobiliario','Sillas y Mesas Nayarit|mobiliario','Mobiliario Elegance|mobiliario',
    'Carpas del Pacífico|mobiliario',
    'Flores y Globos Lila|decoracion','Decora Eventos Brisa|decoracion','Ambientes Candil|decoracion',
    'Fotografía Instante|fotografia','Foto y Video Retrato|fotografia','Cabina Sonrisas|fotografia',
    'Dulce Encanto|pasteleria','Pasteles La Abuela|pasteleria','Mesa Dulce Confeti|pasteleria'];
  colonias text[] := array['Centro','Ciudad del Valle','Los Fresnos','Lindavista','San Juan','Versalles'];
  nombre text; cat text; cat_id uuid; n int; svc int := 0; k int; por_persona boolean;
  base_precio numeric; servicios int; recursos int; r int;
begin
  for n in 1..30 loop
    nombre := split_part(lista[n], '|', 1);
    cat := split_part(lista[n], '|', 2);
    select id into cat_id from public.categories where slug = cat;

    insert into public.providers (id, owner_id, name, slug, description, founded_year, colonia, lat, lng,
      status, verified_at, premium_badge, is_founder, deposit_pct, requires_deposit_to_book,
      payment_account_id)
    values (seed.id(3, n), seed.id(2, n), nombre, 'prueba-' || n,
      nombre || ' es un proveedor de ejemplo para probar la plataforma en Tepic.',
      2005 + n % 18, colonias[(n - 1) % 6 + 1], 21.50 + (n % 7) * 0.004, -104.89 - (n % 5) * 0.004,
      case when n in (29, 30) then 'pendiente' when n = 27 then 'falta_info' else 'aprobado' end,
      case when n not in (27, 29, 30) then now() - interval '60 days' end,
      n % 5 = 1, n <= 5, 20 + (n % 4) * 10, n % 6 <> 0,
      case when n not in (27, 29, 30) then 'prueba_cuenta_' || n end);

    insert into public.provider_contacts (provider_id, phone, whatsapp, email)
    values (seed.id(3, n), '311555' || lpad((1000 + n)::text, 4, '0'),
      '311555' || lpad((1000 + n)::text, 4, '0'), 'contacto' || n || '@ejemplo.test');
    insert into public.provider_categories (provider_id, category_id) values (seed.id(3, n), cat_id);
    insert into public.subscriptions (provider_id, plan, current_period_end)
    values (seed.id(3, n), case when n % 5 = 1 then 'premium' else 'gratuito' end,
      case when n % 5 = 1 then now() + interval '20 days' end);

    insert into public.shifts (provider_id, name, start_time, end_time) values
      (seed.id(3, n), 'Mañana', '09:00', '15:00'),
      (seed.id(3, n), 'Noche', '18:00', '02:00'),
      (seed.id(3, n), 'Día completo', '09:00', '23:59');

    recursos := case when cat = 'salones' then 1 else 2 end;
    for r in 1..recursos loop
      insert into public.resources (id, provider_id, name)
      values (seed.id(5, n * 10 + r), seed.id(3, n),
        case when cat = 'salones' then nombre else 'Equipo ' || r end);
    end loop;

    por_persona := cat in ('catering', 'pasteleria');
    base_precio := case cat when 'salones' then 14000 when 'catering' then 190 when 'espectaculos' then 3500
      when 'mobiliario' then 1800 when 'decoracion' then 2800 when 'fotografia' then 4500 else 45 end;
    servicios := case when cat = 'salones' then 1 else 2 end;
    for k in 1..servicios loop
      svc := svc + 1;
      insert into public.services (id, provider_id, category_id, name, description,
        capacity_min, capacity_max, duration_min, included_items)
      values (seed.id(4, svc), seed.id(3, n), cat_id,
        case when cat = 'salones' then 'Renta del lugar' when k = 1 then 'Paquete básico' else 'Paquete completo' end,
        'Servicio de ejemplo de ' || nombre || '.',
        case when cat = 'salones' then 50 end, case when cat = 'salones' then 120 + (n % 5) * 70 end,
        360, array['Montaje', 'Personal']);
      insert into public.prices (service_id, unit, amount)
      values (seed.id(4, svc), case when por_persona then 'persona' else 'fijo' end,
        base_precio * (1 + (n % 4) * 0.15) * (case when k = 2 then 1.5 else 1 end));
      insert into public.service_addons (service_id, name, price)
      values (seed.id(4, svc), 'Hora extra', 800 + (n % 3) * 200);
      for r in 1..recursos loop
        insert into public.service_resources (service_id, resource_id)
        values (seed.id(4, svc), seed.id(5, n * 10 + r));
      end loop;
    end loop;
  end loop;
end $$;

-- ---------------------------------------------------------------- Eventos, reservas y pagos
-- 50 reservas en 40 eventos (los primeros 10 eventos tienen dos servicios).
do $$
declare
  i int; ev int; estado public.booking_status; dia date; horario tstzrange;
  total_svc int; s record; invitados int; total numeric; anticipo numeric; comision numeric;
  usuario uuid; creado timestamptz; metodo text;
  tipos text[] := array['XV años', 'Boda', 'Cumpleaños', 'Bautizo'];
begin
  select count(*) into total_svc from public.services s2
    join public.providers p on p.id = s2.provider_id where p.status = 'aprobado';

  for i in 1..50 loop
    ev := case when i <= 20 then (i + 1) / 2 else i - 10 end;
    estado := case
      when i <= 14 then 'completada' when i <= 26 then 'anticipo_pagado' when i <= 32 then 'pagada'
      when i <= 38 then 'confirmada' when i <= 41 then 'esperando_pago' when i <= 45 then 'expirada'
      else 'cancelada' end;
    dia := case when i <= 14 then current_date - (ev * 6 + 4) else current_date + (ev * 5 + 8) end;
    horario := tstzrange((dia + time '14:00') at time zone 'America/Mazatlan',
                         (dia + time '22:00') at time zone 'America/Mazatlan');
    usuario := seed.id(1, (ev - 1) % 20 + 1);
    invitados := 60 + (ev % 8) * 20;
    creado := case when estado in ('confirmada', 'esperando_pago') then now() - interval '3 hours'
                   else least(now() - interval '5 days', lower(horario) - interval '45 days') end;

    select sv.id as service_id, sv.provider_id, sr.resource_id, pr.unit, pr.amount,
           p.deposit_pct, sb.plan
      into s
      from (select sv2.*, row_number() over (order by sv2.id) - 1 as pos
              from public.services sv2 join public.providers p2 on p2.id = sv2.provider_id
             where p2.status = 'aprobado') sv
      join public.providers p on p.id = sv.provider_id
      join public.prices pr on pr.service_id = sv.id
      join public.subscriptions sb on sb.provider_id = p.id
      join lateral (select resource_id from public.service_resources x
                     where x.service_id = sv.id order by resource_id limit 1) sr on true
     where sv.pos = (i * 7) % total_svc;

    total := round(case when s.unit = 'persona' then s.amount * invitados else s.amount end, 2);
    anticipo := least(total, greatest(500, round(total * s.deposit_pct / 100.0, 2)));
    comision := case when s.plan = 'premium' then 0.04 else 0.07 end;

    insert into public.events (id, user_id, type, name, date, guest_count, budget, status)
    values (seed.id(6, ev), usuario, tipos[ev % 4 + 1], tipos[ev % 4 + 1] || ' de ejemplo ' || ev, dia,
      invitados, 80000, case when dia < current_date then 'pasado' else 'activo' end)
    on conflict (id) do nothing;

    insert into public.bookings (id, event_id, user_id, provider_id, service_id, resource_id, during,
      guest_count, status, total, deposit_amount, commission_rate, commission_amount,
      confirmed_at, deposit_due_at, provider_free_cancel_until,
      cancelled_at, cancelled_by, cancel_reason, created_at)
    values (seed.id(7, i), seed.id(6, ev), usuario, s.provider_id, s.service_id, s.resource_id, horario,
      invitados, estado, total, anticipo, comision, round(total * comision, 2),
      case when estado <> 'esperando_pago' then creado end,
      case when estado = 'confirmada' then now() + interval '21 hours'
           when estado = 'esperando_pago' then now() + interval '20 hours' end,
      case when estado <> 'esperando_pago' then creado + interval '24 hours' end,
      case when estado = 'cancelada' then creado + case when i = 50 then interval '3 days' else interval '5 hours' end end,
      case when estado = 'cancelada' then case when i >= 49 then 'proveedor' else 'usuario' end end,
      case when i >= 49 then 'La fecha ya estaba ocupada fuera de la app.' end,
      creado);

    -- Horario ocupado. Las canceladas y expiradas liberan la fecha.
    if estado in ('confirmada', 'anticipo_pagado', 'pagada', 'completada') then
      insert into public.resource_slots (resource_id, during, kind, booking_id)
      values (s.resource_id, horario, 'reserva', seed.id(7, i));
    elsif estado = 'esperando_pago' then
      insert into public.resource_slots (resource_id, during, kind, booking_id, expires_at)
      values (s.resource_id, horario, 'apartado_temporal', seed.id(7, i), now() + interval '20 hours');
    end if;

    metodo := (array['tarjeta', 'oxxo', 'spei'])[i % 3 + 1];
    if estado in ('anticipo_pagado', 'pagada', 'completada') or i in (46, 49, 50) then
      insert into public.payments (booking_id, kind, method, amount, platform_fee, provider_amount,
        gateway, gateway_ref, status, paid_at)
      values (seed.id(7, i), 'anticipo', metodo, anticipo, round(anticipo * comision, 2),
        anticipo - round(anticipo * comision, 2), 'stripe', 'prueba_anticipo_' || i,
        case when estado = 'cancelada' then 'reembolsado' else 'pagado' end, creado);
    end if;
    if estado in ('pagada', 'completada') and total > anticipo then
      insert into public.payments (booking_id, kind, method, amount, platform_fee, provider_amount,
        gateway, gateway_ref, status, paid_at)
      values (seed.id(7, i), 'saldo', metodo, total - anticipo, round((total - anticipo) * comision, 2),
        (total - anticipo) - round((total - anticipo) * comision, 2), 'stripe', 'prueba_saldo_' || i,
        'pagado', creado + interval '10 days');
    end if;
    if estado = 'esperando_pago' then
      insert into public.payments (booking_id, kind, method, amount, gateway, gateway_ref, status, due_at)
      values (seed.id(7, i), 'anticipo', 'oxxo', anticipo, 'stripe', 'prueba_pendiente_' || i,
        'pendiente', now() + interval '20 hours');
    end if;
    if i in (46, 49, 50) then
      insert into public.refunds (payment_id, amount, reason, status)
      select id, amount, 'Reembolso de ejemplo por cancelación', 'procesado'
        from public.payments where booking_id = seed.id(7, i);
    end if;
    -- Cancelación del proveedor fuera de las 24 h: multa (monto de ejemplo, regla X02 por definir).
    if i = 50 then
      insert into public.provider_penalties (provider_id, booking_id, amount)
      values (s.provider_id, seed.id(7, i), round(total * 0.10, 2));
    end if;

    -- Reseñas: 10 publicadas por ambos lados y 2 esperando al otro (publicación a ciegas).
    if i <= 12 then
      insert into public.reviews (booking_id, rating, punctuality, quality, service, value, comment, published_at, created_at)
      values (seed.id(7, i), 3 + i % 3, 4, 3 + i % 3, 5, 4,
        'Reseña de ejemplo: cumplieron con lo acordado y el trato fue muy amable.',
        case when i <= 10 then upper(horario) + interval '3 days' end, upper(horario) + interval '3 days');
    end if;
    if i <= 10 then
      insert into public.client_reviews (booking_id, rating, payment_punctuality, respect, agreements, comment, published_at)
      values (seed.id(7, i), 4 + i % 2, 5, 5, 4, 'Cliente de ejemplo, puntual y respetuoso.',
        upper(horario) + interval '3 days');
    end if;
  end loop;
end $$;

update public.providers p set rating_avg = x.promedio
  from (select b.provider_id, round(avg(r.rating), 2) as promedio
          from public.reviews r join public.bookings b on b.id = r.booking_id
         where r.published_at is not null group by b.provider_id) x
 where x.provider_id = p.id;

-- ---------------------------------------------------------------- Favoritos, chat, bloqueos e invitación
insert into public.favorites (user_id, provider_id)
select seed.id(1, u), seed.id(3, ((u * 3 + k) % 26) + 1)
  from generate_series(1, 10) u, generate_series(1, 3) k;

insert into public.conversations (user_id, provider_id, last_message_at)
select seed.id(1, n), seed.id(3, n), now() - make_interval(hours => n) from generate_series(1, 6) n;

insert into public.messages (conversation_id, sender_id, body, created_at)
select c.id, case when m = 1 then c.user_id else p.owner_id end,
  case when m = 1 then 'Hola, ¿tienen disponible el sábado en la noche?'
       else 'Hola, sí. Con gusto le comparto los detalles por aquí.' end,
  c.last_message_at - make_interval(mins => (3 - m) * 5)
  from public.conversations c join public.providers p on p.id = c.provider_id, generate_series(1, 2) m;

-- Fechas vendidas fuera de la app.
insert into public.resource_slots (resource_id, during, kind)
select seed.id(5, n * 10 + 1),
  tstzrange((current_date + 300 + n + time '09:00') at time zone 'America/Mazatlan',
            (current_date + 300 + n + time '23:00') at time zone 'America/Mazatlan'),
  'bloqueo'
  from generate_series(1, 5) n;

with inv as (
  insert into public.invitations (event_id, place, public_token, status, max_companions)
  values (seed.id(6, 8), 'Salón de ejemplo, Tepic', 'prueba-invitacion', 'publicada', 2)
  returning id
)
insert into public.guests (invitation_id, name, token, rsvp, companions)
select inv.id, 'Invitado ' || n, 'prueba-invitado-' || n,
  (array['confirmado', 'pendiente', 'declinado'])[n % 3 + 1], case when n % 3 = 0 then 1 else 0 end
  from inv, generate_series(1, 6) n;

drop schema seed cascade;
