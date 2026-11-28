import { createBrowserRouter, RouterProvider } from 'react-router'
import { routes } from './app/routes'
import { AuthProvider } from './features/auth'
import { supabase } from './shared/lib/supabase'

const router = createBrowserRouter(routes)

function App() {
  return (
    <AuthProvider client={supabase}>
      <RouterProvider router={router} />
    </AuthProvider>
  )
}

export default App
