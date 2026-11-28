# Permisos (cimiento 1.4)

Decididos por Nicolás el 28/11/2026; Ricardo los aprueba al revisar el pull request. Están en `supabase/migrations/20261128000001_permisos.sql` y se prueban en `supabase/tests/database/03_permisos.test.sql`.

**Todo está cerrado por defecto**, también las tablas nuevas: cada migración que cree una tabla debe dar sus permisos y políticas.

| Información | Visitante | Usuario | Proveedor | Admin |
|---|---|---|---|---|
| Proveedores aprobados, servicios, precios, fotos aprobadas | Ver | Ver | Ver; edita lo suyo | Ver |
| Proveedores sin aprobar | — | — | Solo el suyo | Ver |
| Teléfono y WhatsApp del proveedor | — | Con anticipo pagado | El suyo | Ver |
| Teléfono y correo del cliente | — | — | Con anticipo pagado | Ver |
| Ocupado o libre (sin decir quién) | Ver | Ver | Ver | Ver |
| RFC, CLABE y documentos | — | — | Los suyos | Ver |
| Perfil | — | El suyo | El suyo | Ver |
| Eventos, favoritos, invitados | — | Los suyos | Los suyos como usuario | Ver (favoritos no) |
| Reservas y pagos | — | Los suyos | Los de su negocio | Ver |
| Chat | — | Los suyos | Los suyos | Solo con disputa, queda en bitácora |
| Reseñas publicadas | Ver | Ver; escribe las suyas | Ver; responde | Ver |
| Calificación de clientes | — | Solo su promedio | De quien le pagó anticipo, y las que él escribió | Ver |
| Tasa de cancelación, comisiones, multas | — | — | Las suyas | Ver |
| Categorías, banners, plantillas | Ver | Ver | Ver | Editar |
| Cupones, configuración, bitácora | — | — | — | Todo (la bitácora no se borra) |

## Importante al programar

- **No usar `select('*')`** en `providers`, `bookings`, `payments`, `resource_slots`, `provider_billing`, `billing_profiles`, `calendar_connections`, `api_keys` ni `webhooks`: hay columnas ocultas y la consulta fallaría. Pedir las columnas por nombre.
- **No hay escritura directa** en reservas, pagos, reembolsos ni horarios. Llegan como funciones (contratos 1.5 y sus bloques).
- **Cambios delicados del admin** (aprobar proveedores, moderar, reembolsar, suspender reseñas) también serán funciones que anoten en la bitácora, en los bloques B6 y B7.
- Al registrarse una persona, el trigger `on_auth_user_created` (1.6) crea su perfil, su rol (`usuario` o `proveedor`, nunca `admin`) y sus consentimientos con los datos que manda `signUp`. Ver `supabase/migrations/20261128000002_registro.sql`.

## Funciones disponibles

| Función | Quién | Para qué |
|---|---|---|
| `booking_client(reserva)` | Proveedor de la reserva, admin | Nombre; teléfono y correo si ya pagó el anticipo |
| `provider_booking_commissions(proveedor)` | Dueño, admin | Comisión de cada reserva |
| `my_provider_internal(proveedor)` | Dueño, admin | Tasa de cancelación, de cierre y cuenta de pago |
| `provider_reviews(proveedor)` | Todos | Reseñas publicadas |
| `my_client_rating()` | Usuario | Su promedio como cliente |
| `get_invitation(token)`, `rsvp_invitation(token, respuesta, acompañantes, notas)` | Invitado sin cuenta | Ver y confirmar |
| `admin_read_conversation(conversación)` | Admin, solo con disputa | Leer el chat; queda en la bitácora |

## Pendiente

- Verificación en dos pasos obligatoria para el admin (RF-008, bloque B8).
- Reportes de chat: no existe tabla; por ahora solo las disputas abren un chat al admin.
- Permisos de archivos (Storage), cuando se suban fotos y documentos.
- Que una cuenta suspendida pierda acceso (RF-084, bloque B6).
