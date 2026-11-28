import { useRef, type ClipboardEvent, type KeyboardEvent } from 'react'
import styles from './CodeInput.module.css'

type Props = {
  value: string
  onChange: (value: string) => void
  length?: number
  label?: string
  disabled?: boolean
}

/** Código de verificación: una casilla por dígito. */
export function CodeInput({
  value,
  onChange,
  length = 6,
  label = 'Código de verificación',
  disabled,
}: Props) {
  const inputs = useRef<(HTMLInputElement | null)[]>([])
  const focus = (i: number) => inputs.current[Math.max(0, Math.min(i, length - 1))]?.focus()

  const setFrom = (index: number, text: string) => {
    const digits = text.replace(/\D/g, '')
    if (!digits) return
    // No se dejan huecos: si se escribe más adelante, se coloca en la primera casilla libre.
    const start = Math.min(index, value.length)
    const next = (value.slice(0, start) + digits + value.slice(start + digits.length)).slice(
      0,
      length,
    )
    onChange(next)
    focus(start + digits.length)
  }

  const onKeyDown = (index: number) => (e: KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace') {
      e.preventDefault()
      const target = value[index] ? index : index - 1
      if (target < 0) return
      onChange(value.slice(0, target) + value.slice(target + 1))
      focus(target)
    } else if (e.key === 'ArrowLeft') focus(index - 1)
    else if (e.key === 'ArrowRight') focus(index + 1)
  }

  const onPaste = (index: number) => (e: ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault()
    setFrom(index, e.clipboardData.getData('text'))
  }

  return (
    <div className={styles.code} role="group" aria-label={label}>
      {Array.from({ length }, (_, i) => (
        <input
          key={i}
          ref={(el) => {
            inputs.current[i] = el
          }}
          className={styles.digit}
          inputMode="numeric"
          autoComplete={i === 0 ? 'one-time-code' : 'off'}
          aria-label={`Dígito ${i + 1} de ${length}`}
          value={value[i] ?? ''}
          disabled={disabled}
          onChange={(e) => setFrom(i, e.target.value)}
          onKeyDown={onKeyDown(i)}
          onPaste={onPaste(i)}
          onFocus={(e) => e.target.select()}
        />
      ))}
    </div>
  )
}
