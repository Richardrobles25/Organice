import { Icon, type IconName } from './Icon'
import styles from './BottomNav.module.css'

export type Tab = { label: string; href: string; icon: IconName; active?: boolean }

/** Navegación en celular; en pantallas anchas se oculta porque la cubre AppHeader. */
export function BottomNav({ tabs }: { tabs: Tab[] }) {
  return (
    <nav className={styles.nav} aria-label="Principal en celular">
      {tabs.map((tab) => (
        <a key={tab.href} href={tab.href} aria-current={tab.active ? 'page' : undefined}>
          <Icon name={tab.icon} size={24} />
          {tab.label}
        </a>
      ))}
    </nav>
  )
}
