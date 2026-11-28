import type { RouteObject } from 'react-router'
import { Inicio, NoEncontrada, Sistema } from './pages'

// Rutas de la app (cimiento 1.6). Cada bloque agrega aquí sus pantallas.
// Las de acceso (registro, inicio de sesión, recuperar contraseña, perfil) llegan en el siguiente paso.

export const routes: RouteObject[] = [
  { path: '/', element: <Inicio /> },
  { path: '/sistema', element: <Sistema /> },
  { path: '*', element: <NoEncontrada /> },
]
