import bell from '../assets/icons/campana.svg?no-inline'
import search from '../assets/icons/lupa.svg?no-inline'
import calendar from '../assets/icons/nav-reservas.svg?no-inline'
import compass from '../assets/icons/nav-explorar.svg?no-inline'
import heart from '../assets/icons/nav-favoritos.svg?no-inline'
import profile from '../assets/icons/nav-perfil.svg?no-inline'
import user from '../assets/icons/usuario.svg?no-inline'
import shield from '../assets/icons/insignia.svg?no-inline'
import star from '../assets/icons/estrella.svg?no-inline'
import styles from './Icon.module.css'

const ICONS = { bell, search, calendar, explore: compass, heart, profile, user, shield, star }

export type IconName = keyof typeof ICONS

/** Icono lineal del Figma; toma el color del texto que lo rodea. */
export function Icon({ name, size = 20 }: { name: IconName; size?: number }) {
  return (
    <span
      aria-hidden="true"
      className={styles.icon}
      style={{ width: size, height: size, maskImage: `url("${ICONS[name]}")` }}
    />
  )
}
