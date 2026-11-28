import { render, screen } from '@testing-library/react'
import { createMemoryRouter, RouterProvider } from 'react-router'
import { describe, expect, it } from 'vitest'
import { routes } from './app/routes'

function abrir(ruta: string) {
  render(<RouterProvider router={createMemoryRouter(routes, { initialEntries: [ruta] })} />)
}

describe('Rutas', () => {
  it('muestra el nombre de ORGANICE en el inicio', () => {
    abrir('/')
    expect(screen.getByRole('heading', { name: 'ORGANICE' })).toBeInTheDocument()
  })

  it('muestra la página no encontrada en una ruta que no existe', () => {
    abrir('/no-existe')
    expect(screen.getByRole('heading', { name: 'No encontramos esta página' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Ir al inicio' })).toHaveAttribute('href', '/')
  })
})
