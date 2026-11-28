import { lazy, Suspense } from 'react'

const Showcase = lazy(() => import('./shared/showcase/Showcase'))

function App() {
  // Todavía no hay enrutador: /sistema muestra los componentes del cimiento 1.7.
  if (window.location.pathname === '/sistema') {
    return (
      <Suspense fallback={null}>
        <Showcase />
      </Suspense>
    )
  }

  return (
    <main className="inicio">
      <img src="/pwa-512x512.png" alt="" width={192} height={192} />
      <h1 className="titulo-grande">ORGANICE</h1>
      <p>Organiza tu fiesta completa en un solo lugar.</p>
    </main>
  )
}

export default App
