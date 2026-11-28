import { createContext, useContext, useEffect, useState, type ReactNode } from 'react'
import type { Session, SupabaseClient } from '@supabase/supabase-js'

// Sesión de la persona en toda la app (cimiento 1.6). Supabase Auth guarda la sesión y la renueva;
// aquí solo se escucha para que las pantallas sepan si hay alguien dentro.

type AuthState = {
  /** `true` mientras se lee la sesión guardada al abrir la app. */
  loading: boolean
  session: Session | null
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({
  client,
  children,
}: {
  client: SupabaseClient
  children: ReactNode
}) {
  const [state, setState] = useState<AuthState>({ loading: true, session: null })

  useEffect(() => {
    let active = true
    client.auth.getSession().then(({ data }) => {
      if (active) setState({ loading: false, session: data.session })
    })
    const { data } = client.auth.onAuthStateChange((_event, session) => {
      if (active) setState({ loading: false, session })
    })
    return () => {
      active = false
      data.subscription.unsubscribe()
    }
  }, [client])

  return <AuthContext.Provider value={state}>{children}</AuthContext.Provider>
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth(): AuthState {
  const value = useContext(AuthContext)
  if (!value) throw new Error('useAuth debe usarse dentro de <AuthProvider>')
  return value
}
