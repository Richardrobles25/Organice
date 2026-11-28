import { Icon } from './Icon'
import styles from './ProviderCard.module.css'

type Props = {
  name: string
  /** Ej. "Hasta 250 invitados · Centro". */
  detail: string
  href: string
  /** Precio ya formateado, ej. "$18,000". */
  price: string
  unit?: string
  rating?: number
  photo?: string
  premium?: boolean
  favorite?: boolean
  onToggleFavorite?: () => void
}

export function ProviderCard({
  name,
  detail,
  href,
  price,
  unit = 'evento',
  rating,
  photo,
  premium,
  favorite = false,
  onToggleFavorite,
}: Props) {
  return (
    <article className={styles.card}>
      <div className={styles.photo}>
        {photo && <img src={photo} alt="" loading="lazy" />}
        {premium && (
          <span className={styles.badge}>
            <Icon name="shield" size={14} />
            Verificado Premium
          </span>
        )}
        {onToggleFavorite && (
          <button
            type="button"
            className={styles.favorite}
            aria-pressed={favorite}
            aria-label={`Guardar ${name} en favoritos`}
            onClick={onToggleFavorite}
          >
            <svg width="24" height="24" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
            </svg>
          </button>
        )}
      </div>
      <h3 className={styles.name}>
        {/* El enlace cubre toda la tarjeta; el corazón queda por encima. */}
        <a href={href}>{name}</a>
      </h3>
      <p className={styles.detail}>{detail}</p>
      <div className={styles.footer}>
        <p>
          Desde <strong>{price}</strong> <span className={styles.unit}>/ {unit}</span>
        </p>
        {rating !== undefined && (
          <p className={styles.rating}>
            <Icon name="star" size={13} />
            <span className="solo-lectores">Calificación</span>
            {rating.toFixed(1)}
          </p>
        )}
      </div>
    </article>
  )
}
