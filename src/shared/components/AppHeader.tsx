import logo from '../assets/img/logo-tinta.png'
import partyHat from '../assets/icons/gorro.svg'
import { Icon } from './Icon'
import styles from './AppHeader.module.css'

export type NavLink = { label: string; href: string; active?: boolean; badge?: number }

type Props = {
  links: NavLink[]
  notifications?: number
  searchHref?: string
  notificationsHref?: string
  accountHref?: string
}

export function AppHeader({
  links,
  notifications = 0,
  searchHref = '/buscar',
  notificationsHref = '/notificaciones',
  accountHref = '/cuenta',
}: Props) {
  return (
    <header className={styles.header}>
      <a className={styles.logo} href="/">
        <img src={logo} alt="ORGANICE" width={156} height={52} />
      </a>
      <nav className={styles.links} aria-label="Principal">
        {links.map((link) => (
          <a key={link.href} href={link.href} aria-current={link.active ? 'page' : undefined}>
            {link.label}
            {!!link.badge && <span className={styles.count}>{link.badge}</span>}
          </a>
        ))}
      </nav>
      <div className={styles.actions}>
        <a
          className={styles.round}
          href={notificationsHref}
          aria-label={
            notifications ? `Notificaciones: ${notifications} sin leer` : 'Notificaciones'
          }
        >
          <Icon name="bell" />
          {!!notifications && (
            <span className={`${styles.count} ${styles.corner}`} aria-hidden="true">
              {notifications}
            </span>
          )}
        </a>
        <a className={styles.round} href={searchHref} aria-label="Buscar">
          <Icon name="search" />
        </a>
        <a className={styles.account} href={accountHref} aria-label="Mi cuenta">
          <span className={styles.avatar}>
            <Icon name="user" size={18} />
          </span>
          <img className={styles.hat} src={partyHat} alt="" />
        </a>
      </div>
    </header>
  )
}
