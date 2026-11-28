import type { ButtonHTMLAttributes, ReactNode } from 'react'
import styles from './Button.module.css'

type Props = ButtonHTMLAttributes<HTMLButtonElement> & {
  /** `claro` es el botón blanco que va sobre fondos oscuros. */
  variant?: 'primary' | 'secondary' | 'social' | 'claro'
  loading?: boolean
  fullWidth?: boolean
  icon?: ReactNode
}

export function Button({
  variant = 'primary',
  loading = false,
  fullWidth = false,
  icon,
  disabled,
  type = 'button',
  className,
  children,
  ...rest
}: Props) {
  return (
    <button
      type={type}
      className={[styles.button, styles[variant], fullWidth && styles.fullWidth, className]
        .filter(Boolean)
        .join(' ')}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      data-loading={loading || undefined}
      {...rest}
    >
      {loading ? <span className={styles.spinner} aria-hidden="true" /> : icon}
      {children}
    </button>
  )
}
