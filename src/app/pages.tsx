import { lazy, Suspense } from 'react'
import { Link } from 'react-router'

// Páginas generales que todavía no pertenecen a ningún bloque.

const Showcase = lazy(() => import('@/shared/showcase/Showcase'))

export function Inicio() {
  return (
    <main className="inicio">
      <img src="/pwa-512x512.png" alt="" width={192} height={192} />
      <h1 className="titulo-grande">ORGANICE</h1>
      <p>Organiza tu fiesta completa en un solo lugar.</p>
    </main>
  )
}

/** Sistema de diseño (cimiento 1.7). */
export function Sistema() {
  return (
    <Suspense fallback={null}>
      <Showcase />
    </Suspense>
  )
}

export function NoEncontrada() {
  return (
    <main className="inicio">
      <h1 className="titulo-seccion">No encontramos esta página</h1>
      <p>Puede que el enlace esté mal escrito o que la página ya no exista.</p>
      <Link to="/">Ir al inicio</Link>
    </main>
  )
}
