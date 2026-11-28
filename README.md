ORGANICE
La app que te arma tu fiesta. Marketplace para encontrar, comparar y apartar todo lo necesario para una fiesta (salón, banquete, espectáculo, mobiliario, decoración, fotografía y pastelería) según la fecha y el número de invitados, armando la fiesta completa o contratando cada servicio por separado. Empieza en Tepic, Nayarit, con la meta de operar a nivel nacional.
> **Estado:** 🟡 Fase 0 – Preparación. El producto aún no está en desarrollo.
---
Tabla de contenido
El problema
Alcance del producto
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
Alcance del producto
Se construye el producto completo: los 121 requisitos (`RF-001` a `RF-121`) de la especificación, por bloques y en dos tracks. La beta cerrada en Tepic arrancará con salones y proveedores fundadores, pero las demás categorías ya forman parte del producto, no de una fase posterior.
Usuario
Registro (email, Google, Facebook), verificación de email y teléfono, e inicio de sesión
Búsqueda por fecha, número de invitados, precio y capacidad, en 7 categorías
Armador de fiesta completa o reserva de servicios por separado (toda reserva pertenece a un evento)
Ficha del proveedor con fotos, precios y calendario de disponibilidad
Chat, agendar visita y cotización personalizada
Apartar fecha con un anticipo que fija el proveedor (20% a 50%, mínimo $500), reembolsable durante 7 días, con tarjeta, OXXO o SPEI
Cancelación, reprogramación, reseñas e historial de reservas
Invitaciones digitales con confirmación de asistencia (herramienta propia, no una categoría)
Proveedor
Registro y verificación manual
Perfil, galería, catálogo y precios
Calendario con turnos, sincronización con Google Calendar y bloqueo de fechas vendidas fuera de la app
Prevención de doble reserva
Panel de reservas (se confirman al instante; el proveedor puede cancelar sin penalización en las primeras 24 h), datos del cliente y calificación al cliente
Ingresos, estadísticas y planes (gratuito y Premium)
Administración
Aprobación de proveedores, vista de reservas, disputas y reembolsos
Finanzas, moderación de contenido, cupones, banners y configuración
La especificación completa (requisitos `RF-XXX`) está en `Documentos/`.
Stack
Capa	Tecnología
Frontend	React + TypeScript (PWA)
Backend y base de datos	Supabase (PostgreSQL, Auth, Storage)
Pagos	Una sola pasarela con pagos divididos en la primera versión: Stripe Connect o Conekta, por elegir tras compararlas en modo de prueba. Mercado Pago descartado
Emails transaccionales	Por definir (requiere el dominio propio, que se compra al inicio de la Fase 1)
Hosting frontend	Por definir (Vercel o Netlify)
Reglas técnicas
La autenticación se maneja con Supabase Auth; no se implementa login a mano.
ORGANICE no retiene dinero de proveedores: los pagos se dividen en la pasarela, que también libera la parte del proveedor 24 a 48 horas después del evento.
Nunca se guardan datos de tarjetas.
Estructura del repositorio
```
organice/
├── Documentos/          # Especificación, guía, reglas y plan
├── Logos/
├── public/              # Íconos de la PWA
├── src/
│   ├── features/        # Una carpeta por módulo (ver reparto de tracks en CLAUDE.md)
│   ├── shared/          # Componentes, utilidades y tipos compartidos (cambios con PR de ambos)
│   └── test/            # Configuración de las pruebas
├── supabase/
│   └── migrations/      # Migraciones de la base de datos
├── CLAUDE.md            # Contexto del proyecto para Claude Code
└── README.md
```
Cómo correr el proyecto

Requisitos previos: Node.js 24 (mínimo 22.12) y npm. La cuenta de Supabase hará falta a partir del cimiento 1.3.
```bash
git clone https://github.com/Richardrobles25/Organice.git
cd Organice
npm install
cp .env.example .env    # llenar las variables
npm run dev
```

GitHub Actions revisa cada Pull Request (aplicación y base de datos, ver `.github/workflows/ci.yml`). Si sale en rojo, no se hace merge.

### Sistema de diseño

Con `npm run dev`, abre `/sistema` para ver todos los componentes. Se importan desde `src/shared/components`; los colores, fuentes y espacios están en `src/shared/styles/tokens.css`. Siguen las pantallas finales del Figma: Organice Custom v2 en títulos grandes (clase `titulo-grande` o `titulo-seccion`) e Inter en todo lo demás.

Antes de abrir un Pull Request:

```bash
npm run typecheck
npm run lint
npm run format:check
npm test
npm run build
```
Base de datos local (necesita Docker Desktop abierto):

```bash
npm run db:start    # enciende la base (la primera vez descarga imágenes)
npm run db:reset    # borra la base local y aplica todas las migraciones
npm run db:test     # pruebas de la base, incluida la de reservas simultáneas
npm run db:stop
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
esperando pago ──► anticipo pagado     (proveedor que exige anticipo)

confirmada ──► anticipo pagado ──► pagada ──► completada
    │                │              │
    ├──► expirada    └──► cancelada ◄┘
    └──► cancelada
```
Esperando pago: solo si el proveedor exige anticipo; dura 15 minutos con tarjeta o hasta 24 h con OXXO o SPEI, y pasa a anticipo pagado o expirada.
Confirmada: la fecha estaba libre, así que la reserva se confirma al instante (si el proveedor exige anticipo, al pagarlo). El proveedor tiene 24 horas para cancelar sin penalización.
Expirada: el usuario no pagó el anticipo a tiempo.
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
0 – Preparación	Decisiones pendientes, cuentas, trámites y entrevistas con salones y proveedores	🟡 En curso
1 – Cimientos compartidos	Proyecto base, modelo de base de datos, seguridad, contratos, autenticación y sistema de diseño (incluye comprar el dominio)	⚪ Pendiente
2 – Desarrollo en paralelo	Bloques A1 a A8 (organizador y transacciones) y B1 a B9 (proveedor, administración y plataforma)	⚪ Pendiente
3 – Integración y calidad	Pruebas completas, seguridad, accesibilidad, rendimiento y compatibilidad	⚪ Pendiente
4 – Legal, fiscal y operación	Figura legal, RFC, PAC, avisos legales y proveedores fundadores (en paralelo desde la Fase 0)	⚪ Pendiente
5 – Beta cerrada y lanzamiento	Beta en Tepic con salones y proveedores fundadores, y después lanzamiento público	⚪ Pendiente
El plan detallado está en la Guía de desarrollo v2 (`Documentos/`).
Equipo
Ricardo
Nicolás
Estudiantes de Ingeniería en Sistemas Computacionales, Instituto Tecnológico de Tepic.
---
© ORGANICE. Todos los derechos reservados. Repositorio privado.
