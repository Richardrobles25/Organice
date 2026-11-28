import { act, render, screen } from '@testing-library/react'
import type { Session, SupabaseClient } from '@supabase/supabase-js'
import { describe, expect, it, vi } from 'vitest'
import { AuthProvider, useAuth } from './AuthProvider'

// Cliente falso: solo lo que usa AuthProvider.
function clienteFalso(inicial: Session | null) {
  let avisar: (evento: string, sesion: Session | null) => void = () => {}
  const unsubscribe = vi.fn()
  const client = {
    auth: {
      getSession: vi.fn().mockResolvedValue({ data: { session: inicial } }),
      onAuthStateChange: vi.fn((cb: typeof avisar) => {
        avisar = cb
        return { data: { subscription: { unsubscribe } } }
      }),
    },
  } as unknown as SupabaseClient
  return { client, unsubscribe, avisar: (s: Session | null) => avisar('SIGNED_IN', s) }
}

function Estado() {
  const { loading, session } = useAuth()
  return <p>{loading ? 'cargando' : session ? `dentro: ${session.user.email}` : 'fuera'}</p>
}

const sesion = { user: { email: 'ana@ejemplo.test' } } as Session

describe('AuthProvider', () => {
  it('empieza cargando y luego dice que no hay sesión', async () => {
    const { client } = clienteFalso(null)
    render(
      <AuthProvider client={client}>
        <Estado />
      </AuthProvider>,
    )
    expect(screen.getByText('cargando')).toBeInTheDocument()
    expect(await screen.findByText('fuera')).toBeInTheDocument()
  })

  it('reacciona cuando la persona inicia sesión', async () => {
    const falso = clienteFalso(null)
    render(
      <AuthProvider client={falso.client}>
        <Estado />
      </AuthProvider>,
    )
    await screen.findByText('fuera')
    act(() => falso.avisar(sesion))
    expect(screen.getByText('dentro: ana@ejemplo.test')).toBeInTheDocument()
  })

  it('deja de escuchar al desmontarse', async () => {
    const falso = clienteFalso(sesion)
    const { unmount } = render(
      <AuthProvider client={falso.client}>
        <Estado />
      </AuthProvider>,
    )
    await screen.findByText('dentro: ana@ejemplo.test')
    unmount()
    expect(falso.unsubscribe).toHaveBeenCalled()
  })
})
