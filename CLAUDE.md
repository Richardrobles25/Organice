# CLAUDE.md — Contexto de ORGANICE

Este archivo es lo primero que debes leer al empezar cualquier sesión en este repositorio. Contiene el negocio, las decisiones técnicas ya tomadas y las reglas de trabajo. No las cuestiones ni las cambies sin que el equipo lo pida explícitamente.

## 1. Qué es ORGANICE

Marketplace que centraliza la organización de fiestas y eventos sociales (XV años, bodas, cumpleaños, bautizos) en Tepic, Nayarit, con la meta de operar a nivel nacional. Conecta organizadores con proveedores en 7 categorías: salones, catering, espectáculos, mobiliario, decoración, fotografía y pastelería. Su diferenciador es el "Armador de Fiesta Completa": el usuario arma toda la fiesta en un solo flujo, viendo solo lo disponible para su fecha. El Armador es opcional: cada servicio también se puede buscar y reservar por separado, y **toda reserva pertenece a un evento** (si se aparta un solo servicio, el sistema crea un evento con ese servicio y después se pueden agregar más).

Las invitaciones digitales (RF-049 a RF-055) son una herramienta propia de ORGANICE, no una categoría de proveedores.

**Se construye el producto completo**, no un MVP recortado: los 121 requisitos (`RF-001` a `RF-121`) de `docs/especificacion.md`, agrupados en 5 módulos (Autenticación, Usuarios finales, Proveedores, Administración, Backend/Sistema).

**Equipo:** Ricardo y Nicolás, estudiantes de Ingeniería en Sistemas del Tecnológico de Tepic. Tiempo limitado por la escuela. Dirigen, revisan y prueban todo lo que Claude Code programa.

**Documento de referencia completo:** "ORGANICE – Guía de desarrollo del producto completo (v2)" en Google Docs. Contiene el roadmap por fases, el detalle de cada bloque de trabajo y los puntos de integración. Este `CLAUDE.md` resume lo que Claude Code necesita para programar; la guía es la fuente de verdad del plan.

## 2. Reglas de negocio (no negociables sin aprobación del equipo)

- **El pago pasa por la app.** Nada de "solo contacto, pagas aparte" y nada de pagar en efectivo directo al proveedor (el efectivo se paga por OXXO). El usuario aparta con un anticipo que fija el proveedor (20% a 50% del precio del servicio, con un mínimo de $500 MXN), reembolsable en su totalidad durante 7 días, y paga con tarjeta, OXXO o SPEI.
- **Pagos divididos (split).** ORGANICE nunca retiene dinero de proveedores. La pasarela manda su parte al proveedor y la comisión a ORGANICE directamente. Lo que antes se llamaba "retención" es un pago diferido que maneja la pasarela: libera la parte del proveedor 24 a 48 horas después del evento. Confirmar con un abogado que esto no requiere ningún permiso.
- **Comisión:** 7% al proveedor del plan gratuito y 4% al del plan Premium. Al usuario, una "tarifa de servicio" de 3% que se puede activar o desactivar desde la configuración: arranca en 0% durante la beta cerrada y se activa en el lanzamiento público. Proveedores "fundadores" pueden tener 0% de comisión, pero la cuota de la pasarela nunca la absorbe ORGANICE.
- **ORGANICE solo factura su comisión.** No emite CFDI al usuario final por el servicio del proveedor; eso lo factura el proveedor con su propio RFC.
- **Anti-fuga de comisión:** el contacto (teléfono/WhatsApp) del proveedor se muestra al usuario solo después de apartar. Solo quien reservó por la app puede dejar reseña. La tasa de cierre por la app se usa internamente para el ranking del proveedor, nunca como etiqueta pública de "este proveedor incumple".
- **Reserva instantánea:** si la fecha y el turno están libres, la reserva queda confirmada al instante, sin aprobación del proveedor. El proveedor tiene 24 horas para cancelar sin penalización; después hay multa (monto por definir) y baja de visibilidad. Si el proveedor cancela, el usuario recibe el 100% de reembolso y alternativas. La tasa de cancelación del proveedor se usa internamente para el ranking, nunca como etiqueta pública. Al lanzamiento es obligatoria para todos; la modalidad "con aprobación" queda como mejora futura.
- **Calificación de clientes:** después del evento el proveedor califica al cliente (1 a 5 estrellas y categorías). Es visible solo para otros proveedores y administración, nunca pública. Las calificaciones de ambos lados se publican a ciegas, al mismo tiempo, cuando ambas partes calificaron o a los 14 días.
- **Doble reserva:** debe ser imposible a nivel de base de datos (no solo validación en el frontend), incluso con dos solicitudes simultáneas.
- **Un proveedor puede bloquear fechas vendidas fuera de la app** (manual o por sincronización de Google Calendar), para que el calendario nunca mienta.

