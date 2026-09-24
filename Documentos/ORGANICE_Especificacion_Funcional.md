# ORGANICE — Especificación Funcional Completa

*Documento de referencia para desarrollo del sistema*
**Marketplace de servicios para eventos y fiestas**

Autor: Nicolás · Tepic, Nayarit · Abril 2026 · *Versión 1.0*

> 💡 **Cómo usar este documento:** cada funcionalidad tiene un ID único (RF-XXX). Cuando estés desarrollando, puedes referirte a ellos directamente en tu tablero de tareas, commits o documentación técnica.

## Índice

1. [Introducción](#1-introducción)
2. [Módulo de Autenticación y Cuentas](#2-módulo-de-autenticación-y-cuentas) — RF-001 a RF-012
3. [Módulo de Usuarios Finales (Organizadores)](#3-módulo-de-usuarios-finales-organizadores) — RF-013 a RF-055
4. [Módulo de Proveedores](#4-módulo-de-proveedores) — RF-056 a RF-081
5. [Módulo de Administración (Backoffice)](#5-módulo-de-administración-backoffice) — RF-082 a RF-100
6. [Funcionalidades del Sistema (Backend)](#6-funcionalidades-del-sistema-backend) — RF-101 a RF-119
7. [Requerimientos No Funcionales](#7-requerimientos-no-funcionales)
8. [Organización del Desarrollo por Módulos](#8-organización-del-desarrollo-por-módulos)
9. [Glosario de Términos](#9-glosario-de-términos)

---

## 1. Introducción

### 1.1 Propósito del documento

Este documento describe TODAS las funcionalidades que debe tener la plataforma ORGANICE de forma completa e integral. Sirve como referencia principal durante el desarrollo, permite estimar tiempos y comunicar el alcance total del sistema a desarrolladores, colaboradores o inversionistas.

### 1.2 Alcance del sistema

ORGANICE es un marketplace digital que conecta a personas que organizan eventos sociales (XV años, bodas, cumpleaños, bautizos) con proveedores locales (salones, catering, espectáculos, mobiliario, decoración, fotografía, invitaciones digitales). Su valor diferencial es el "Armador de Fiesta Completa": el usuario puede reservar todos los elementos de su evento sincronizados por fecha en un solo flujo.

### 1.3 Tipos de usuarios del sistema

El sistema atiende a cuatro tipos de usuarios con permisos y funcionalidades diferentes:

- **Usuario Final** (Organizador de eventos): busca, compara y reserva servicios.
- **Proveedor**: publica sus servicios, gestiona disponibilidad y responde a reservas.
- **Administrador** (Nicolás y equipo): supervisa la plataforma, resuelve disputas.
- **Visitante** (no registrado): navega el catálogo pero no puede reservar hasta registrarse.

### 1.4 Identificación de funcionalidades

Cada funcionalidad tiene un ID único con el formato RF-XXX (Requerimiento Funcional). Este documento describe el sistema completo: todas las funcionalidades aquí listadas forman parte del alcance total de ORGANICE.

---

## 2. Módulo de Autenticación y Cuentas

Todas las funcionalidades relacionadas con el registro, inicio de sesión y gestión de perfiles de usuarios y proveedores.

### 2.1 Registro de usuarios finales

#### RF-001 — Registro con email y contraseña

*Permite a un usuario crear una cuenta usando su email y una contraseña segura.*

- Formulario con campos: nombre completo, email, contraseña, confirmación de contraseña.
- Validación de email en formato correcto y que no esté ya registrado.
- Validación de contraseña: mínimo 8 caracteres, al menos una mayúscula, un número.
- Encriptación de contraseña con bcrypt o argon2 antes de guardar en base de datos.
- Envío automático de email de verificación al registrarse.
- El usuario no puede reservar hasta que verifique su email.
- Aceptación explícita de términos y condiciones (checkbox obligatorio).
- Aceptación explícita del aviso de privacidad (obligatorio por LFPDPPP en México).

#### RF-002 — Registro con Google (OAuth)

*Permite a un usuario registrarse o iniciar sesión con su cuenta de Google en un solo clic.*

- Botón "Continuar con Google" en pantalla de registro y login.
- Integración con Google OAuth 2.0.
- Al primer login con Google, se crea automáticamente la cuenta y se marca el email como verificado.
- Si el email ya existe con contraseña, se vincula la cuenta de Google al perfil existente.
- Solicita permisos mínimos: nombre, email, foto de perfil.

#### RF-003 — Registro con Facebook

*Similar al de Google pero usando Facebook Login.*

- Botón "Continuar con Facebook" en pantallas de registro y login.
- Integración con Facebook Login SDK.
- Manejo especial cuando Facebook no proporciona email.

#### RF-004 — Verificación de email

*Envío de correo con enlace único para confirmar que el email es válido.*

- Al registrarse, se envía email automáticamente con link único (token válido 24 horas).
- El link redirige a una página que confirma la verificación y activa la cuenta.
- Opción de reenviar el email de verificación si el usuario no lo recibe.
- Mensaje claro en la app: "Verifica tu email antes de reservar".

#### RF-005 — Verificación de teléfono por SMS

*Verificar el número de teléfono del usuario mediante código SMS.*

- Al reservar por primera vez, se pide verificar teléfono.
- Envío de código de 6 dígitos vía SMS (usando Twilio, Vonage o similar).
- Código válido por 10 minutos.
- Máximo 3 intentos fallidos por sesión, luego se bloquea temporalmente.
- El teléfono verificado se usa para comunicación con proveedores.

### 2.2 Inicio de sesión y recuperación

#### RF-006 — Login con email y contraseña

*Pantalla de inicio de sesión con email y contraseña.*

- Formulario simple: email y contraseña.
- Opción "Recordarme" que mantiene sesión activa por 30 días.
- Mensajes de error claros pero sin revelar si el email existe o no (por seguridad).
- Bloqueo temporal (15 minutos) después de 5 intentos fallidos consecutivos.
- Redirect automático a la pantalla que intentaba visitar antes del login.

#### RF-007 — Recuperación de contraseña

*Permite recuperar acceso cuando el usuario olvida su contraseña.*

- Enlace "Olvidé mi contraseña" visible en pantalla de login.
- Formulario para ingresar email.
- Envío de email con link único para restablecer (token válido 1 hora).
- Pantalla para crear nueva contraseña (con misma validación de seguridad).
- Notificación al usuario cuando su contraseña se cambia exitosamente.
- Invalidación de todas las sesiones activas al cambiar contraseña.

#### RF-008 — Autenticación de dos factores (2FA)

*Capa adicional de seguridad para cuentas sensibles.*

- Opcional para usuarios, obligatorio para proveedores y administradores.
- Soporte para apps como Google Authenticator, Authy.
- Códigos de respaldo (10) para uso en caso de perder el dispositivo.
- Configuración desde ajustes de cuenta.

### 2.3 Perfil de usuario

#### RF-009 — Ver y editar perfil personal

*Página donde el usuario puede ver y modificar sus datos personales.*

- Campos editables: nombre, apellidos, teléfono, foto de perfil, fecha de nacimiento (opcional).
- Campo NO editable: email (solo con proceso especial de cambio).
- Preferencias: idioma, notificaciones (email, SMS, push), tipo de evento favorito.
- Guardado automático o botón "Guardar cambios".
- Confirmación visual de que los cambios se guardaron.

#### RF-010 — Cambio de contraseña

*Sección dentro del perfil para cambiar la contraseña.*

- Solicita contraseña actual + nueva + confirmación.
- Aplica las mismas reglas de seguridad de contraseña.
- Notificación por email cuando la contraseña se cambia exitosamente.

#### RF-011 — Cambio de email

*Permite al usuario cambiar su dirección de correo electrónico.*

- Solicita contraseña actual para confirmar identidad.
- Envía verificación al NUEVO email antes de aplicar el cambio.
- Envía notificación al email VIEJO informando del cambio (para detectar hackeos).

#### RF-012 — Eliminar cuenta

*Permite al usuario eliminar permanentemente su cuenta (requerido por LFPDPPP).*

- Confirmación en dos pasos.
- Explicación clara de qué se elimina y qué se conserva (por temas legales/fiscales).
- Los datos personales se eliminan; las reservas históricas se anonimizan.
- Email de confirmación al eliminar.

---

## 3. Módulo de Usuarios Finales (Organizadores)

Todas las funcionalidades diseñadas para las personas que buscan organizar un evento.

### 3.1 Búsqueda y descubrimiento

#### RF-013 — Búsqueda por fecha y número de invitados

*La funcionalidad central: buscar servicios disponibles según fecha del evento y capacidad requerida.*

- Formulario principal en homepage: fecha del evento + número aproximado de invitados.
- Filtrado automático de solo proveedores disponibles esa fecha.
- Filtrado automático de salones con capacidad suficiente.
- Búsqueda persistente: los filtros permanecen mientras navega.
- Sugerencia inteligente si no hay disponibilidad exacta: "¿Considerarías 2 días antes/después?".

#### RF-014 — Navegación por categorías

*Explorar servicios agrupados por tipo (salones, comida, espectáculos, etc.).*

- Página de categoría principal con las 7 categorías (salones, catering, espectáculos, mobiliario, decoración, fotografía, pastelería).
- Icono representativo y foto atractiva para cada categoría.
- Contador de proveedores disponibles por categoría.
- Filtros específicos por categoría (ej: en catering se muestran opciones de tipo de comida).

#### RF-015 — Búsqueda por texto libre

*Buscador tipo Google que permita encontrar proveedores por nombre o palabra clave.*

- Barra de búsqueda con autocompletado.
- Búsqueda en: nombre del proveedor, descripción, categorías, tags.
- Búsquedas recientes guardadas.
- Búsquedas populares sugeridas.

#### RF-016 — Filtros avanzados

*Refinar resultados con múltiples criterios.*

- Filtro por rango de precio (mínimo y máximo).
- Filtro por ubicación / colonia dentro de Tepic.
- Filtro por calificación mínima (4+, 3+ estrellas).
- Filtro por servicios incluidos (aire acondicionado, alberca, cocina, sonido, etc.).
- Filtro por capacidad exacta (para salones).
- Filtro combinable: múltiples filtros aplicados simultáneamente.
- Contador dinámico: "Se encontraron X resultados".

#### RF-017 — Ordenamiento de resultados

*Cambiar el orden en que se muestran los proveedores.*

- Opciones: relevancia (default), precio (menor a mayor), precio (mayor a menor), mejor calificados, más reservados, más cercanos.
- El ordenamiento se combina con los filtros aplicados.

#### RF-018 — Vista en mapa

*Ver los proveedores ubicados en un mapa interactivo de Tepic.*

- Integración con Google Maps o Mapbox.
- Pines de colores según categoría.
- Al hacer clic en un pin: vista rápida del proveedor.
- Filtros aplican tanto a la vista de lista como al mapa.
- Botón para alternar entre vista de lista y vista de mapa.

#### RF-019 — Recomendaciones personalizadas

*Sugerencias basadas en historial y preferencias del usuario.*

- Algoritmo básico basado en categorías vistas, favoritos, reservas previas.
- Sección "Para ti" en la homepage.
- Sugerencias contextuales: "Los usuarios que reservaron X también reservaron Y".

### 3.2 Ficha del proveedor / servicio

#### RF-020 — Vista detallada del proveedor

*Página completa con toda la información de un proveedor/servicio.*

- Galería de fotos (mínimo 5, máximo 20 según plan).
- Nombre del proveedor, categoría, ubicación.
- Descripción detallada del servicio.
- Precio o rango de precios (con nota si requiere cotización).
- Capacidad (para salones), menú (para catering), duración (para shows).
- Servicios incluidos y adicionales.
- Políticas de reserva, cancelación, anticipo.
- Reseñas y calificación promedio.
- Información de contacto (WhatsApp, teléfono) — solo visible tras reservar o pedir cotización.
- Ubicación en mapa.
- Badge de verificación si es proveedor premium.
- Botón principal de acción: "Ver disponibilidad y reservar".

#### RF-021 — Calendario de disponibilidad

*Visualización clara de qué días está disponible el proveedor.*

- Calendario mensual con días marcados: verde (disponible), rojo (ocupado), amarillo (parcial), gris (no disponible).
- Navegación entre meses.
- Al seleccionar un día disponible, muestra horarios/turnos disponibles.
- Salones pueden tener 2 turnos por día (matutino, vespertino/nocturno).

#### RF-022 — Video walkthrough del lugar

*Video corto (2-5 minutos) mostrando el salón o instalaciones.*

- Reproducción integrada en la ficha del proveedor.
- Alojamiento en YouTube o Vimeo (embed) para no consumir storage propio.
- Botón destacado "Ver video del lugar".

#### RF-023 — Tour virtual 360°

*Recorrido inmersivo de 360° por las instalaciones.*

- Integración con Matterport o similar.
- Solo para proveedores Premium.
- Botón destacado "Tour virtual".

#### RF-024 — Simulador de acomodo virtual

*Herramienta para probar diferentes configuraciones de mesas y sillas en un salón.*

- Drag & drop de elementos (mesas redondas, rectangulares, pista de baile, escenario).
- Cálculo automático de capacidad según configuración.
- Vista superior 2D.
- Solo para proveedores Premium.

#### RF-025 — Comparador de proveedores

*Comparar hasta 3 proveedores lado a lado.*

- Botón "Comparar" en cada ficha de proveedor.
- Vista lateral con las 3 fichas mostrando: fotos principales, precios, capacidad, servicios incluidos, calificación.
- Botón para reservar directamente desde la comparación.

#### RF-026 — Favoritos

*Guardar proveedores para revisarlos después.*

- Icono de corazón en cada ficha de proveedor.
- Sección "Mis favoritos" en el perfil del usuario.
- Notificación cuando un favorito baja de precio o tiene promoción.
- Compartir lista de favoritos con familiares.

### 3.3 El Armador de Fiesta Completa (diferenciador clave)

#### RF-027 — Constructor de evento completo

*La funcionalidad estrella: armar toda la fiesta en un solo flujo.*

- Wizard de 5-6 pasos: fecha → invitados → salón → comida → espectáculo → extras.
- En cada paso muestra SOLO opciones disponibles para la fecha.
- Barra de progreso visible.
- Contador de presupuesto que actualiza en tiempo real.
- Posibilidad de saltar pasos y regresar.
- Guardado automático del progreso (por si abandona y regresa).
- Al final: resumen visual completo del evento y precio total.

#### RF-028 — Checklist inteligente por tipo de evento

*Lista de tareas y proveedores recomendados según el tipo de evento.*

- Templates predefinidos: XV años, boda, cumpleaños, bautizo, etc.
- Cada template muestra los proveedores "esenciales" vs "opcionales".
- Marcar cada item cuando esté completado.
- Recordatorios automáticos si falta algo cerca de la fecha.

#### RF-029 — Presupuesto en tiempo real

*Contador visible del gasto total mientras arma su fiesta.*

- Suma automática de todos los servicios seleccionados.
- Desglose por categoría (salón, comida, etc.).
- Alerta si supera un presupuesto previamente establecido.
- Sugerencia de alternativas más económicas si es muy alto.

#### RF-030 — Guardado de eventos en curso

*El usuario puede guardar el evento a medio armar y continuar después.*

- Botón "Guardar y continuar después" en cualquier paso del constructor.
- Lista de "Mis eventos guardados" en el perfil.
- Aviso si algún proveedor guardado ya no está disponible al regresar.

### 3.4 Reservas y pagos

#### RF-031 — Reserva con anticipo

*Reservar un servicio pagando solo un porcentaje (ej: 30%).*

- Formulario de reserva: fecha, hora, cantidad, notas especiales.
- Cálculo automático del anticipo según política del proveedor (20-50%).
- Método de pago: tarjeta de crédito/débito (Stripe/Conekta).
- Confirmación por email y notificación al proveedor.
- Comprobante descargable en PDF.

#### RF-032 — Reserva sin pago (solo apartar)

*Reservar sin pagar aún, con confirmación posterior del proveedor.*

- Estado inicial "Pendiente de confirmación".
- Proveedor tiene 24-48 horas para aceptar o rechazar.
- Si acepta, el usuario tiene 24 horas para pagar el anticipo.

#### RF-033 — Pago del saldo restante

*Pagar el resto del monto después del anticipo.*

- Recordatorios automáticos: 7 días antes, 3 días antes, 1 día antes del evento.
- Botón "Pagar saldo" desde el detalle de la reserva.
- Mismos métodos de pago que el anticipo.
- Comprobante actualizado en PDF.

#### RF-034 — Pagos en cuotas / MSI

*Pagar en meses sin intereses para tickets grandes.*

- Disponible para reservas mayores a cierto monto ($10K MXN).
- 3, 6, 9, 12 MSI según banco.
- Integración con la funcionalidad de MSI de Conekta/Stripe.

#### RF-035 — Métodos de pago alternativos

*Opciones de pago además de tarjeta.*

- OXXO Pay (código para pagar en tienda).
- SPEI (transferencia bancaria).
- Mercado Pago.
- Pago en efectivo directo con el proveedor (con confirmación posterior).

#### RF-036 — Facturación electrónica (CFDI 4.0)

*Emisión de factura fiscal mexicana al pagar.*

- Formulario en checkout: RFC, razón social, uso de CFDI, régimen fiscal.
- Integración con PAC autorizado (Facturama, Contpaq, etc.).
- Emisión automática al confirmar el pago.
- Descarga de XML y PDF de la factura.
- Historial de facturas en el perfil del usuario.

#### RF-037 — Cancelación de reserva

*Cancelar una reserva y solicitar reembolso según política.*

- Botón "Cancelar reserva" visible.
- Muestra claramente la política de cancelación aplicable.
- Cálculo automático del reembolso según días de anticipación.
- Notificación inmediata al proveedor.
- Reembolso procesado a los 5-10 días hábiles.

#### RF-038 — Reprogramación de reserva

*Cambiar la fecha de una reserva ya confirmada.*

- Sujeto a disponibilidad del proveedor.
- Solicitud enviada al proveedor para aprobación.
- Cargo administrativo pequeño (opcional según política).
- Notificaciones automáticas del cambio.

### 3.5 Comunicación con proveedores

#### RF-039 — Chat integrado

*Mensajería directa dentro de la plataforma con cada proveedor.*

- Chat en tiempo real (WebSockets).
- Historial completo de conversaciones por proveedor.
- Envío de imágenes y archivos.
- Notificaciones push, email y SMS de nuevos mensajes.
- Indicador de "leído" / "no leído".
- Filtro automático de datos de contacto para evitar que salgan de la plataforma antes de reservar (prevención de bypass).

#### RF-040 — Agendar visita al salón

*Programar visita física al lugar antes de reservar.*

- Calendario del proveedor mostrando horarios disponibles para visitas.
- Confirmación automática al proveedor.
- Recordatorios al usuario y proveedor 24h antes.
- Opción de reagendar o cancelar la visita.

#### RF-041 — Checklist "qué preguntar al visitar"

*Lista de preguntas útiles cuando el usuario va a visitar un salón.*

- Templates por tipo de servicio: "10 cosas que preguntar en un salón".
- El usuario puede marcar las que ya preguntó.
- Puede agregar preguntas personalizadas.

#### RF-042 — Cotización personalizada

*Solicitar una cotización específica cuando el precio depende de muchos factores.*

- Formulario: fecha, invitados, requerimientos especiales, presupuesto aproximado.
- El proveedor recibe la solicitud y responde con propuesta.
- Cotización con validez limitada (7-15 días).
- El usuario puede aceptar la cotización y convertirla en reserva.

### 3.6 Reseñas y calificaciones

#### RF-043 — Publicar reseña

*Después del evento, calificar y comentar la experiencia con cada proveedor.*

- Solicitud automática 3 días después del evento (por email y push).
- Calificación de 1-5 estrellas.
- Categorías de calificación: puntualidad, calidad, atención, relación precio-calidad.
- Comentario en texto libre (mínimo 20 caracteres, máximo 500).
- Subir hasta 5 fotos del evento (opcional).
- Solo puede reseñar si tuvo una reserva confirmada y pagada.

#### RF-044 — Responder a reseñas

*El proveedor puede responder públicamente a cada reseña.*

- Respuesta única por reseña.
- Se muestra debajo de la reseña original.
- Se puede editar hasta 24 horas después.
- Notificación al usuario cuando el proveedor responde.

#### RF-045 — Reportar reseña

*Reportar reseñas inapropiadas o falsas para revisión por administradores.*

- Motivos: contenido ofensivo, información falsa, spam, competencia desleal.
- El administrador revisa y decide si eliminar.

### 3.7 Historial y gestión personal

#### RF-046 — Historial de reservas

*Ver todas las reservas pasadas y activas.*

- Pestañas: activas, pasadas, canceladas.
- Detalle de cada reserva: proveedor, fecha, monto, estado, comprobante.
- Filtros por año o rango de fechas.
- Exportar historial en Excel/PDF.

#### RF-047 — Mis eventos

*Vista unificada donde el usuario ve TODOS sus eventos organizados (múltiples reservas relacionadas).*

- Agrupa reservas del mismo evento (salón + comida + música = 1 evento).
- Countdown al día del evento.
- Checklist de tareas pendientes.
- Chat unificado con todos los proveedores del evento.

#### RF-048 — Notificaciones

*Sistema de notificaciones dentro de la app.*

- Campana de notificaciones en la barra superior.
- Categorías: reservas, mensajes, promociones, sistema.
- Marcar como leído / no leído.
- Configuración de qué notificaciones recibir (email, SMS, push).

### 3.8 Invitaciones Digitales

Módulo para crear, personalizar y enviar invitaciones digitales del evento directamente desde ORGANICE, sin depender de apps externas.

#### RF-049 — Editor de invitaciones digitales

*Herramienta para diseñar la invitación del evento dentro de la plataforma.*

- Catálogo de plantillas prediseñadas por tipo de evento (XV años, boda, cumpleaños, bautizo, baby shower, etc.).
- Editor visual tipo drag & drop: cambiar colores, tipografías, fotos e imágenes de fondo.
- Campos editables: nombre del festejado, fecha, hora, lugar, dirección, código de vestimenta, mensaje personalizado.
- Subida de fotos propias para personalizar la invitación.
- Vista previa en tiempo real antes de guardar o enviar.
- Guardado de borradores para continuar editando después.

#### RF-050 — Invitación con mapa y ubicación integrada

*La invitación incluye la ubicación del evento con mapa interactivo.*

- Inserción automática del mapa cuando el lugar reservado es un proveedor de ORGANICE (salón, jardín de eventos, etc.).
- Botón "Cómo llegar" que abre Google Maps o Waze con la ruta.
- Opción de agregar ubicación manual si el evento es en un lugar no registrado en la plataforma.

#### RF-051 — Envío digital de invitaciones

*Enviar la invitación a los invitados por distintos canales.*

- Envío por WhatsApp con vista previa enriquecida (link con imagen y datos del evento).
- Envío por email a una lista de contactos.
- Generación de link único compartible para redes sociales.
- Código QR de la invitación para imprimir o compartir.
- Envío masivo a partir de una lista de contactos importada (CSV o desde contactos del teléfono).

#### RF-052 — Confirmación de asistencia (RSVP) digital

*Los invitados confirman su asistencia directamente desde la invitación digital.*

- Botón "Confirmar asistencia" / "No podré asistir" dentro de la invitación.
- Campo para indicar número de acompañantes (dentro del límite que defina el organizador).
- Campo opcional de restricciones alimenticias o alergias.
- El invitado no necesita crear cuenta en ORGANICE para confirmar.
- Notificación al organizador cada vez que alguien confirma o declina.

#### RF-053 — Panel de control de invitados

*Vista para que el organizador administre su lista de invitados y confirmaciones.*

- Lista completa de invitados con estado: confirmado, pendiente, declinado.
- Conteo automático de asistentes confirmados (incluyendo acompañantes).
- Comparación contra el límite de aforo del salón reservado, con alerta si se supera.
- Exportar lista de invitados y confirmaciones en Excel/PDF.
- Reenvío de invitación a quienes no han respondido, con un clic.
- Notas privadas por invitado (ej. mesa asignada, restricciones).

#### RF-054 — Plantillas temáticas y de marca

*Catálogo ampliable de diseños de invitación.*

- Plantillas gratuitas incluidas para todos los usuarios.
- Plantillas premium de diseñadores, con costo adicional o incluidas en reservas de cierto monto.
- Filtros por estilo: elegante, infantil, rústico, moderno, temático.
- Posibilidad de que proveedores de diseño/papelería se den de alta como creadores de plantillas dentro del marketplace.

#### RF-055 — Integración de la invitación con el evento del Armador de Fiesta

*La invitación se conecta automáticamente con los datos ya capturados del evento.*

- Autocompletado de fecha, hora y lugar a partir de los datos del Armador de Fiesta Completa.
- Actualización automática de la invitación si el usuario cambia fecha, hora o lugar de la reserva.
- Aviso a los invitados que ya confirmaron si hay un cambio relevante en fecha u hora.

---

## 4. Módulo de Proveedores

Todas las funcionalidades diseñadas para los negocios que ofrecen servicios en la plataforma.

### 4.1 Registro y onboarding de proveedores

#### RF-056 — Registro de proveedor

*Proceso especializado para que un negocio se registre en la plataforma.*

- Formulario paso a paso: datos del negocio, categoría, ubicación, servicios ofrecidos.
- Solicitud de documentos: identificación del representante legal, RFC, constancia de situación fiscal.
- Verificación manual por parte del equipo ORGANICE (24-48 horas).
- Notificación por email cuando la cuenta es aprobada.
- Tutorial guiado tras la aprobación.

#### RF-057 — Verificación de proveedor

*Proceso para validar la legitimidad del negocio.*

- Revisión manual de documentos por administrador.
- Visita física opcional para validar existencia (proveedores Premium).
- Badge de "Verificado" visible en la ficha del proveedor.
- Diferenciación visual entre verificado y no verificado.

#### RF-058 — Contrato digital de servicios

*Firma electrónica del contrato entre proveedor y ORGANICE.*

- Contrato con términos de uso, comisión, políticas.
- Firma electrónica simple (checkbox + registro de IP y timestamp) o avanzada (con OTP).
- PDF descargable con el contrato firmado.
- Renovación anual automática.

### 4.2 Perfil del proveedor

#### RF-059 — Editor de perfil de negocio

*Editar toda la información pública del negocio.*

- Nombre comercial, descripción, historia, año de fundación.
- Categorías y sub-categorías atendidas.
- Ubicación exacta en mapa.
- Datos de contacto (teléfono, WhatsApp, email, redes sociales).
- Horarios de atención.
- Área de cobertura (radio de servicio para móviles como taquizas).

#### RF-060 — Gestión de galería de fotos

*Subir, ordenar y eliminar fotos del negocio.*

- Plan gratis: hasta 5 fotos. Plan premium: ilimitadas.
- Compresión automática y optimización para carga rápida.
- Reordenamiento con drag & drop.
- Foto principal destacada.
- Categorización de fotos: exterior, interior, eventos pasados, montajes.

#### RF-061 — Gestión de videos

*Subir o vincular videos del negocio.*

- Enlace a YouTube/Vimeo (no consume storage).
- Máximo 3 videos por proveedor.
- Video destacado que se reproduce automáticamente.

#### RF-062 — Catálogo de servicios

*Enlistar los servicios/paquetes específicos que ofrece.*

- Nombre del servicio, descripción, precio (o rango), fotos.
- Categorización dentro del negocio (ej: paquete básico, plata, oro).
- Servicios incluidos en cada paquete (checklist).
- Servicios opcionales/adicionales con precios.
- Duración típica del servicio.

#### RF-063 — Gestión de precios

*Configurar la estructura de precios de forma flexible.*

- Precio fijo, por persona, por hora, por día.
- Precios diferenciados por temporada (alta, media, baja).
- Precios diferenciados por día de la semana.
- Descuentos por reserva anticipada.
- Cargos adicionales por servicios extras.

### 4.3 Calendario y disponibilidad

#### RF-064 — Calendario de disponibilidad

*Herramienta principal para marcar cuándo está disponible el negocio.*

- Vista mensual, semanal, diaria.
- Bloquear días completos o turnos específicos.
- Bloquear días recurrentes (ej: cerrado los lunes).
- Vacaciones o cierres temporales.
- Confirmación visual clara al cambiar disponibilidad.

#### RF-065 — Sincronización con Google Calendar

*Sincronizar el calendario de ORGANICE con Google Calendar del proveedor.*

- Sincronización bidireccional (eventos externos bloquean automáticamente).
- Autorización OAuth con Google.
- Frecuencia de sincronización configurable.

#### RF-066 — Sincronización con otros calendarios

*Soporte para Outlook, Apple Calendar y otros.*

- Estándar iCal para máxima compatibilidad.

#### RF-067 — Múltiples turnos por día

*Permitir 2-3 turnos diferentes en el mismo día (típico en salones).*

- Configuración de turnos: matutino, vespertino, nocturno.
- Horarios personalizables por proveedor.
- Precios diferenciados por turno.

#### RF-068 — Prevención de doble reserva

*El sistema NUNCA permite dos reservas confirmadas en el mismo horario.*

- Bloqueo automático al confirmar una reserva.
- Lock temporal (15 minutos) al iniciar proceso de reserva.
- Manejo de concurrencia en base de datos.

### 4.4 Gestión de reservas del proveedor

#### RF-069 — Panel de reservas entrantes

*Dashboard con todas las reservas por atender.*

- Vista de: pendientes de confirmar, confirmadas, canceladas, pagadas.
- Filtros por fecha, estado, categoría.
- Detalles de cada reserva: cliente, fecha, monto, notas.
- Botones de acción: confirmar, rechazar, contactar cliente.

#### RF-070 — Confirmación de reservas

*Aprobar o rechazar una reserva pendiente.*

- Notificación inmediata al proveedor al recibir una reserva nueva.
- Tiempo máximo para responder: 24-48 horas configurable.
- Al confirmar: notificación al usuario y bloqueo de calendario.
- Al rechazar: motivo obligatorio, notificación al usuario, sugerencia de alternativas.

#### RF-071 — Ver detalles del cliente

*Información del cliente que hizo la reserva.*

- Nombre, teléfono verificado, email.
- Historial en la plataforma (cuántas reservas ha hecho).
- Notas del cliente sobre la reserva.
- Datos de facturación si los requiere.

#### RF-072 — Modificar reserva existente

*Ajustar detalles de una reserva ya confirmada.*

- Modificar hora, cantidad de invitados, notas.
- Requiere aprobación del cliente si cambia condiciones importantes.
- Registro de cambios (audit trail).

### 4.5 Ingresos y pagos al proveedor

#### RF-073 — Dashboard financiero

*Vista de ingresos, comisiones y pagos pendientes.*

- Total facturado en el mes, año.
- Comisiones cobradas por ORGANICE.
- Ingreso neto (después de comisión).
- Próximos pagos a recibir.
- Gráficas comparativas mes a mes.

#### RF-074 — Configuración de cuenta bancaria

*Datos para recibir depósitos de ORGANICE.*

- CLABE interbancaria.
- Banco y titular.
- Validación con SAT (RFC vs titular).
- Verificación con depósito de prueba de $1 MXN.

#### RF-075 — Retiros y pagos automáticos

*ORGANICE deposita al proveedor tras el evento.*

- Retención de fondos hasta 24-48 horas post-evento.
- Depósito automático semanal (viernes) o quincenal (elegible).
- Comprobante de depósito por email.
- Historial completo de pagos.

#### RF-076 — Sistema de reclamaciones

*Reportar problemas con pagos pendientes.*

- Formulario para reclamar pagos no recibidos.
- Notificación al equipo ORGANICE.
- SLA de respuesta: 24 horas hábiles.

### 4.6 Analíticas del proveedor

#### RF-077 — Estadísticas básicas

*Métricas clave del negocio dentro de ORGANICE.*

- Visualizaciones de perfil (semana, mes, año).
- Tasa de conversión (visitas → reservas).
- Ingresos por mes.
- Categorías de eventos más solicitadas.
- Días/horas con más demanda.

#### RF-078 — Estadísticas avanzadas (Premium)

*Analytics profundos solo para proveedores Premium.*

- Comparativa con promedio de la categoría.
- Análisis de reseñas (sentiment analysis).
- Origen del tráfico (búsqueda, favoritos, referencias).
- Recomendaciones automáticas de mejora.

### 4.7 Planes y suscripciones del proveedor

#### RF-079 — Plan Gratuito

*El plan base con funcionalidades limitadas.*

- Comisión: 7% por reserva.
- Máximo 5 fotos.
- Perfil básico sin destacar.
- Sin analíticas avanzadas.
- Soporte por email.

#### RF-080 — Plan Premium

*Suscripción mensual con beneficios adicionales.*

- Precio: $399 MXN/mes (dinámico según modelo).
- Comisión reducida: 4% por reserva.
- Fotos ilimitadas.
- Badge de "Verificado Premium".
- Aparición destacada en búsquedas.
- Analíticas avanzadas.
- Soporte prioritario por WhatsApp.
- Facturación mensual automática.

#### RF-081 — Cambio de plan

*Upgrade o downgrade entre planes.*

- Cambio inmediato con prorateo del cobro.
- Al hacer downgrade, se aplica al siguiente ciclo.

---

## 5. Módulo de Administración (Backoffice)

Panel interno para el equipo de ORGANICE (Nicolás y colaboradores) para operar y supervisar la plataforma.

### 5.1 Gestión de usuarios

#### RF-082 — Listado y búsqueda de usuarios

*Ver, filtrar y buscar todos los usuarios de la plataforma.*

- Tabla con filtros: rol (usuario/proveedor), estado (activo/suspendido), fecha de registro.
- Búsqueda por nombre, email, teléfono.
- Exportación en Excel/CSV.

#### RF-083 — Ver detalle de usuario

*Perfil completo de cualquier usuario para el admin.*

- Datos personales.
- Historial de reservas.
- Historial de pagos.
- Reseñas escritas.
- Reportes recibidos.

#### RF-084 — Suspender / bloquear usuario

*Deshabilitar acceso de un usuario problemático.*

- Suspensión temporal (con fecha de fin).
- Bloqueo permanente.
- Motivo obligatorio.
- Notificación por email al usuario suspendido.
- Registro de auditoría.

### 5.2 Gestión de proveedores

#### RF-085 — Aprobación de proveedores nuevos

*Revisar y aprobar solicitudes de registro de proveedores.*

- Cola de proveedores pendientes.
- Vista de documentos subidos.
- Botones: aprobar, rechazar (con motivo), solicitar más info.
- Envío automático de email según decisión.

#### RF-086 — Verificación premium

*Proceso de verificación exhaustiva para el badge premium.*

- Checklist de requisitos: documentos, visita física, referencias.
- Historial de reseñas.
- Aprobación del badge.

### 5.3 Gestión de reservas

#### RF-087 — Vista global de reservas

*Todas las reservas de la plataforma en un solo lugar.*

- Filtros por: estado, fecha, categoría, proveedor, cliente.
- Estadísticas: reservas del día, semana, mes.
- Alertas de reservas en disputa.

#### RF-088 — Resolución de disputas

*Sistema para arbitrar problemas entre usuario y proveedor.*

- Formulario para reportar disputa (ambas partes).
- Panel del admin con evidencias (chats, fotos, documentos).
- Decisión: reembolso total, parcial, o resolución a favor del proveedor.
- Registro completo de la disputa.

#### RF-089 — Reembolsos manuales

*Procesar reembolsos por casos especiales.*

- Botón "Reembolso manual" en cada reserva.
- Monto configurable.
- Motivo obligatorio.
- Integración con Stripe/Conekta para procesar.

### 5.4 Gestión financiera

#### RF-090 — Dashboard financiero global

*Vista de ingresos totales, comisiones, pagos a proveedores.*

- GMV total (Gross Merchandise Value).
- Comisiones cobradas.
- Costo pasarela.
- Utilidad neta.
- Gráficas de tendencia.

#### RF-091 — Reportes financieros

*Generación de reportes exportables.*

- Reporte mensual de ingresos.
- Reporte de pagos a proveedores.
- Reporte de reembolsos.
- Exportación en Excel y PDF.
- Envío automático mensual por email.

#### RF-092 — Facturación a proveedores premium

*Cobro automático mensual del Plan Premium.*

- Cargo recurrente a la tarjeta guardada del proveedor.
- Emisión de CFDI automática.
- Manejo de fallas de cobro (3 intentos + suspensión).

### 5.5 Moderación de contenido

#### RF-093 — Moderación de reseñas

*Revisar y aprobar reseñas reportadas.*

- Cola de reseñas reportadas.
- Ver contexto: reserva, comunicación previa, historial del usuario.
- Acciones: mantener, editar, eliminar.

#### RF-094 — Moderación de contenido de proveedores

*Revisar fotos y descripciones de proveedores.*

- Detección automática de contenido inapropiado.
- Cola de revisión manual.
- Solicitud de cambio al proveedor.

### 5.6 Configuración de plataforma

#### RF-095 — Configuración general

*Ajustes globales del sistema.*

- Comisión por defecto.
- Fee al usuario (activable).
- Precio del Plan Premium.
- Políticas de cancelación por defecto.
- Datos de contacto de soporte.

#### RF-096 — Gestión de categorías

*Añadir, editar o eliminar categorías y sub-categorías.*

- Estructura jerárquica.
- Iconos y colores por categoría.
- Reasignación de proveedores existentes.

#### RF-097 — Cupones y promociones

*Crear códigos de descuento para usuarios.*

- Descuento fijo o porcentual.
- Validez limitada (fechas, número de usos).
- Aplicable a categorías o proveedores específicos.
- Reporte de uso de cupones.

#### RF-098 — Gestión de banners y contenido de homepage

*Editar el contenido destacado en la página principal.*

- Banners promocionales.
- Proveedores destacados.
- Categorías promocionadas.
- Programación por fechas.

### 5.7 Reportes y analíticas

#### RF-099 — Analíticas generales

*Métricas clave del negocio.*

- Usuarios registrados totales / activos.
- Proveedores totales / activos.
- Reservas por período.
- Ticket promedio.
- Tasa de conversión de visitantes a reservas.
- Churn rate de proveedores.

#### RF-100 — Integración con Google Analytics

*Tracking del comportamiento del usuario.*

- Eventos personalizados.
- Embudos de conversión.
- Origen del tráfico.

---

## 6. Funcionalidades del Sistema (Backend)

Capacidades técnicas del sistema que no son visibles al usuario pero son críticas para el funcionamiento.

### 6.1 Notificaciones

#### RF-101 — Sistema de notificaciones por email

*Envío automatizado de emails para eventos importantes.*

- Integración con servicio SMTP (SendGrid, AWS SES, Mailgun).
- Templates responsivos personalizables.
- Colas de envío para manejar picos.
- Tracking de aperturas y clicks.

#### RF-102 — Notificaciones push

*Push notifications en app móvil y web.*

- Firebase Cloud Messaging (FCM) para móvil.
- Web Push Notifications para navegador.
- Preferencias de notificación por usuario.

#### RF-103 — Notificaciones por SMS

*Mensajes de texto para eventos críticos.*

- Integración con Twilio, Vonage o similar.
- Solo para eventos críticos (verificación, confirmación de reserva).
- Consideración de costos por mensaje.

#### RF-104 — Notificaciones por WhatsApp

*Envío automatizado por WhatsApp Business API.*

- Integración con WhatsApp Business API oficial.
- Templates aprobados por Meta.
- Usado para recordatorios y confirmaciones.

### 6.2 Integraciones de pago

#### RF-105 — Integración con Stripe

*Procesamiento de pagos con tarjeta.*

- Stripe Payment Intents API.
- Soporte 3D Secure (obligatorio en México).
- Webhooks para eventos de pago.
- Manejo de disputas y chargebacks.

#### RF-106 — Integración con Conekta

*Pasarela local mexicana con métodos alternativos.*

- OXXO Pay.
- SPEI.
- Tarjetas.
- Meses sin intereses.
- Webhooks.

#### RF-107 — Sistema de reintentos de pago

*Manejo automático de pagos fallidos.*

- 3 reintentos automáticos con delay incremental.
- Notificación al usuario en cada fallo.
- Registro completo de intentos.

### 6.3 Seguridad

#### RF-108 — Encriptación de datos sensibles

*Protección de información privada.*

- HTTPS obligatorio en toda la plataforma (SSL/TLS).
- Encriptación en base de datos para datos personales (AES-256).
- Hashing de contraseñas con bcrypt/argon2.
- Tokens JWT firmados para autenticación.

#### RF-109 — Cumplimiento LFPDPPP (México)

*Requisitos legales de protección de datos personales.*

- Aviso de privacidad completo y aceptación explícita.
- Derecho ARCO (Acceso, Rectificación, Cancelación, Oposición).
- Registro de consentimientos.
- Portabilidad de datos.

#### RF-110 — Protección contra ataques

*Medidas contra amenazas comunes.*

- Protección CSRF en formularios.
- Protección XSS (escape de HTML).
- SQL Injection prevención (queries parametrizadas / ORM).
- Rate limiting en APIs.
- CAPTCHA en formularios sensibles (reCAPTCHA v3).

#### RF-111 — Backup automático

*Respaldos regulares para prevenir pérdida de datos.*

- Backup diario incremental de base de datos.
- Backup semanal completo.
- Retención: 30 días.
- Almacenamiento en ubicación separada del servidor principal (S3, Cloud Storage).
- Pruebas mensuales de restauración.

#### RF-112 — Auditoría y logs

*Registro de todas las acciones importantes.*

- Log de accesos y autenticaciones.
- Log de cambios en configuración.
- Log de operaciones financieras.
- Retención mínima: 12 meses.
- Búsqueda y filtrado de logs.

### 6.4 Performance y escalabilidad

#### RF-113 — Caché de datos frecuentes

*Almacenamiento en caché para respuestas rápidas.*

- Redis para caché en memoria.
- Caché de: catálogo de proveedores, categorías, resultados de búsqueda populares.
- Invalidación automática al actualizar datos.

#### RF-114 — CDN para archivos estáticos

*Distribución global de imágenes y archivos.*

- Cloudflare o AWS CloudFront.
- Optimización automática de imágenes.
- Compresión gzip/brotli.

#### RF-115 — Optimización de imágenes

*Reducción automática del tamaño de imágenes.*

- Compresión al subir sin perder calidad visible.
- Generación de múltiples tamaños (thumbnail, medium, large).
- Formato WebP para navegadores compatibles.
- Lazy loading.

#### RF-116 — Búsqueda con Elasticsearch

*Motor de búsqueda avanzado para grandes catálogos.*

- Búsqueda por texto completo con relevancia.
- Búsqueda con tolerancia a errores tipográficos.
- Filtros combinados sin degradar performance.
- Autocompletado.

### 6.5 APIs e integraciones

#### RF-117 — API REST pública documentada

*API para integraciones externas.*

- Documentación con Swagger/OpenAPI.
- Autenticación por API keys.
- Rate limiting.
- Versionado (v1, v2).

#### RF-118 — Webhooks para proveedores

*Notificaciones automáticas a sistemas externos.*

- El proveedor puede configurar URLs para recibir eventos.
- Eventos: nueva reserva, cancelación, pago recibido.
- Firma digital para verificar autenticidad.
- Reintentos automáticos ante fallos.

#### RF-119 — Integración con contabilidad (Contpaq, Aspel)

*Sincronización con sistemas contables mexicanos.*

- Exportación de reportes en formato compatible.
- Integración con Contpaq i Comercial.
- Sincronización de CFDIs.

---

## 7. Requerimientos No Funcionales

Características que definen CÓMO debe funcionar el sistema, no solo QUÉ debe hacer.

### 7.1 Performance

- Tiempo de carga inicial de página: menor a 3 segundos en conexión 4G.
- Tiempo de respuesta de búsquedas: menor a 1 segundo.
- Tiempo de respuesta de operaciones críticas (reserva): menor a 2 segundos.
- Uptime objetivo: 99.5% (permite ~3.6 horas de downtime al mes).

### 7.2 Escalabilidad

- Soportar mínimo 10,000 usuarios activos concurrentes.
- Manejar 1,000 reservas por día sin degradación.
- Base de datos preparada para 100,000+ proveedores potenciales.
- Arquitectura horizontal escalable (agregar servidores según demanda).

### 7.3 Compatibilidad

- Web: Chrome, Firefox, Safari, Edge (últimas 2 versiones).
- Móvil: iOS 14+ y Android 8+.
- Responsive design: adaptado a todas las pantallas desde 320px.
- Progressive Web App (PWA) para instalación desde navegador.

### 7.4 Accesibilidad

- Cumplimiento WCAG 2.1 nivel AA.
- Contraste de colores adecuado.
- Navegación por teclado.
- Textos alternativos en imágenes.
- Compatibilidad con lectores de pantalla.

### 7.5 Idioma y localización

- Español mexicano como idioma principal.
- Formato de fecha: DD/MM/YYYY.
- Moneda: MXN con separador de miles.
- Preparado para agregar más idiomas en el futuro (i18n).

### 7.6 Legales y cumplimiento

- Términos y condiciones claros y completos.
- Aviso de privacidad conforme LFPDPPP.
- Política de cookies con banner de consentimiento.
- Facturación electrónica CFDI 4.0.
- Cumplimiento de disposiciones fiscales del SAT.

---

## 8. Organización del Desarrollo por Módulos

El sistema se construirá de forma completa, cubriendo todos los módulos descritos en este documento. A continuación se agrupan las funcionalidades por módulo como referencia para organizar el trabajo, la asignación de tareas y las pruebas.

- **Módulo 1: Autenticación y Cuentas** (RF-001 a RF-012) — Registro, login, verificación, recuperación de contraseña, 2FA y gestión de perfil.
- **Módulo 2: Usuarios Finales** (RF-013 a RF-055) — Búsqueda, ficha de proveedor, Armador de Fiesta Completa, reservas y pagos, chat, reseñas, historial e invitaciones digitales.
- **Módulo 3: Proveedores** (RF-056 a RF-081) — Registro, perfil de negocio, calendario, gestión de reservas, ingresos, analíticas y planes de suscripción.
- **Módulo 4: Administración (Backoffice)** (RF-082 a RF-100) — Gestión de usuarios, proveedores, reservas, finanzas, moderación de contenido, configuración y reportes.
- **Módulo 5: Backend y Sistema** (RF-101 a RF-119) — Notificaciones, pagos, seguridad, performance, escalabilidad e integraciones.

> 💡 **Sugerencia de trabajo:** aunque el sistema se construye completo, sigue siendo más manejable avanzar módulo por módulo en el orden aquí presentado, ya que cada uno depende parcialmente del anterior (por ejemplo, las reservas requieren autenticación funcionando primero). Usa los RF-XXX para trackear avance en tu herramienta de gestión de tareas.

---

## 9. Glosario de Términos

Definiciones de términos técnicos y de negocio usados en este documento.

- **MVP** — Minimum Viable Product. La versión mínima funcional del producto que ya aporta valor.
- **GMV** — Gross Merchandise Value. Volumen total transaccionado en la plataforma.
- **CFDI** — Comprobante Fiscal Digital por Internet. Factura electrónica mexicana.
- **PAC** — Proveedor Autorizado de Certificación. Empresa que certifica CFDIs ante el SAT.
- **LFPDPPP** — Ley Federal de Protección de Datos Personales en Posesión de Particulares.
- **SLA** — Service Level Agreement. Compromiso de nivel de servicio (tiempo de respuesta, uptime).
- **OAuth** — Estándar abierto para autorización delegada (login con Google, Facebook).
- **Webhook** — Notificación HTTP automática que un sistema envía a otro cuando ocurre un evento.
- **Rate limiting** — Limitación de la cantidad de peticiones por unidad de tiempo.
- **Churn rate** — Tasa de abandono. % de proveedores/usuarios que dejan la plataforma en un período.

---

*— Fin del documento —*

**Total: 119 funcionalidades documentadas**
