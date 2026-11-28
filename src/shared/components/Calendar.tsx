import { monthWeeks, toIsoDay } from './calendar-dates'
import styles from './Calendar.module.css'

export type DayStatus = 'available' | 'partial' | 'busy' | 'unavailable'

const STATUS_LABEL: Record<DayStatus, string> = {
  available: 'Libre (día y noche)',
  partial: 'Un turno libre',
  busy: 'Ocupado',
  unavailable: 'No disponible',
}

const WEEKDAYS = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo']

type Props = {
  year: number
  /** 0 = enero. */
  month: number
  /** Estado por día (AAAA-MM-DD). Un día sin estado no se puede elegir. */
  days: Record<string, DayStatus>
  /** Rango elegido; para un solo día, `from` y `to` son iguales. */
  selected?: { from: string; to: string }
  onSelect?: (day: string) => void
  onMonthChange?: (year: number, month: number) => void
}

export function Calendar({ year, month, days, selected, onSelect, onMonthChange }: Props) {
  const first = new Date(year, month, 1)
  const monthName = first.toLocaleDateString('es-MX', { month: 'long' })
  const title = `${monthName.charAt(0).toUpperCase()}${monthName.slice(1)} ${year}`

  const go = (delta: number) => {
    const next = new Date(year, month + delta, 1)
    onMonthChange?.(next.getFullYear(), next.getMonth())
  }

  return (
    <div className={styles.calendar}>
      <div className={styles.header}>
        <p className={styles.title} aria-live="polite">
          {title}
        </p>
        {onMonthChange && (
          <div className={styles.arrows}>
            <button type="button" aria-label="Mes anterior" onClick={() => go(-1)}>
              ‹
            </button>
            <button type="button" aria-label="Mes siguiente" onClick={() => go(1)}>
              ›
            </button>
          </div>
        )}
      </div>
      <table className={styles.grid} aria-label={title}>
        <thead>
          <tr>
            {WEEKDAYS.map((d) => (
              <th key={d} scope="col" abbr={d}>
                {d === 'Miércoles' ? 'M' : d[0]}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {monthWeeks(year, month).map((week, i) => (
            <tr key={i}>
              {week.map((date, j) => {
                if (!date) return <td key={j} />
                const iso = toIsoDay(date)
                const status = days[iso]
                const open = status === 'available' || status === 'partial'
                const isEnd = selected && (iso === selected.from || iso === selected.to)
                const inRange = selected && iso >= selected.from && iso <= selected.to
                const label = date.toLocaleDateString('es-MX', {
                  day: 'numeric',
                  month: 'long',
                  year: 'numeric',
                })
                return (
                  <td key={j}>
                    <button
                      type="button"
                      className={styles.day}
                      data-status={status ?? 'none'}
                      data-selected={isEnd ? 'end' : inRange ? 'middle' : undefined}
                      aria-pressed={inRange || false}
                      aria-label={status ? `${label}, ${STATUS_LABEL[status]}` : label}
                      disabled={!open}
                      onClick={() => onSelect?.(iso)}
                    >
                      {date.getDate()}
                      <span className={styles.dot} aria-hidden="true" />
                    </button>
                  </td>
                )
              })}
            </tr>
          ))}
        </tbody>
      </table>
      <ul className={styles.legend}>
        {(Object.keys(STATUS_LABEL) as DayStatus[]).map((s) => (
          <li key={s}>
            <span className={styles.dot} data-status={s} aria-hidden="true" />
            {STATUS_LABEL[s]}
          </li>
        ))}
      </ul>
    </div>
  )
}