## 3. Arquitectura (ADRs aceptadas)

| Decisión | Elegido | Por qué |
|---|---|---|
| Frontend | React + TypeScript, PWA (Vite) | Un solo código para web y celular, sin pasar por tiendas de apps |
| Backend | Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions) | Un servicio administrado cubre datos, login, archivos y tiempo real; menos código propio = menos huecos de seguridad |
| Hosting | Vercel o Netlify | CDN incluido |
| Pruebas | Vitest (unitarias) + Playwright (flujos completos) | — |
| Motor de reservas | Funciones de Postgres (RPC) + restricción de exclusión por fecha/turno | Hace la doble reserva imposible a nivel de base de datos |
| Pagos | Adaptador `PaymentProvider`. La primera versión usa **una sola pasarela** (Stripe Connect o Conekta, la que gane la comparación en modo de prueba); la otra se agrega después con el mismo adaptador. Mercado Pago queda descartado | Pagos divididos y pago diferido sin que ORGANICE retenga dinero |
| Búsqueda | Texto completo de Postgres al inicio; Elasticsearch después detrás de la misma interfaz | No bloquea el resto del desarrollo |

**Reglas técnicas fijas:**
- Nunca implementar login o hash de contraseñas a mano: usar Supabase Auth, que también emite los JWT y cifra la base de datos en reposo. El cifrado propio, a nivel de campo, se reserva para datos muy sensibles como RFC y CLABE.
- Nunca guardar datos de tarjetas.
- Toda tabla con datos de un usuario lleva políticas RLS (Row Level Security) desde que se crea.
- Español de México en toda la interfaz: fechas DD/MM/AAAA, moneda MXN.

## 4. Cómo está dividido el trabajo

El trabajo se divide en dos tracks independientes para que ninguno espere al otro. Antes de dividir, hay una Fase 1 de cimientos compartidos (modelo de base de datos completo, contratos entre tracks con versión simulada, autenticación base, sistema de diseño).

**Track A — Organizador y transacciones**
Carpetas: `src/features/{search,catalog,planner,bookings,payments,chat,reviews,invitations,events}`
Tablas: `bookings, payments, events, event_items, conversations, messages, reviews, invitations, guests, favorites`
Requisitos: RF-013 a 021, RF-025 a 043, RF-045 a 055, RF-068, RF-105 a 108, 110, 113, 116, 117

**Track B — Proveedor, administración y plataforma**
Carpetas: `src/features/{provider,admin,notifications,account,media,subscriptions}`
Tablas: `providers, services, prices, media, availability, subscriptions, payouts, claims, notifications, coupons, categories, banners, audit_logs, client_reviews, provider_penalties`
Requisitos: RF-002, 003, 005, 008, 010 a 012, RF-022 a 024, RF-044, RF-056 a 067, RF-069 a 104, RF-109, 111, 112, 114, 115, 118, 119, RF-120, RF-121

**Regla de oro:** cada quien modifica solo las carpetas y tablas de su track. Los contratos compartidos (`docs/contratos.md`, tipos de TypeScript, tablas de otro track) solo se cambian con Pull Request aprobado por ambos socios.

### Contratos compartidos (definidos en la Fase 1, en `docs/contratos.md`)

