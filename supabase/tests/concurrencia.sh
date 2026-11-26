#!/usr/bin/env bash
# Dos conexiones intentan ocupar el mismo horario al mismo tiempo: solo una debe lograrlo (RF-068).
# Requiere la base local encendida. Deja la base como estaba.
set -euo pipefail

DB=$(docker ps --format '{{.Names}}' | grep -i '^supabase_db_' | head -1)
[ -n "$DB" ] || { echo "La base local no está encendida (npm run db:start)"; exit 1; }
sql() { docker exec -i "$DB" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -qtA "$@"; }

P=11111111-1111-1111-1111-111111111111
limpiar() {
  sql -c "delete from public.resource_slots where resource_id='$P';
          delete from public.resources where id='$P';
          delete from public.providers where id='$P';
          delete from public.profiles where id='$P';" >/dev/null
}
trap limpiar EXIT
limpiar
sql -c "insert into public.profiles (id) values ('$P');
        insert into public.providers (id, owner_id, name, slug) values ('$P', '$P', 'Concurrencia', 'concurrencia');
        insert into public.resources (id, provider_id, name) values ('$P', '$P', 'Salón');"

APARTAR="insert into public.resource_slots (resource_id, during, kind)
         values ('$P', '[2027-06-19 14:00-07, 2027-06-19 20:00-07)', 'bloqueo');"

# Cada transacción se queda abierta 2 segundos después de insertar, así que se enciman.
fallos=0
sql -c "begin; $APARTAR select pg_sleep(2); commit;" >/dev/null 2>&1 & uno=$!
sql -c "begin; $APARTAR select pg_sleep(2); commit;" >/dev/null 2>&1 & dos=$!
wait $uno || fallos=$((fallos + 1))
wait $dos || fallos=$((fallos + 1))

filas=$(sql -c "select count(*) from public.resource_slots where resource_id='$P';")
if [ "$fallos" = 1 ] && [ "$filas" = 1 ]; then
  echo "OK: de dos reservas simultáneas solo entró una"
else
  echo "FALLO: transacciones rechazadas=$fallos, filas=$filas"
  exit 1
fi
