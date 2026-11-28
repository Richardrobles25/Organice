import { useState } from 'react'
import {
  Alert,
  AppHeader,
  BottomNav,
  Button,
  Calendar,
  Checkbox,
  CodeInput,
  PasswordField,
  ProviderCard,
  TextField,
  toIsoDay,
  type DayStatus,
} from '../components'
import google from '../assets/icons/google.svg'
import styles from './Showcase.module.css'

const COLORS = [
  'tinta',
  'secundario',
  'atenuado',
  'blanco',
  'fondo-claro',
  'borde',
  'beige',
  'banner',
  'disponible',
  'ocupado',
  'parcial',
  'no-disponible',
]

/** Estados de ejemplo: viernes con un turno libre y sábados 6 y 20 ocupados. */
function sampleDays(year: number, month: number): Record<string, DayStatus> {
  const days: Record<string, DayStatus> = {}
  const total = new Date(year, month + 1, 0).getDate()
  for (let d = 1; d <= total; d++) {
    const date = new Date(year, month, d)
    days[toIsoDay(date)] =
      d === 6 || d === 20
        ? 'busy'
        : d === 25
          ? 'unavailable'
          : date.getDay() === 5
            ? 'partial'
            : 'available'
  }
  return days
}

/** Página de muestra del cimiento 1.7 (ruta /sistema). Los datos son ficticios. */
export default function Showcase() {
  const [code, setCode] = useState('482')
  const [favorite, setFavorite] = useState(false)
  const [view, setView] = useState({ year: 2027, month: 2 })
  const [day, setDay] = useState('2027-03-19')

  return (
    <>
      <AppHeader
        notifications={3}
        links={[
          { label: 'Explorar', href: '#explorar', active: true },
          { label: 'Armar mi fiesta', href: '#armar' },
          { label: 'Mis reservas', href: '#reservas' },
          { label: 'Mensajes', href: '#mensajes', badge: 2 },
        ]}
      />
      <main className={styles.page}>
        <div>
          <h1 className="titulo-grande">Sistema de diseño</h1>
          <p className={styles.lead}>Componentes base de ORGANICE. Datos de ejemplo.</p>
        </div>

        <section>
          <h2 className="titulo-seccion">Colores</h2>
          <ul className={styles.colors}>
            {COLORS.map((c) => (
              <li key={c}>
                <span style={{ background: `var(--color-${c})` }} />
                {c}
              </li>
            ))}
          </ul>
        </section>

        <section>
          <h2 className="titulo-seccion">Botones</h2>
          <div className={styles.row}>
            <Button>Crear cuenta</Button>
            <Button variant="secondary">Cancelar</Button>
            <Button disabled>Crear cuenta</Button>
            <Button loading>Creando cuenta…</Button>
            <Button variant="social" icon={<img src={google} alt="" width={20} height={20} />}>
              Continuar con Google
            </Button>
          </div>
          <div className={styles.dark}>
            <Button variant="claro">Registrar mi negocio</Button>
          </div>
        </section>

        <section>
          <h2 className="titulo-seccion">Campos</h2>
          <div className={styles.fields}>
            <TextField label="Correo electrónico" type="email" placeholder="Escribe tu correo" />
            <TextField
              label="Correo con error"
              defaultValue="correo@"
              error="Escribe un correo válido."
            />
            <TextField
              label="Correo correcto"
              defaultValue="ana@ejemplo.com"
              success="Correo disponible."
            />
            <TextField label="Deshabilitado" defaultValue="ana@ejemplo.com" disabled />
            <PasswordField label="Contraseña" placeholder="Tu contraseña" />
            <PasswordField label="Contraseña corta" error="Usa al menos 8 caracteres." />
          </div>
          <div className={styles.row}>
            <Checkbox>Acepto los Términos y condiciones</Checkbox>
            <Checkbox defaultChecked>Recordarme</Checkbox>
            <Checkbox invalid>Debes aceptar los términos</Checkbox>
          </div>
          <CodeInput value={code} onChange={setCode} />
        </section>

        <section>
          <h2 className="titulo-seccion">Avisos</h2>
          <div className={styles.fields}>
            <Alert title="Revisa tu correo">Te enviamos un enlace de confirmación.</Alert>
            <Alert type="success" title="Cambios guardados" />
            <Alert type="warning" title="Sesión por vencer">
              Se cerrará en 2 minutos.
            </Alert>
            <Alert type="error" title="No pudimos iniciar sesión">
              Revisa tu correo y contraseña.
            </Alert>
          </div>
        </section>

        <section>
          <h2 className="titulo-seccion">Tarjeta de proveedor</h2>
          <div className={styles.cards}>
            <ProviderCard
              name="Salón de ejemplo"
              detail="Hasta 250 invitados · Centro"
              href="#salon"
              price="$18,000"
              rating={4.9}
              premium
              favorite={favorite}
              onToggleFavorite={() => setFavorite((f) => !f)}
            />
            <ProviderCard
              name="Banquetes de ejemplo con un nombre muy largo"
              detail="Buffet · desde 50 personas"
              href="#banquetes"
              price="$280"
              unit="persona"
              rating={4.8}
            />
          </div>
        </section>

        <section>
          <h2 className="titulo-seccion">Calendario</h2>
          <Calendar
            year={view.year}
            month={view.month}
            days={sampleDays(view.year, view.month)}
            selected={{ from: day, to: day }}
            onSelect={setDay}
            onMonthChange={(year, month) => setView({ year, month })}
          />
        </section>
      </main>
      <BottomNav
        tabs={[
          { label: 'Explorar', href: '#explorar', icon: 'explore', active: true },
          { label: 'Favoritos', href: '#favoritos', icon: 'heart' },
          { label: 'Reservas', href: '#reservas', icon: 'calendar' },
          { label: 'Perfil', href: '#perfil', icon: 'profile' },
        ]}
      />
    </>
  )
}