- `check_availability(provider, fecha, turno)` — dueño: Track A
- `create_booking / confirm_booking / cancel_booking / reschedule_booking` — dueño: Track A
- `refund_booking(booking, monto, motivo)` — dueño: Track A
- `block_dates(provider, fechas, origen)` — dueño: Track B
- `notify(usuario, tipo, datos)` — dueño: Track B
- `get_provider_public(provider)` — dueño: Track B
- `providers.payment_account_id` — alta: Track B, lo usa Track A para cobros divididos
- Estados de reserva: `confirmada → anticipo_pagado → pagada → completada`, además `expirada`, `cancelada` (con quién canceló: usuario o proveedor, y si fue dentro de las 24 h) y `reprogramada`. Ya no existe el estado `pendiente` — dueño: Track A
- `cancel_booking` registra quién cancela y calcula si cae dentro de la ventana de 24 h del proveedor; si el proveedor cancela fuera de ella, avisa a Track B para crear la penalización (`provider_penalties`)

Si necesitas algo del otro track que aún no existe, usa la versión simulada del contrato, nunca esperes al otro.

## 5. Cómo trabajar en cada sesión

1. Antes de programar, di qué bloque vas a trabajar (por ejemplo "Bloque A3 — Pagos") y qué requisitos cubre (RF-XXX), según la Guía v2.
2. Trabaja solo dentro de las carpetas y tablas del track correspondiente (sección 4). Si el bloque toca algo compartido, dilo explícitamente y pide confirmación antes de tocarlo.
3. Primero da un plan corto de lo que vas a hacer, luego implementa un requisito o un grupo pequeño a la vez.
4. Cada requisito o grupo pequeño va en su propia rama: `feat/<track>-<bloque>-<tema>` (ej. `feat/A3-pagos-stripe`).
5. Todo lo relacionado con reservas, pagos y doble reserva lleva pruebas automáticas obligatorias.
6. Sigue el formato de commits: `feat(RF-XXX): descripción`, `fix(RF-XXX): descripción`, `docs: descripción`.
7. Nunca inventes servicios externos o credenciales; si hace falta una cuenta o llave que no está configurada, dilo y detente.

## 6. Estado del proyecto

- **Fase actual:** Fase 0 — Preparación. Identidad visual lista (idea, nombre y logo definidos). Repositorio de GitHub y proyecto de Supabase (`OrganiceBD`, región `us-east-2`) ya creados. Faltan por resolver: acuerdo entre socios, asignación de tracks, resto de cuentas de servicio, gestor de contraseñas compartido y trámites legales de la Fase 4.
- **Track A asignado a:** Por definir.
- **Track B asignado a:** Por definir.
- **Correo del proyecto:** `organiceadmin@gmail.com` (cuenta principal para todas las cuentas de servicio). **Dominio propio:** se compra al inicio de la Fase 1 (decisión del 04/11/2026, que sustituye a la de no comprarlo), antes de configurar el correo transaccional, el login con Google y Facebook y WhatsApp Business, que lo necesitan. Hasta que exista, no usar un dominio en correos, contratos ni configuración.
- **Pasarela de pagos elegida:** Por definir. La primera versión usa una sola: se abren cuentas de prueba en Stripe Connect y Conekta y se elige comparando pagos divididos, OXXO, SPEI, meses sin intereses y pago diferido. Cuentas de ambas en proceso de alta.
- **Figura legal / RFC:** Por definir.

> Actualiza esta sección conforme avance el proyecto, para que cualquier sesión nueva de Claude Code sepa en qué punto van.

## 7. Qué NO hacer

- No recortar el alcance a un MVP: el producto se construye completo, por bloques, no por "lo mínimo indispensable".
- No implementar autenticación, hash de contraseñas o manejo de tarjetas a mano.
- No modificar código o tablas fuera del track asignado sin PR aprobado.
- No mostrar el contacto del proveedor al usuario antes de que aparte.
- No permitir que una reserva se confirme sin pasar por las funciones RPC con la restricción de exclusión.
