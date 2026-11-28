import { createClient } from '@supabase/supabase-js'

// Cliente único de Supabase para toda la app (cimiento 1.6).
// Los valores salen de `.env` (copia `.env.example`). En local los da `npx supabase status`.
const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  throw new Error(
    'Falta configurar Supabase: copia .env.example como .env y llena VITE_SUPABASE_URL y VITE_SUPABASE_ANON_KEY.',
  )
}

export const supabase = createClient(url, anonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    // Lee la sesión que llega en los enlaces de verificación y de recuperar contraseña.
    detectSessionInUrl: true,
    flowType: 'pkce',
  },
})
