import { beforeEach, describe, expect, it } from 'vitest'
import { createMockContracts, createMockStore, type NewBooking } from '.'

const HOUR = 60 * 60 * 1000
let clock = Date.parse('2027-01-10T12:00:00-07:00')
let store = createMockStore(() => new Date(clock))
const as = (role: 'user' | 'provider' | 'admin' | 'server') => createMockContracts(store, role)

const salon: NewBooking = {
  serviceId: 'salon-demo-renta',
  dates: ['2027-03-19'],
  shiftId: 'noche',
  guestCount: 150,
  paymentMethod: 'tarjeta',
}
const buffet: NewBooking = {
  serviceId: 'banquetes-demo-buffet',
  dates: ['2027-03-19'],
  shiftId: 'noche',
  guestCount: 100,
}

beforeEach(() => {
  clock = Date.parse('2027-01-10T12:00:00-07:00')
  store = createMockStore(() => new Date(clock))
})

describe('apartar', () => {
  it('si el proveedor exige anticipo, espera el pago 15 minutos con tarjeta', async () => {
    const { bookings, depositTotal } = await as('user').createBooking(salon)
    expect(bookings[0].status).toBe('esperando_pago')
    expect(depositTotal).toBe(5400)
    expect(Date.parse(bookings[0].depositDueAt!) - clock).toBe(HOUR / 4)
    expect(bookings[0].providerFreeCancelUntil).toBeUndefined()
  })

  it('si no exige anticipo, queda confirmada al instante', async () => {
    const { bookings, total } = await as('user').createBooking(buffet)
    expect(bookings[0].status).toBe('confirmada')
    expect(total).toBe(28000)
  })

  it('varios días crean una reserva por día en el mismo evento', async () => {
    const created = await as('user').createBooking({
      ...salon,
      dates: ['2027-03-19', '2027-03-20'],
    })
    expect(created.bookings).toHaveLength(2)
    expect(new Set(created.bookings.map((b) => b.eventId)).size).toBe(1)
    expect(created.total).toBe(36000)
  })

  it('no permite doble reserva, y si un día falla no aparta ninguno', async () => {
    await as('user').createBooking(salon)
    await expect(
      as('user').createBooking({ ...salon, dates: ['2027-03-18', '2027-03-19'] }),
    ).rejects.toMatchObject({ code: 'date_taken' })
    expect((await as('user').checkAvailability('salon-demo', '2027-03-18')).status).toBe(
      'available',
    )
    expect((await as('user').checkAvailability('salon-demo', '2027-03-19')).status).toBe('partial')
  })
})

describe('pago y cancelación', () => {
  const paid = async () => {
    const { bookings } = await as('user').createBooking(salon)
    const [b] = await as('server').confirmBooking([bookings[0].id], 'pago-1')
    return b
  }

  it('solo el servidor registra el anticipo, y ahí empiezan las 24 h del proveedor', async () => {
    const { bookings } = await as('user').createBooking(salon)
    await expect(as('provider').confirmBooking([bookings[0].id], 'x')).rejects.toMatchObject({
      code: 'forbidden',
    })
    const [b] = await as('server').confirmBooking([bookings[0].id], 'pago-1')
    expect(b.status).toBe('anticipo_pagado')
    expect(Date.parse(b.providerFreeCancelUntil!) - clock).toBe(24 * HOUR)
  })

  it('el proveedor cancela sin multa dentro de 24 h y con multa después', async () => {
    const first = await paid()
    expect(await as('provider').cancelBooking(first.id, 'Ya estaba vendida')).toMatchObject({
      penalty: false,
      refundAmount: 5400,
    })
    const second = await paid()
    clock += 25 * HOUR
    expect(await as('provider').cancelBooking(second.id, 'Cambio de planes')).toMatchObject({
      penalty: true,
      refundAmount: 5400,
    })
  })

  it('el usuario recibe todo dentro de 7 días; después depende de la política', async () => {
    const b = await paid()
    clock += 8 * 24 * HOUR
    expect((await as('user').cancelBooking(b.id)).refundAmount).toBeNull()
  })

  it('reprogramar necesita que el proveedor acepte y conserva el estado', async () => {
    const b = await paid()
    const request = await as('user').rescheduleBooking(b.id, '2027-04-02', 'noche')
    expect(request.status).toBe('solicitado')
    const moved = await as('provider').answerReschedule(request.id, true)
    expect(moved).toMatchObject({ date: '2027-04-02', status: 'anticipo_pagado' })
    expect((await as('user').checkAvailability('salon-demo', '2027-03-19')).status).toBe(
      'available',
    )
  })
})

describe('proveedor', () => {
  it('bloquea fechas libres y reporta las que chocan', async () => {
    await as('user').createBooking(salon)
    const result = await as('provider').blockDates(
      'salon-demo',
      ['2027-03-19', '2027-03-26'],
      'manual',
    )
    expect(result.conflicts).toEqual(['2027-03-19'])
    expect(result.blocked).toHaveLength(1)
    await as('provider').unblockDates(result.blocked[0].blockId)
    expect((await as('user').checkAvailability('salon-demo', '2027-03-26')).status).toBe(
      'available',
    )
  })

  it('los datos públicos no traen contacto', async () => {
    const data = await as('user').getProviderPublic('salon-demo')
    expect(JSON.stringify(data)).not.toMatch(/phone|whatsapp|email|telefono|correo/i)
  })
})
