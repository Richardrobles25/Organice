// Versión simulada de los contratos: vive en memoria, sin base de datos.
// Sirve para que un track avance sin esperar al otro. No es la lógica real.
import {
  ContractError,
  type BlockResult,
  type Booking,
  type Contracts,
  type Day,
  type DayStatus,
  type ProviderPublic,
  type RescheduleRequest,
  type Role,
} from './types'

const HOUR = 60 * 60 * 1000
const SHIFTS = [
  { id: 'manana', name: 'Mañana' },
  { id: 'noche', name: 'Noche' },
]

export const MOCK_PROVIDERS: ProviderPublic[] = [
  {
    id: 'salon-demo',
    name: 'Salón de ejemplo',
    description: 'Salón ficticio para probar.',
    category: 'salones',
    colonia: 'Centro',
    ratingAvg: 4.8,
    premium: true,
    depositPct: 30,
    requiresDepositToBook: true,
    shifts: SHIFTS,
    services: [
      {
        id: 'salon-demo-renta',
        name: 'Renta del lugar',
        price: 18000,
        priceUnit: 'fijo',
        capacityMax: 250,
      },
    ],
  },
  {
    id: 'banquetes-demo',
    name: 'Banquetes de ejemplo',
    description: 'Banquetes ficticios para probar.',
    category: 'catering',
    colonia: 'Los Fresnos',
    ratingAvg: null,
    premium: false,
    depositPct: 20,
    requiresDepositToBook: false,
    shifts: SHIFTS,
    services: [
      {
        id: 'banquetes-demo-buffet',
        name: 'Buffet',
        price: 280,
        priceUnit: 'persona',
        capacityMax: null,
      },
    ],
  },
]

type Slot = { providerId: string; date: Day; shiftId: string; ref: string }

export function createMockStore(now: () => Date = () => new Date()) {
  return {
    now,
    nextId: 0,
    bookings: new Map<string, Booking & { paidAt?: number }>(),
    slots: [] as Slot[],
    requests: new Map<string, RescheduleRequest>(),
    notifications: [] as { userId: string; type: string }[],
  }
}
export type MockStore = ReturnType<typeof createMockStore>

