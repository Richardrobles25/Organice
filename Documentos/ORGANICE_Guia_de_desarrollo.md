# ORGANICE – Guía de desarrollo del producto completo (v2)

*Equipo: Ricardo y Nicolás · Referencia: Especificación Funcional (RF-001 a RF-119) · Sustituye al documento v1 (enfoque MVP)*

## Índice

0. [Cómo usar esta guía](#0-cómo-usar-esta-guía)
1. [Resumen y alcance](#1-resumen-y-alcance)
2. [Arquitectura y decisiones técnicas](#2-arquitectura-y-decisiones-técnicas)
3. [Reparto del trabajo](#3-reparto-del-trabajo)
4. [Contratos compartidos](#4-contratos-compartidos-se-definen-en-la-fase-1)
5. [Pasos a seguir (Fases 0-5)](#5-pasos-a-seguir)
6. [Puntos de integración](#6-puntos-de-integración)
7. [Riesgos](#7-riesgos)
8. [Checklist general](#8-checklist-general)
9. [Preguntas por responder](#9-preguntas-por-responder)

---

## 0. Cómo usar esta guía

Esta guía dice qué hacer, en qué orden y quién lo hace. El trabajo se divide en dos líneas independientes (**Track A** y **Track B**). Después de unos cimientos que se hacen juntos, cada quien avanza en su track sin esperar al otro, y solo se juntan en puntos de integración ya programados.

**Ciclo que se repite en cada bloque de trabajo:**

1. Abrir el bloque en este documento y leer sus requisitos (RF) en la especificación.
2. Crear una rama: `feat/A3-pagos` (track + bloque + tema).
3. Pedirle el trabajo a Claude Code por partes, un RF o un grupo pequeño a la vez (ver plantilla abajo).
4. Revisar el código, correr las pruebas y probar en celular.
5. Abrir Pull Request; el otro socio lo revisa solo si toca carpetas o contratos compartidos.
6. Marcar las casillas del bloque en este documento.
7. Traer el avance al chat del proyecto "Organice" para confirmar el siguiente paso.

**Plantilla de prompt para Claude Code (por bloque):**

> *"Lee CLAUDE.md y docs/contratos.md. Vamos a implementar el bloque [A3 – Pagos], requisitos [RF-105, RF-106, RF-107] de docs/especificacion.md. Trabaja solo dentro de [src/features/payments y supabase/migrations de tablas propias del Track A]. No cambies contratos compartidos; si hace falta un cambio, detente y explícame cuál. Primero dame un plan corto, luego implementa un RF a la vez con pruebas automáticas."*

---

## 1. Resumen y alcance

ORGANICE se construirá como producto completo: los 119 requisitos de la especificación, agrupados en 5 módulos (Autenticación, Usuarios finales, Proveedores, Administración y Backend/Sistema). El desarrollo lo hace Claude Code, dirigido, revisado y probado por el equipo.

**Recomendación:** aunque el producto salga completo, antes de abrirlo al público conviene una beta cerrada (Fase 5) con salones reales de Tepic. Es la forma más barata de encontrar errores en pagos y reservas antes de que los encuentre un cliente.

---

## 2. Arquitectura y decisiones técnicas

### ADR-001 · Stack principal — Aceptada

- **Frontend** — React + TypeScript, PWA (Vite). *Cubre:* web y celular (iOS 14+ / Android 8+ vía PWA), RNF 7.3.
- **Backend** — Supabase: PostgreSQL, Auth, Storage, Realtime, Edge Functions. *Cubre:* datos, login, archivos, chat en tiempo real, webhooks.
- **Hosting** — Vercel o Netlify (con CDN incluido). *Cubre:* RF-114.
- **Pruebas** — Vitest (unitarias) + Playwright (flujos completos). *Cubre:* QA.

**Por qué:** un solo servicio administrado cubre base de datos, login, archivos y tiempo real; menos código propio significa menos huecos de seguridad y menos trabajo para dos personas.
**Costo:** dependencia de Supabase; si algún día se necesita, Postgres se puede migrar.

### ADR-002 · Trabajo por contratos — Aceptada

Para que ninguno dependa del avance del otro, en la Fase 1 se definen juntos: el modelo completo de la base de datos, las funciones compartidas (con su firma y una versión simulada), los tipos de TypeScript y datos de prueba. Cada track programa contra esos contratos. Cambiar un contrato requiere PR aprobado por ambos.

### ADR-003 · Motor de reservas dentro de la base de datos — Aceptada

Crear, confirmar, cancelar y reprogramar reservas se hace con funciones de Postgres (RPC) y una restricción de exclusión por fecha/turno. Así la doble reserva (RF-068) es imposible aunque dos personas aparten al mismo segundo. Dueño: Track A. Track B solo llama a las funciones.

### ADR-004 · Pagos con adaptador y pagos divididos — Propuesta

Una interfaz única `PaymentProvider` con dos implementaciones: Stripe Connect (RF-105) y Conekta (RF-106). Con Stripe Connect el dinero se divide en la pasarela y la retención post-evento (RF-075) la maneja la pasarela, sin que el dinero pase por la cuenta de ORGANICE.

**Pendiente:** confirmar requisitos fiscales de Stripe Connect y Conekta en México (requieren RFC y figura legal).

### ADR-005 · Búsqueda — Aceptada

Búsqueda con texto completo de Postgres desde el inicio (RF-013 a RF-017). Elasticsearch (RF-116) se implementa al final, detrás de la misma interfaz de búsqueda, para no bloquear el resto del desarrollo.

### Servicios externos sugeridos (por confirmar)

- **Mapas** — Google Maps o Mapbox (RF-018, RF-050)
- **SMS y WhatsApp** — Twilio / WhatsApp Business API (RF-005, RF-103, RF-104)
- **Notificaciones push** — Firebase Cloud Messaging / Web Push (RF-102)
- **Email transaccional** — Resend o SendGrid (RF-101)
- **Facturación CFDI 4.0** — PAC con API (ej. Facturama) (RF-036, RF-092)
- **Firma de contratos** — Firma simple propia (IP + fecha) o Mifiel (RF-058)
- **Tours 360°** — Visor embebido (ej. Pannellum) o Matterport (RF-023)
- **Analíticas** — Google Analytics 4 (RF-100)

---

## 3. Reparto del trabajo

El reparto está pensado para que cada track tenga sus propias pantallas, carpetas y tablas. Track A es más complejo (reservas, pagos, armador); Track B tiene más requisitos pero más sencillos (paneles y administración). **Quién toma cada track: por decidir entre ustedes.**

### Track A — Organizador y transacciones

- **Enfoque:** todo lo que ve y hace quien organiza la fiesta, más el motor de reservas y pagos.
- **Requisitos:** RF-013 a 021, RF-025 a 043, RF-045 a 055, RF-068, RF-105 a 107, RF-108, 110, 113, 116, 117.
- **Carpetas propias:** `src/features/{search, catalog, planner, bookings, payments, chat, reviews, invitations, events}`
- **Tablas propias:** `bookings, payments, events, event_items, conversations, messages, reviews, invitations, guests, favorites`

### Track B — Proveedor, administración y plataforma

- **Enfoque:** todo lo que ve y hace el proveedor y el administrador, más notificaciones y servicios de plataforma.
- **Requisitos:** RF-002, 003, 005, 008, 010 a 012, RF-022 a 024, RF-044, RF-056 a 067, RF-069 a 104, RF-109, 111, 112, 114, 115, 118, 119.
- **Carpetas propias:** `src/features/{provider, admin, notifications, account, media, subscriptions}`
- **Tablas propias:** `providers, services, prices, media, availability, subscriptions, payouts, claims, notifications, coupons, categories, banners, audit_logs`

**Compartido (lo hacen juntos en la Fase 1):** autenticación base (RF-001, 004, 006, 007, 009), roles, diseño visual, rutas, tipos y contratos.

### Reglas para no depender uno del otro

- Cada quien modifica solo sus carpetas y sus tablas.
- Lo compartido (`src/shared`, tipos, contratos, migraciones de tablas ajenas) se cambia solo con PR aprobado por ambos.
- Si necesitas algo del otro track que aún no existe, usa la versión simulada del contrato y los datos de prueba. Nunca se espera.
- Integración solo en los puntos programados (sección 6).
- El archivo `CODEOWNERS` del repo marca quién es dueño de cada carpeta.

---

## 4. Contratos compartidos (se definen en la Fase 1)

- **`check_availability(provider, fecha, turno)`** — dice si un servicio está libre. *Dueño:* A · *Lo usa:* A, B.
- **`create_booking` / `confirm_booking` / `cancel_booking` / `reschedule_booking`** — cambia el estado de una reserva. *Dueño:* A · *Lo usa:* A, B (confirmar, modificar).
- **`refund_booking(booking, monto, motivo)`** — reembolso. *Dueño:* A · *Lo usa:* B (admin, disputas).
- **`block_dates(provider, fechas, origen)`** — bloqueo manual o por sincronización de calendario. *Dueño:* B · *Lo usa:* B.
- **`notify(usuario, tipo, datos)`** — crea una notificación; B decide el canal (email, push, SMS, WhatsApp). *Dueño:* B · *Lo usa:* A, B.
- **`get_provider_public(provider)`** — datos públicos del proveedor para búsqueda y ficha. *Dueño:* B · *Lo usa:* A.
- **`providers.payment_account_id`** — cuenta de pago del proveedor (Stripe Connect / Conekta). *Dueño:* B (alta) · *Lo usa:* A (cobros divididos).
- **Estados de reserva** — pendiente → confirmada → anticipo pagado → pagada → completada; expirada; cancelada; reprogramada. *Dueño:* A · *Lo usa:* Ambos.

---

## 5. Pasos a seguir

### Fase 0 – Preparación (≈1 semana · Ambos)

- [ ] Definir identidad visual básica: logo, 2-3 colores principales y tipografía. No requiere código; se puede hacer en Canva o Figma. *Terminado cuando:* tienen el logo en PNG/SVG y los códigos hexadecimales de los colores listos para el punto 1.7 (Sistema de diseño).
- [ ] Firmar acuerdo entre socios (porcentajes, roles, salida).
- [ ] Decidir quién toma Track A y quién Track B.
- [ ] Crear organización y repositorio privado en GitHub; subir README.md.
- [ ] Crear cuentas: Supabase, Vercel/Netlify, Google Cloud (Maps, OAuth, Analytics), Stripe, Conekta, Twilio, Firebase, Meta for Developers (login con Facebook y WhatsApp Business API). Usar un correo del proyecto, no personal.
- [ ] Guardar credenciales en un gestor de contraseñas compartido; nunca en el repositorio.
- [ ] Subir la especificación a `docs/especificacion.md`.
- [ ] Arrancar en paralelo los trámites de la Fase 4 (legales), porque pagos y facturación dependen de ellos.

### Fase 1 – Cimientos compartidos (≈2 semanas · Ambos)

Es la única fase donde trabajan sobre lo mismo. Al terminarla, cada quien puede avanzar solo.

**1.1 — Proyecto base** · Responsable: Ambos
Crear el proyecto (Vite + React + TS + PWA), estructura de carpetas, ESLint, Prettier.
*Terminado cuando:* corre en local y compila sin errores.

**1.2 — CI/CD** · Responsable: B
CI en GitHub Actions: lint, tipos y pruebas en cada PR; despliegues de vista previa.
*Terminado cuando:* un PR de prueba pasa la CI y genera vista previa.

**1.3 — Modelo de base de datos** · Responsable: Ambos
Modelo completo de base de datos (todas las tablas de los 119 RF) y diagrama.
*Terminado cuando:* diagrama aprobado y migraciones aplicadas en Supabase.

**1.4 — Seguridad por fila (RLS)** · Responsable: Ambos
Políticas de seguridad por fila (RLS) por rol: usuario, proveedor, admin.
*Terminado cuando:* un usuario no puede leer datos de otro (prueba automática).

**1.5 — Contratos compartidos** · Responsable: Ambos
Contratos de la sección 4: firmas, tipos y versión simulada en `docs/contratos.md`.
*Terminado cuando:* las funciones existen y responden con datos simulados.

**1.6 — Autenticación base** · Responsable: A
RF-001, 004, 006, 007, 009 y roles.
*Terminado cuando:* usuario y proveedor se registran, verifican email e inician sesión.

**1.7 — Sistema de diseño** · Responsable: B
Colores, tipografía, componentes base (botones, formularios, tarjetas, calendario), layout y navegación.
*Terminado cuando:* página de muestra con todos los componentes.

**1.8 — Localización es-MX** · Responsable: B
Fechas DD/MM/AAAA, moneda MXN, textos preparados para i18n.
*Terminado cuando:* formateadores con pruebas.

**1.9 — Datos de prueba** · Responsable: A
30 proveedores de distintas categorías, 20 usuarios, 50 reservas en varios estados.
*Terminado cuando:* un comando carga todo en la base local.

**1.10 — CLAUDE.md y CODEOWNERS** · Responsable: Ambos
Reglas, dueños y contratos.
*Terminado cuando:* Claude Code respeta las carpetas en una prueba.

### Fase 2 – Desarrollo en paralelo

Bloques de ≈2 semanas cada uno (estimado; ajustar a sus horas reales). Hacerlos en el orden indicado.

#### Track A – Organizador y transacciones

**A1 · Búsqueda y ficha** — RF-013, 014, 015, 016, 017, 020, 021, 026
Búsqueda por fecha e invitados con `check_availability`; categorías; texto libre; filtros; orden; ficha del proveedor; calendario público; favoritos.
*Terminado cuando:* solo aparecen proveedores disponibles para la fecha buscada.

**A2 · Motor de reservas** — RF-068, 031 (sin pago), 032, 037, 038, 046, 047
Restricción de exclusión; funciones reales de reserva (reemplazan las simuladas); apartar; cancelar; reprogramar; historial; "mis eventos"; expiración automática.
*Terminado cuando:* pruebas de doble reserva simultánea pasan; todos los estados funcionan.

**A3 · Pagos** — RF-105, 106, 107, 031, 033, 034, 035
Adaptador `PaymentProvider`; Stripe Connect; Conekta; anticipo; saldo; MSI; OXXO y SPEI; webhooks; reintentos.
*Terminado cuando:* pago de prueba dividido entre proveedor y ORGANICE con cada método.

**A4 · Armador de fiesta** — RF-027, 028, 029, 030, 025
Wizard de 6 pasos con solo opciones disponibles; checklist por tipo de evento; presupuesto en tiempo real; guardado automático; comparador.
*Terminado cuando:* un evento completo se arma, se guarda, se retoma y se aparta.

**A5 · Comunicación** — RF-039, 040, 041, 042, 048
Chat en tiempo real con archivos y filtro de datos de contacto; agendar visita; checklist de visita; cotización personalizada; centro de notificaciones (usa `notify`).
*Terminado cuando:* usuario y proveedor chatean; teléfonos y correos se ocultan antes de reservar.

**A6 · Reseñas, mapa y factura** — RF-043, 045, 018, 019, 036
Reseñas solo de reservas completadas; reportar reseña; vista en mapa; recomendaciones; CFDI con PAC.
*Terminado cuando:* factura de prueba emitida y descargable (XML y PDF).

**A7 · Invitaciones digitales** — RF-049 a 055
Editor con plantillas; mapa; envío por WhatsApp, email, link y QR; RSVP; panel de invitados; conexión con el evento del armador.
*Terminado cuando:* un invitado confirma asistencia desde el link y aparece en el panel.

**A8 · Sistema** — RF-108, 110, 113, 116, 117
Encriptación de datos sensibles; protección contra ataques y límites de peticiones; caché; Elasticsearch; API pública documentada.
*Terminado cuando:* búsqueda tolera errores de escritura; API documentada.

#### Track B – Proveedor, administración y plataforma

**B1 · Alta y perfil del proveedor** — RF-056, 057, 059, 060, 061, 062, 063, 085
Registro de proveedor; carga de documentos; editor de perfil; galería; videos; catálogo; precios; aprobación por admin.
*Terminado cuando:* un proveedor se registra, lo aprueba el admin y aparece en `get_provider_public`.

**B2 · Calendario** — RF-064, 065, 066, 067
Calendario con turnos; bloqueo manual (`block_dates`); sincronización con Google Calendar y otros (iCal).
*Terminado cuando:* un evento de Google Calendar bloquea la fecha en ORGANICE.

**B3 · Reservas del proveedor** — RF-069, 070, 071, 072, 044
Panel de reservas entrantes; confirmar/rechazar (usa `confirm_booking`); detalle del cliente; modificar reserva; responder reseñas.
*Terminado cuando:* el proveedor confirma una reserva de los datos de prueba.

**B4 · Notificaciones** — RF-101, 102, 103, 104
Implementar `notify` con email, push, SMS y WhatsApp; plantillas; preferencias por usuario.
*Terminado cuando:* una notificación llega por los 4 canales.

**B5 · Dinero y planes del proveedor** — RF-058, 074, 075, 073, 076, 079, 080, 081, 077, 078
Contrato digital; alta de cuenta de pago (`payment_account_id`); pagos y retiros; dashboard financiero; reclamaciones; planes gratis/premium con cobro mensual; estadísticas.
*Terminado cuando:* un proveedor firma, conecta su cuenta y cambia a premium.

**B6 · Admin: operación** — RF-082, 083, 084, 086, 087, 088, 089, 093, 094
Usuarios; suspensión; verificación premium; vista global de reservas; disputas; reembolsos (usa `refund_booking`); moderación.
*Terminado cuando:* el admin resuelve una disputa con reembolso de prueba.

**B7 · Admin: negocio** — RF-090, 091, 092, 095, 096, 097, 098, 099, 100
Dashboard y reportes financieros; facturación a premium; configuración; categorías; cupones; banners; analíticas; Google Analytics.
*Terminado cuando:* un cupón creado por admin se aplica en una reserva.

**B8 · Media avanzada y cuenta** — RF-022, 023, 024, 002, 003, 005, 008, 010, 011, 012
Video walkthrough; tour 360°; simulador de acomodo; login con Google y Facebook; verificación por SMS; 2FA; cambio de contraseña y email; eliminar cuenta.
*Terminado cuando:* un usuario entra con Google y activa 2FA.

**B9 · Sistema** — RF-109, 111, 112, 114, 115, 118, 119
Aviso de privacidad, cookies y derechos ARCO; respaldos; auditoría; CDN; optimización de imágenes; webhooks para proveedores; integración contable.
*Terminado cuando:* banner de cookies funcional y bitácora de acciones de admin.

---

## 6. Puntos de integración

Son los únicos momentos en que se prueban juntos. Si uno llega antes, sigue con su siguiente bloque.

- **I-1 Reservas** — al terminar A2 y B3: usuario aparta → proveedor confirma → usuario ve el cambio.
- **I-2 Dinero** — al terminar A3 y B5: pago dividido a la cuenta real del proveedor; plan premium cambia la comisión a 4%.
- **I-3 Notificaciones** — al terminar A5 y B4: cada evento de reserva, pago y chat notifica por el canal correcto.
- **I-4 Operación** — al terminar A6 y B6: reseñas moderadas; disputas y reembolsos de punta a punta.
- **I-5 Final** — al terminar todos los bloques: pruebas completas de la Fase 3.

### Fase 3 – Integración y calidad (≈3-4 semanas · Ambos)

- [ ] Pruebas completas con Playwright de los flujos: búsqueda → armador → pago → confirmación → evento → reseña.
- [ ] Revisión de seguridad: RLS, permisos por rol, webhooks firmados, datos sensibles cifrados.
- [ ] Revisión de accesibilidad WCAG 2.1 AA (contraste, teclado, lectores de pantalla) — RNF 7.4.
- [ ] Revisión de rendimiento: carga menor a 3 s en 4G, búsqueda menor a 1 s, reserva menor a 2 s — RNF 7.1.
- [ ] Prueba de carga y escalabilidad: simular 10,000 usuarios concurrentes y 1,000 reservas/día sin degradación — RNF 7.2.
- [ ] Pruebas cross-browser en escritorio (Chrome, Firefox, Safari, Edge, últimas 2 versiones) además de celulares reales (Android e iPhone) e instalación como PWA — RNF 7.3.
- [ ] Corregir todo lo encontrado antes de la beta.

### Fase 4 – Legal, fiscal y operación (en paralelo desde la Fase 0)

- [ ] **Registrar la marca en el IMPI y comprar dominio** — proteger el nombre. *Necesario antes de:* Beta.
- [ ] **Definir figura legal y RFC** (persona física con actividad empresarial o S.A.S.) — Stripe, Conekta y el PAC la piden. *Necesario antes de:* Integración I-2.
- [ ] **Contratar PAC para CFDI 4.0** y definir quién factura qué (comisión vs. servicio del proveedor) — RF-036 y RF-092. *Necesario antes de:* Bloque A6.
- [ ] **Aviso de privacidad, términos y condiciones, política de cookies** (revisados por abogado) — LFPDPPP. *Necesario antes de:* Beta.
- [ ] **Contrato marco para proveedores** — RF-058. *Necesario antes de:* Bloque B5.
- [ ] **Aprobación de plantillas de WhatsApp Business por Meta** — RF-104 (tarda días). *Necesario antes de:* Bloque B4.
- [ ] **Conseguir 20-30 proveedores fundadores en Tepic** — que la app no salga vacía. *Necesario antes de:* Beta.

### Fase 5 – Beta cerrada y lanzamiento

- [ ] Dar de alta a los proveedores fundadores con sus fotos y calendarios reales.
- [ ] Invitar a un grupo pequeño de usuarios reales (familiares, conocidos, redes).
- [ ] Configurar monitoreo de uptime y alertas de caída del servicio (objetivo 99.5% — RNF 7.1).
- [ ] Operar 3-4 semanas con soporte por WhatsApp y registrar cada problema.
- [ ] Corregir y lanzar al público en Tepic.

---

## 7. Riesgos

- **Alcance muy grande para dos personas con escuela** → Bloques cortos, trabajo en paralelo real, beta antes del lanzamiento.
- **Uno se atrasa y bloquea al otro** → Contratos con versión simulada y datos de prueba; integración solo en puntos fijos.
- **Pagos o facturación bloqueados por trámites** → Iniciar la Fase 4 desde el principio; los pagos se prueban en modo prueba mientras tanto.
- **Errores de seguridad en código generado con IA** → Supabase Auth y RLS, pruebas automáticas, revisión de PRs en zonas compartidas, revisión de seguridad en la Fase 3.
- **Doble reserva o pagos duplicados** → Restricción en base de datos y reintentos idempotentes; pruebas de concurrencia.
- **Salir sin proveedores** → Captación de fundadores en paralelo al desarrollo.

---

## 8. Checklist general

**Fase 0**
- [ ] Identidad visual (logo, colores, tipografía)
- [ ] Acuerdo de socios
- [ ] Tracks asignados
- [ ] Repo
- [ ] Cuentas de servicios
- [ ] Gestor de contraseñas
- [ ] Especificación en docs

**Fase 1**
- [ ] 1.1 · [ ] 1.2 · [ ] 1.3 · [ ] 1.4 · [ ] 1.5 · [ ] 1.6 · [ ] 1.7 · [ ] 1.8 · [ ] 1.9 · [ ] 1.10

**Track A**
- [ ] A1 · [ ] A2 · [ ] A3 · [ ] A4 · [ ] A5 · [ ] A6 · [ ] A7 · [ ] A8

**Track B**
- [ ] B1 · [ ] B2 · [ ] B3 · [ ] B4 · [ ] B5 · [ ] B6 · [ ] B7 · [ ] B8 · [ ] B9

**Integración**
- [ ] I-1 · [ ] I-2 · [ ] I-3 · [ ] I-4 · [ ] I-5

**Fase 3**
- [ ] Pruebas completas
- [ ] Seguridad
- [ ] Accesibilidad
- [ ] Rendimiento
- [ ] Escalabilidad
- [ ] Compatibilidad cross-browser y celulares reales

**Fase 4**
- [ ] IMPI y dominio
- [ ] Figura legal y RFC
- [ ] PAC
- [ ] Documentos legales
- [ ] Contrato proveedores
- [ ] Plantillas WhatsApp
- [ ] Proveedores fundadores

**Fase 5**
- [ ] Proveedores dados de alta
- [ ] Usuarios beta
- [ ] Monitoreo de uptime configurado
- [ ] Operación beta
- [ ] Lanzamiento

---

## 9. Preguntas por responder

- ¿Quién toma el Track A y quién el Track B?
- ¿Cuántas horas por semana puede dedicar cada uno?
- ¿Con qué figura legal y RFC se darán de alta en Stripe, Conekta y el PAC?
- ¿Quién emite la factura del servicio del proveedor: el proveedor con su propio RFC o solo se factura la comisión de ORGANICE?
- ¿Hay fecha objetivo de lanzamiento o de algún concurso?
