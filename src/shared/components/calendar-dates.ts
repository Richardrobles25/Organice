/** Fecha local en formato AAAA-MM-DD (sin pasar por UTC, que puede cambiar el día). */
export function toIsoDay(date: Date): string {
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${date.getFullYear()}-${m}-${d}`
}

/** Días del mes acomodados en semanas que empiezan en lunes; `null` son huecos. */
export function monthWeeks(year: number, month: number): (Date | null)[][] {
  const offset = (new Date(year, month, 1).getDay() + 6) % 7
  const total = new Date(year, month + 1, 0).getDate()
  const cells: (Date | null)[] = [
    ...Array<null>(offset).fill(null),
    ...Array.from({ length: total }, (_, i) => new Date(year, month, i + 1)),
  ]
  while (cells.length % 7) cells.push(null)
  return Array.from({ length: cells.length / 7 }, (_, i) => cells.slice(i * 7, i * 7 + 7))
}