/** `role` simula quién está llamando; en la base real sale de la sesión. */
export function createMockContracts(store: MockStore, role: Role): Contracts {
  const id = (prefix: string) => `${prefix}-${++store.nextId}`
  const iso = (ms: number) => new Date(ms).toISOString()
  const now = () => store.now().getTime()

  const only = (...roles: Role[]) => {
    if (!roles.includes(role))
      throw new ContractError('forbidden', `${role} no puede hacer esta acción`)
  }
  const provider = (providerId: string) => {
    const found = MOCK_PROVIDERS.find((p) => p.id === providerId)
    if (!found) throw new ContractError('not_found', 'Proveedor no encontrado')
    return found
  }
  const booking = (bookingId: string) => {
    const found = store.bookings.get(bookingId)
    if (!found) throw new ContractError('not_found', 'Reserva no encontrada')
    return found
  }
  const taken = (providerId: string, date: Day, shiftId: string) =>
    store.slots.some((s) => s.providerId === providerId && s.date === date && s.shiftId === shiftId)
  const release = (ref: string) => {
    store.slots = store.slots.filter((s) => s.ref !== ref)
  }
  const active = (b: Booking) => !['cancelada', 'expirada', 'completada'].includes(b.status)
  const copy = (b: Booking & { paidAt?: number }): Booking => {
    const out = { ...b }
    delete out.paidAt
    return out
  }

  return {
    async checkAvailability(providerId, date, shiftId) {
      const p = provider(providerId)
      const shifts = p.shifts
        .filter((s) => !shiftId || s.id === shiftId)
        .map((s) => ({ shiftId: s.id, name: s.name, available: !taken(providerId, date, s.id) }))
      const free = shifts.filter((s) => s.available).length
      const status: DayStatus = !shifts.length
        ? 'unavailable'
        : free === shifts.length
          ? 'available'
          : free
            ? 'partial'
            : 'busy'
      return { date, status, services: p.services.map((s) => ({ serviceId: s.id, shifts })) }
    },

    async createBooking(input) {
      only('user')
      const p = MOCK_PROVIDERS.find((x) => x.services.some((s) => s.id === input.serviceId))
      const service = p?.services.find((s) => s.id === input.serviceId)
      if (!p || !service) throw new ContractError('not_found', 'Servicio no encontrado')
      if (!input.dates.length || input.guestCount < 1)
        throw new ContractError('invalid', 'Faltan fechas o invitados')
      if (new Set(input.dates).size !== input.dates.length)
        throw new ContractError('invalid', 'Hay fechas repetidas')
      if (!p.shifts.some((s) => s.id === input.shiftId))
        throw new ContractError('invalid', 'Turno desconocido')
      if (p.requiresDepositToBook && !input.paymentMethod)
        throw new ContractError('invalid', 'Este proveedor exige anticipo: elige cómo pagar')
      // Todas o ninguna.
      if (input.dates.some((d) => taken(p.id, d, input.shiftId)))
        throw new ContractError('date_taken', 'Alguna de las fechas ya está ocupada')

      const eventId = input.eventId ?? id('evento')
      const total =
        service.priceUnit === 'persona' ? service.price * input.guestCount : service.price
      const deposit = Math.min(total, Math.max(500, Math.round((total * p.depositPct) / 100)))
      // Con tarjeta se espera 15 minutos; con OXXO o SPEI, o sin exigir anticipo, 24 horas.
      const wait =
        p.requiresDepositToBook && input.paymentMethod === 'tarjeta' ? HOUR / 4 : 24 * HOUR

      const bookings = input.dates.map((date) => {
        const b: Booking = {
          id: id('reserva'),
          eventId,
          providerId: p.id,
          serviceId: service.id,
          date,
          shiftId: input.shiftId,
          guestCount: input.guestCount,
          status: p.requiresDepositToBook ? 'esperando_pago' : 'confirmada',
          total,
          depositAmount: deposit,
          depositDueAt: iso(now() + wait),
          providerFreeCancelUntil: p.requiresDepositToBook ? undefined : iso(now() + 24 * HOUR),
        }
        store.bookings.set(b.id, b)
        store.slots.push({ providerId: p.id, date, shiftId: input.shiftId, ref: b.id })
        return copy(b)
      })
      return {
        eventId,
        bookings,
        total: total * bookings.length,
        depositTotal: deposit * bookings.length,
      }
    },

    async confirmBooking(bookingIds, paymentRef) {
      only('server')
      if (!paymentRef) throw new ContractError('invalid', 'Falta la referencia del pago')
      const found = bookingIds.map(booking)
      if (found.some((b) => !['esperando_pago', 'confirmada'].includes(b.status)))
        throw new ContractError('not_allowed', 'La reserva no está esperando anticipo')
      return found.map((b) => {
        // La ventana del proveedor empieza cuando llega el pago, salvo que ya estuviera confirmada.
        b.providerFreeCancelUntil ??= iso(now() + 24 * HOUR)
        b.status = 'anticipo_pagado'
        b.paidAt = now()
        b.depositDueAt = undefined
        return copy(b)
      })
    },

    async cancelBooking(bookingId, reason) {
      only('user', 'provider', 'admin')
      const b = booking(bookingId)
      if (!active(b)) throw new ContractError('not_allowed', 'La reserva ya no se puede cancelar')
      if (role === 'provider' && !reason)
        throw new ContractError('invalid', 'El proveedor debe dar un motivo')
      const paid = b.paidAt ? (b.status === 'pagada' ? b.total : b.depositAmount) : 0
      // Usuario: reembolso total dentro de los 7 días siguientes al pago.
      const fullRefund = role !== 'user' || !b.paidAt || now() - b.paidAt <= 7 * 24 * HOUR
      const penalty =
        role === 'provider' &&
        !!b.providerFreeCancelUntil &&
        now() > Date.parse(b.providerFreeCancelUntil)
      b.status = 'cancelada'
      release(b.id)
      return {
        bookingId,
        cancelledBy: role === 'user' ? 'usuario' : role === 'provider' ? 'proveedor' : 'admin',
        refundAmount: fullRefund ? paid : null,
        penalty,
      }
    },

    async rescheduleBooking(bookingId, date, shiftId) {
      only('user')
      const b = booking(bookingId)
      if (!active(b)) throw new ContractError('not_allowed', 'La reserva ya no se puede cambiar')
      if (taken(b.providerId, date, shiftId))
        throw new ContractError('date_taken', 'La nueva fecha está ocupada')
      const request: RescheduleRequest = {
        id: id('cambio'),
        bookingId,
        date,
        shiftId,
        status: 'solicitado',
      }
      store.requests.set(request.id, request)
      return { ...request }
    },

    async answerReschedule(requestId, accept) {
      only('provider')
      const request = store.requests.get(requestId)
      if (!request) throw new ContractError('not_found', 'Solicitud no encontrada')
      if (request.status !== 'solicitado')
        throw new ContractError('not_allowed', 'La solicitud ya se contestó')
      const b = booking(request.bookingId)
      if (accept) {
        if (!active(b)) throw new ContractError('not_allowed', 'La reserva ya no está vigente')
        if (taken(b.providerId, request.date, request.shiftId))
          throw new ContractError('date_taken', 'La nueva fecha ya se ocupó')
        release(b.id)
        b.date = request.date
        b.shiftId = request.shiftId
        store.slots.push({
          providerId: b.providerId,
          date: b.date,
          shiftId: b.shiftId,
          ref: b.id,
        })
      }
      // La reserva conserva su estado (no existe "reprogramada").
      request.status = accept ? 'aprobado' : 'rechazado'
      return copy(b)
    },

    async refundBooking(bookingId, amount, reason) {
      only('server', 'admin')
      const b = booking(bookingId)
      if (amount <= 0 || amount > b.total || !reason)
        throw new ContractError('invalid', 'Monto o motivo no válido')
      return { id: id('reembolso'), bookingId, amount, reason }
    },

    async blockDates(providerId, dates, source, shiftId) {
      only('provider', 'server')
      const p = provider(providerId)
      // Los calendarios externos solo los sincroniza el servidor.
      if (source !== 'manual') only('server')
      const result: BlockResult = { blocked: [], conflicts: [] }
      const shifts = p.shifts.filter((s) => !shiftId || s.id === shiftId)
      if (!shifts.length) throw new ContractError('invalid', 'Turno desconocido')
      for (const date of dates) {
        if (shifts.some((s) => taken(providerId, date, s.id))) {
          result.conflicts.push(date)
          continue
        }
        const blockId = id('bloqueo')
        for (const s of shifts) store.slots.push({ providerId, date, shiftId: s.id, ref: blockId })
        result.blocked.push({ blockId, date })
      }
      return result
    },

    async unblockDates(blockId) {
      only('provider', 'server')
      if (store.bookings.has(blockId))
        throw new ContractError('not_allowed', 'Una reserva se cancela, no se desbloquea')
      if (!store.slots.some((s) => s.ref === blockId))
        throw new ContractError('not_found', 'Bloqueo no encontrado')
      release(blockId)
    },

    async notify(userId, type) {
      only('server')
      store.notifications.push({ userId, type })
      return { notificationId: id('aviso') }
    },

    async getProviderPublic(providerId) {
      return structuredClone(MOCK_PROVIDERS.find((p) => p.id === providerId) ?? null)
    },
  }
}
