import type { ReactNode } from 'react'
import styles from './Alert.module.css'

const ICON = { info: 'i', success: '✓', warning: '!', error: '!' }

type Props = {
  type?: keyof typeof ICON
  title: string
  children?: ReactNode
}

export function Alert({ type = 'info', title, children }: Props) {
  return (
    <div className={`${styles.alert} ${styles[type]}`} role={type === 'error' ? 'alert' : 'status'}>
      <span className={styles.icon} aria-hidden="true">
        {ICON[type]}
      </span>
      <div>
        <p className={styles.title}>{title}</p>
        {children && <div className={styles.text}>{children}</div>}
      </div>
    </div>
  )
}
