import type { InputHTMLAttributes, ReactNode } from 'react'
import styles from './Checkbox.module.css'

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'type'> & {
  children: ReactNode
  invalid?: boolean
}

export function Checkbox({ children, invalid, ...rest }: Props) {
  return (
    <label className={styles.checkbox}>
      <input
        type="checkbox"
        className={styles.input}
        aria-invalid={invalid || undefined}
        {...rest}
      />
      <span>{children}</span>
    </label>
  )
}
