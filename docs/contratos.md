# Contratos compartidos (cimiento 1.5)

Aprobados por Nicolás el 28/11/2026; Ricardo los aprueba al revisar el pull request. Cambiarlos requiere un PR aprobado por los dos.

- **Tipos:** `src/shared/contracts/types.ts` (la interfaz `Contracts`).
- **Versión simulada:** `src/shared/contracts/mock.ts`, en memoria y sin base de datos.
- **Reales:** funciones de Postgres (RPC) con el mismo nombre en `snake_case`. Llegan en el bloque de su dueño; **todavía no existen**.

| Función | Dueño | Quién la llama | Recibe | Devuelve |
|---|---|---|---|---|
| `checkAvailability` | A | Cualquiera | proveedor, fecha, turno opcional | libre, parcial u ocupado, por servicio y turno |
| `createBooking` | A | Usuario | servicio, fechas, turno, invitados, notas, evento opcional, extras, forma de pago | evento, una reserva por día, total y anticipo |
| `confirmBooking` | A | Servidor | reservas, referencia del pago | reservas con anticipo pagado |
| `cancelBooking` | A | Usuario, proveedor o admin | reserva, motivo | quién canceló, reembolso y si hay multa |
| `rescheduleBooking` | A | Usuario | reserva, fecha y turno nuevos | solicitud pendiente |
| `answerReschedule` | A | Proveedor | solicitud, aceptar o rechazar | reserva |
| `refundBooking` | A | Servidor o admin | reserva, monto, motivo | reembolso |
| `blockDates` | B | Proveedor (manual) o servidor (calendarios) | proveedor, fechas, origen, turno | bloqueadas y en conflicto |
| `unblockDates` | B | Proveedor o servidor | bloqueo | — |
| `notify` | B | Servidor | persona, tipo, datos | aviso |
| `getProviderPublic` | B | Cualquiera | proveedor | datos públicos, **sin contacto** |

Además, `providers.payment_account_id`: lo llena Track B y lo usa Track A para cobrar dividido. La app no puede leerlo directo (ver `docs/permisos.md`).

## Reglas que las funciones reales deben cumplir

- Crear reservas de varios días es **todo o nada**: si un día está ocupado, no se aparta ninguno.
- Si el proveedor exige anticipo, la reserva nace `esperando_pago` (15 minutos con tarjeta, 24 h con OXXO o SPEI). Si no, nace `confirmada` con 24 h para pagar.
- Las 24 h del proveedor para cancelar empiezan al confirmarse la reserva (con anticipo exigido, al recibir el pago).
- Reprogramar no cambia el estado de la reserva.
- Los errores usan los códigos de `ContractErrorCode`.
- Quién llama sale de la sesión, nunca de un parámetro.

## Cómo usar la versión simulada

```ts
import { createMockContracts, createMockStore } from '@/shared/contracts'

const store = createMockStore()
const user = createMockContracts(store, 'user')
const server = createMockContracts(store, 'server') // comparten los datos
```

Proveedores de ejemplo: `salon-demo` (exige anticipo) y `banquetes-demo` (permite apartar sin pagar). No coinciden con los de `supabase/seed.sql`.

La versión simulada es más sencilla que la real: no revisa de quién es cada reserva y no hace expirar las reservas sin pago.

## Por resolver en su bloque

- **Pago de varios días (A3):** `payments` tiene una referencia de pasarela única por fila; un solo cobro para varias reservas necesitará agrupar los pagos.
- **Calendario mensual (A1):** `checkAvailability` es por día; conviene agregar una consulta por mes.
- **Reembolso después de 7 días:** `refundAmount` es `null` hasta definir la política de cancelación (regla X01).
