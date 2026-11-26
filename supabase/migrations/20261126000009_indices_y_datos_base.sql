-- Índices para las llaves foráneas y datos de referencia.

do $$
declare r record;
begin
  for r in
    select c.conrelid::regclass as tabla, cl.relname,
           string_agg(quote_ident(a.attname), ', ' order by k.n) as columnas,
           string_agg(a.attname, '_' order by k.n) as sufijo
    from pg_constraint c
    join pg_class cl on cl.oid = c.conrelid
    cross join lateral unnest(c.conkey) with ordinality as k(attnum, n)
    join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum
    where c.contype = 'f' and c.connamespace = 'public'::regnamespace
      -- sin un índice que ya empiece por esa columna
      and not exists (
        select 1 from pg_index i where i.indrelid = c.conrelid and i.indkey[0] = c.conkey[1]
      )
    group by c.oid, c.conrelid, cl.relname
  loop
    execute format('create index if not exists %I on %s (%s)',
                   r.relname || '_' || r.sufijo || '_idx', r.tabla, r.columnas);
  end loop;
end $$;

insert into public.categories (name, slug) values
  ('Salones', 'salones'),
  ('Catering', 'catering'),
  ('Espectáculos', 'espectaculos'),
  ('Mobiliario', 'mobiliario'),
  ('Decoración', 'decoracion'),
  ('Fotografía', 'fotografia'),
  ('Pastelería', 'pasteleria');

-- Valores de la especificación (RF-095). El precio Premium sigue por confirmar (regla C02).
insert into public.app_settings (key, value) values
  ('comision_gratuito', '0.07'),
  ('comision_premium', '0.04'),
  ('tarifa_servicio', '{"activa": false, "porcentaje": 0.03}'),
  ('precio_premium_mxn', '399');
