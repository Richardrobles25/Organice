import { useId, useState, type InputHTMLAttributes, type ReactNode } from 'react'
import styles from './Field.module.css'

type Props = InputHTMLAttributes<HTMLInputElement> & {
  label: string
  error?: string
  /** Mensaje cuando el valor ya se validó correctamente. */
  success?: string
  /** Contenido a la derecha dentro del campo. */
  trailing?: ReactNode
}

export function TextField({ label, error, success, trailing, id, disabled, ...rest }: Props) {
  const autoId = useId()
  const inputId = id ?? autoId
  const messageId = `${inputId}-mensaje`
  const state = error ? 'error' : success ? 'success' : undefined

  return (
    <div className={styles.field} data-state={state} data-disabled={disabled || undefined}>
      <label className={styles.label} htmlFor={inputId}>
        {label}
      </label>
      <div className={styles.box}>
        <input
          id={inputId}
          className={styles.input}
          disabled={disabled}
          aria-invalid={error ? true : undefined}
          aria-describedby={error || success ? messageId : undefined}
          {...rest}
        />
        {success && !error && (
          <span className={styles.ok} aria-hidden="true">
            ✓
          </span>
        )}
        {trailing}
      </div>
      {(error || success) && (
        <p id={messageId} className={styles.message} role={error ? 'alert' : undefined}>
          {error && (
            <span className={styles.bang} aria-hidden="true">
              !
            </span>
          )}
          {error || success}
        </p>
      )}
    </div>
  )
}

export function PasswordField(props: Omit<Props, 'type' | 'trailing'>) {
  const [visible, setVisible] = useState(false)
  return (
    <TextField
      {...props}
      type={visible ? 'text' : 'password'}
      trailing={
        <button
          type="button"
          className={styles.toggle}
          aria-pressed={visible}
          onClick={() => setVisible((v) => !v)}
          disabled={props.disabled}
        >
          {visible ? 'Ocultar' : 'Mostrar'}
        </button>
      }
    />
  )
}
