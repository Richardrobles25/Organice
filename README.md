ORGANICE
La app que te arma tu fiesta. Marketplace para encontrar, comparar y apartar todo lo necesario para una fiesta (salón, comida, espectáculo, mobiliario) según la fecha y el número de invitados. Empieza en Tepic, Nayarit, con la meta de operar a nivel nacional.
> **Estado:** 🟡 Fase 0 – Validación. El MVP aún no está en desarrollo.
---
Tabla de contenido
El problema
Alcance del MVP
Stack
Estructura del repositorio
Cómo correr el proyecto
Flujo de una reserva
Forma de trabajo
Roadmap
Equipo
---
El problema
Organizar una fiesta en Tepic implica buscar proveedores en Facebook, pedir recomendaciones y llamar uno por uno para saber quién está disponible en la fecha. Los proveedores, por su lado, manejan sus reservas en agendas de papel o WhatsApp y sufren dobles reservas.
ORGANICE centraliza la oferta con disponibilidad real por fecha y le da al proveedor una agenda digital para gestionar sus apartados.
Alcance del MVP
El MVP incluye solo salones de eventos. Las demás categorías llegan en fases posteriores.
Usuario
Registro, verificación de email e inicio de sesión
Búsqueda por fecha, número de invitados, precio y capacidad
Ficha del salón con fotos, precios y calendario de disponibilidad
Agendar visita al salón
Apartar fecha con anticipo reembolsable (7 días), con tarjeta y OXXO/SPEI
Cancelación e historial de reservas
Proveedor
Registro y verificación manual
Perfil, galería, catálogo y precios
Calendario con turnos y bloqueo de fechas vendidas fuera de la app
Prevención de doble reserva
Panel para confirmar reservas y ver datos del cliente
Administración
Aprobación de proveedores, vista de reservas y reembolsos manuales
Fuera del MVP: chat propio, reseñas, armador de fiesta completa, planes premium, CFDI al usuario final, dashboards financieros y otras categorías de proveedores.
La especificación completa (requisitos `RF-XXX`) está en `docs/`.
Stack
Capa	Tecnología
Frontend	React + TypeScript (PWA)
Backend y base de datos	Supabase (PostgreSQL, Auth, Storage)
Pagos	Mercado Pago o Stripe Connect con pagos divididos — por definir
Emails transaccionales	Por definir
Hosting frontend	Por definir (Vercel o Netlify)
Reglas técnicas
La autenticación se maneja con Supabase Auth; no se implementa login a mano.
ORGANICE no retiene dinero de proveedores: los pagos se dividen en la pasarela.
Nunca se guardan datos de tarjetas.
Estructura del repositorio
> Estructura propuesta; se ajustará al crear el proyecto.
```
organice/
├── docs/               # Especificación, diagramas y decisiones
├── src/
│   ├── components/     # Componentes reutilizables
│   ├── features/       # Módulos por dominio (auth, search, bookings, provider, admin)
│   ├── lib/            # Cliente de Supabase, utilidades, pagos
│   └── pages/          # Pantallas
├── supabase/
│   └── migrations/     # Migraciones de la base de datos
├── tests/
├── CLAUDE.md           # Contexto del proyecto para Claude Code
└── README.md
```
Cómo correr el proyecto
> Pendiente: se completará cuando se inicialice el proyecto.
Requisitos previos: Node.js (LTS), npm y una cuenta de Supabase.
```bash
git clone https://github.com/<usuario>/organice.git
cd organice
npm install
cp .env.example .env    # llenar las variables
npm run dev
```
Variables de entorno (`.env.example`):
```
VITE_SUPABASE_URL=
VITE_SUPABASE_ANON_KEY=
# Pasarela de pagos: por definir
```
> El archivo `.env` nunca se sube al repositorio.
Flujo de una reserva
Estados previstos de una reserva (se definirán a detalle antes de programar):
```
pendiente ──► confirmada ──► anticipo pagado ──► completada
    │              │                │
    └──► expirada  └──► cancelada ◄─┘
```
Pendiente: el usuario solicitó el apartado; el proveedor debe confirmar.
Expirada: el proveedor no confirmó a tiempo o el usuario no pagó el anticipo.
Cancelada: con o sin reembolso, según la política.
Completada: el evento ya ocurrió.
Forma de trabajo
El desarrollo se hace con Claude Code; el equipo dirige, revisa y prueba.
Ramas
`main`: siempre estable.
Una rama por tarea, con el ID del requisito: `feat/RF-061-doble-reserva`, `fix/RF-013-filtro-fecha`.
Commits (formato convencional):
```
feat(RF-061): bloquear apartados en fechas ocupadas
fix(RF-013): corregir filtro por capacidad
docs: actualizar README
```
Pull requests
Todo cambio entra a `main` por PR.
El PR lo revisa el otro socio antes de unirlo.
Definición de terminado: revisado, pruebas pasando y probado en celular.
Claude Code
`CLAUDE.md` contiene el contexto del proyecto, el stack y las reglas de código.
Tareas pequeñas, una por requisito.
Pedir pruebas automáticas para todo lo relacionado con reservas y pagos.
Roadmap
Fase	Objetivo	Estado
0 – Validación	Entrevistas con usuarios y proveedores; MVP a mano	🟡 En curso
1 – MVP	Salones: buscar, agendar visita y apartar	⚪ Pendiente
2 – Piloto	Lanzamiento cerrado en Tepic	⚪ Pendiente
3 – Crecimiento	Más categorías, armador de fiesta completa, reseñas, chat	⚪ Pendiente
El plan detallado está en el documento maestro del proyecto (Google Docs).
Equipo
Ricardo
Nicolás
Estudiantes de Ingeniería en Sistemas Computacionales, Instituto Tecnológico de Tepic.
---
© ORGANICE. Todos los derechos reservados. Repositorio privado.
