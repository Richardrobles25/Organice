// Cimiento 1.5 · Contratos entre Track A y Track B. Ver docs/contratos.md.
// Cambiar este archivo requiere un Pull Request aprobado por los dos socios.

/** AAAA-MM-DD, en hora de Nayarit. */
export type Day = string
/** Fecha y hora ISO 8601. */
export type Timestamp = string

export type Role = 'user' | 'provider' | 'admin' | 'server'

/** Mismos valores que `public.booking_status` en la base. */
export type BookingStatus =
  | 'esperando_pago'
  | 'confirmada'
  | 'anticipo_pagado'
  | 'pagada'
  | 'completada'
  | 'expirada'
  | 'cancelada'

/** Mismos valores que usa el componente Calendar. */
export type DayStatus = 'available' | 'partial' | 'busy' | 'unavailable'

export type PaymentMethod = 'tarjeta' | 'oxxo' | 'spei'
export type BlockSource = 'manual' | 'google' | 'ical'

export type ContractErrorCode =
  | 'date_taken' // la fecha o el turno ya están ocupados
  | 'not_found'
  | 'forbidden' // quien llama no puede hacer esto
  | 'invalid' // datos incompletos o fuera de rango
  | 'not_allowed' // el estado actual no lo permite

export class ContractError extends Error {
  readonly code: ContractErrorCode
  constructor(code: ContractErrorCode, message: string) {
    super(message)
    this.name = 'ContractError'
    this.code = code
  }
}

export type Availability = {
  date: Day
  status: DayStatus
  services: {
    serviceId: string
    shifts: { shiftId: string; name: string; available: boolean }[]
  }[]
}

export type NewBooking = {
  serviceId: string
  /** Se crea una reserva por día; todas se pagan juntas. */
  dates: Day[]
  shiftId: string
  guestCount: number
  notes?: string
  /** Si se omite, se crea un evento nuevo (toda reserva pertenece a un evento). */
  eventId?: string
  addonIds?: string[]
  /** Obligatorio si el proveedor exige anticipo para apartar. */
  paymentMethod?: PaymentMethod
}

export type Booking = {
  id: string
  eventId: string
  providerId: string
  serviceId: string
  date: Day
  shiftId: string
  guestCount: number
  status: BookingStatus
  /** Montos en pesos mexicanos. */
  total: number
  depositAmount: number
  /** Límite para pagar el anticipo; si pasa, la reserva expira. */
  depositDueAt?: Timestamp
  /** Hasta cuándo el proveedor puede cancelar sin penalización. */
  providerFreeCancelUntil?: Timestamp
}

export type CreatedBookings = {
  eventId: string
  bookings: Booking[]
  total: number
  depositTotal: number
}

export type Cancellation = {
  bookingId: string
  cancelledBy: 'usuario' | 'proveedor' | 'admin'
  /** `null`: depende de la política de cancelación, que sigue por definir (regla X01). */
  refundAmount: number | null
  /** El proveedor canceló fuera de sus 24 horas. */
  penalty: boolean
}

export type RescheduleRequest = {
  id: string
  bookingId: string
  date: Day
  shiftId: string
  status: 'solicitado' | 'aprobado' | 'rechazado'
}

export type Refund = { id: string; bookingId: string; amount: number; reason: string }

export type BlockResult = {
  blocked: { blockId: string; date: Day }[]
  /** Fechas que ya estaban ocupadas: no se tocan y hay que avisar al proveedor. */
  conflicts: Day[]
}

export type NotificationType =
  | 'reserva_nueva'
  | 'reserva_cancelada'
  | 'pago_recibido'
  | 'reprogramacion_solicitada'
  | 'reprogramacion_respondida'
  | 'mensaje_nuevo'

/** Datos públicos del proveedor. Nunca incluye teléfono, WhatsApp ni correo (anti-fuga). */
export type ProviderPublic = {
  id: string
  name: string
  description: string
  category: string
  colonia: string
  ratingAvg: number | null
  premium: boolean
  depositPct: number
  requiresDepositToBook: boolean
  shifts: { id: string; name: string }[]
  services: {
    id: string
    name: string
    price: number
    priceUnit: 'fijo' | 'persona' | 'hora' | 'dia'
    capacityMax: number | null
  }[]
}

export interface Contracts {
  // Dueño: Track A
  checkAvailability(providerId: string, date: Day, shiftId?: string): Promise<Availability>
  createBooking(input: NewBooking): Promise<CreatedBookings>
  /** Solo el servidor, cuando la pasarela confirma el anticipo. */
  confirmBooking(bookingIds: string[], paymentRef: string): Promise<Booking[]>
  cancelBooking(bookingId: string, reason?: string): Promise<Cancellation>
  rescheduleBooking(bookingId: string, date: Day, shiftId: string): Promise<RescheduleRequest>
  answerReschedule(requestId: string, accept: boolean): Promise<Booking>
  refundBooking(bookingId: string, amount: number, reason: string): Promise<Refund>

  // Dueño: Track B
  blockDates(
    providerId: string,
    dates: Day[],
    source: BlockSource,
    shiftId?: string,
  ): Promise<BlockResult>
  unblockDates(blockId: string): Promise<void>
  /** Solo el servidor. El canal (correo, push, SMS, WhatsApp) lo decide Track B. */
  notify(
    userId: string,
    type: NotificationType,
    data: Record<string, string | number>,
  ): Promise<{ notificationId: string }>
  getProviderPublic(providerId: string): Promise<ProviderPublic | null>
}
