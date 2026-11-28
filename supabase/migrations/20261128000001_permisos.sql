-- Cimiento 1.4 · Permisos por rol (RLS). Ver docs/permisos.md.
-- Regla: lo que no esté permitido aquí queda bloqueado. Reservas, pagos y horarios no se escriben
-- directo desde la app, solo con funciones controladas (llegan con los contratos y sus bloques).

-- ============================================================ Todo cerrado por defecto
revoke all on all tables in schema public from anon, authenticated;
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon, authenticated;

-- ============================================================ Funciones de apoyo
-- Esquema que la API no expone. security definer: consultan sin que las políticas se llamen entre sí.
create schema private;
grant usage on schema private to anon, authenticated;

create function private.is_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.user_roles where profile_id = (select auth.uid()) and role = 'admin')
$$;
create function private.owns_provider(p uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.providers where id = p and owner_id = (select auth.uid()))
$$;
create function private.provider_is_public(p uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.providers where id = p and status = 'aprobado')
$$;
create function private.owns_service(s uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.services x join public.providers p on p.id = x.provider_id where x.id = s and p.owner_id = (select auth.uid()))
$$;
create function private.service_is_public(s uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.services x join public.providers p on p.id = x.provider_id where x.id = s and p.status = 'aprobado')
$$;
create function private.owns_resource(r uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.resources x join public.providers p on p.id = x.provider_id where x.id = r and p.owner_id = (select auth.uid()))
$$;
create function private.resource_is_public(r uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.resources x join public.providers p on p.id = x.provider_id where x.id = r and p.status = 'aprobado')
$$;
create function private.owns_event(e uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.events where id = e and user_id = (select auth.uid()))
$$;
create function private.booking_is_mine(b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.bookings where id = b and user_id = (select auth.uid()))
$$;
create function private.booking_is_for_my_business(b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.bookings x join public.providers p on p.id = x.provider_id where x.id = b and p.owner_id = (select auth.uid()))
$$;
create function private.booking_party(b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select private.booking_is_mine(b) or private.booking_is_for_my_business(b)
$$;
create function private.booking_completed(b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.bookings where id = b and status = 'completada')
$$;
-- "Anticipo pagado": la condición para ver datos de contacto, en los dos sentidos.
create function private.paid_with_provider(p uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.bookings where provider_id = p and user_id = (select auth.uid()) and status in ('anticipo_pagado', 'pagada', 'completada'))
$$;
create function private.client_has_paid_me(u uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.bookings x join public.providers p on p.id = x.provider_id where x.user_id = u and p.owner_id = (select auth.uid()) and x.status in ('anticipo_pagado', 'pagada', 'completada'))
$$;
create function private.paid_client_of_booking(b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.bookings x where x.id = b and private.client_has_paid_me(x.user_id))
$$;
create function private.conversation_party(c uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.conversations x join public.providers p on p.id = x.provider_id where x.id = c and (select auth.uid()) in (x.user_id, p.owner_id))
$$;
create function private.dispute_party(d uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.disputes x where x.id = d and private.booking_party(x.booking_id))
$$;
create function private.owns_invitation(i uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.invitations x where x.id = i and private.owns_event(x.event_id))
$$;
create function private.owns_guest(g uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.guests x where x.id = g and private.owns_invitation(x.invitation_id))
$$;
grant execute on all functions in schema private to anon, authenticated;


-- ============================================================ Cuentas
grant select on public.profiles to authenticated;
create policy profiles_ver on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select private.is_admin()));
grant update (full_name, last_name, phone, avatar_url, birth_date, favorite_event_type) on public.profiles to authenticated;
create policy profiles_editar on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
grant select on public.user_roles to authenticated;
create policy user_roles_ver on public.user_roles for select to authenticated
  using (profile_id = (select auth.uid()) or (select private.is_admin()));
grant select on public.consents to authenticated;
create policy consents_ver on public.consents for select to authenticated
  using (profile_id = (select auth.uid()) or (select private.is_admin()));
grant insert (profile_id, document, version) on public.consents to authenticated;
create policy consents_crear on public.consents for insert to authenticated
  with check (profile_id = (select auth.uid()));
grant select on public.privacy_requests to authenticated;
create policy privacy_requests_ver on public.privacy_requests for select to authenticated
  using (profile_id = (select auth.uid()) or (select private.is_admin()));
grant insert (profile_id, type) on public.privacy_requests to authenticated;
create policy privacy_requests_crear on public.privacy_requests for insert to authenticated
  with check (profile_id = (select auth.uid()));
grant select, insert, update, delete on public.user_sanctions to authenticated;
create policy user_sanctions_ver on public.user_sanctions for select to authenticated
  using (profile_id = (select auth.uid()) or (select private.is_admin()));
create policy user_sanctions_admin on public.user_sanctions for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- ============================================================ Proveedores y catálogo
-- cancel_rate, closing_rate y payment_account_id no se leen directo: ver my_provider_internal().
grant select (id, owner_id, name, slug, description, history, founded_year, colonia, lat, lng, coverage_km, business_hours, status, verified_at, premium_badge, is_founder, deposit_pct, requires_deposit_to_book, cancellation_policy, payout_frequency, rating_avg, created_at, updated_at) on public.providers to anon, authenticated;
create policy providers_publicos on public.providers for select to anon
  using (status = 'aprobado');
create policy providers_ver on public.providers for select to authenticated
  using (status = 'aprobado' or owner_id = (select auth.uid()) or (select private.is_admin()));
grant insert (owner_id, slug, name, description, history, founded_year, colonia, lat, lng, coverage_km, business_hours, deposit_pct, requires_deposit_to_book, cancellation_policy, payout_frequency) on public.providers to authenticated;
create policy providers_crear on public.providers for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'pendiente');
grant update (name, description, history, founded_year, colonia, lat, lng, coverage_km, business_hours, deposit_pct, requires_deposit_to_book, cancellation_policy, payout_frequency) on public.providers to authenticated;
create policy providers_editar on public.providers for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

-- El contacto: el dueño, y el cliente solo con el anticipo pagado (anti-fuga).
grant select on public.provider_contacts to authenticated;
create policy provider_contacts_ver on public.provider_contacts for select to authenticated
  using (private.owns_provider(provider_id) or private.paid_with_provider(provider_id) or (select private.is_admin()));
grant insert (provider_id, phone, whatsapp, email, social) on public.provider_contacts to authenticated;
create policy provider_contacts_crear on public.provider_contacts for insert to authenticated
  with check (private.owns_provider(provider_id));
grant update (phone, whatsapp, email, social) on public.provider_contacts to authenticated;
create policy provider_contacts_editar on public.provider_contacts for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id));
grant select on public.provider_documents to authenticated;
create policy provider_documents_ver on public.provider_documents for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant insert (provider_id, type, file_path) on public.provider_documents to authenticated;
create policy provider_documents_crear on public.provider_documents for insert to authenticated
  with check (private.owns_provider(provider_id));
-- RFC y CLABE cifrados: se guardan desde el servidor; ni siquiera el dueño lee el cifrado.
grant select (provider_id, bank, holder, verified_at, created_at, updated_at) on public.provider_billing to authenticated;
create policy provider_billing_ver on public.provider_billing for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.provider_contracts to authenticated;
create policy provider_contracts_ver on public.provider_contracts for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.provider_categories to anon, authenticated;
create policy provider_categories_publico on public.provider_categories for select to anon
  using (private.provider_is_public(provider_id));
create policy provider_categories_ver on public.provider_categories for select to authenticated
  using ((private.provider_is_public(provider_id)) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert, update, delete on public.provider_categories to authenticated;
create policy provider_categories_crear on public.provider_categories for insert to authenticated
  with check (private.owns_provider(provider_id));
create policy provider_categories_editar on public.provider_categories for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id));
create policy provider_categories_borrar on public.provider_categories for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.services to anon, authenticated;
create policy services_publico on public.services for select to anon
  using (private.provider_is_public(provider_id));
create policy services_ver on public.services for select to authenticated
  using ((private.provider_is_public(provider_id)) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert, update, delete on public.services to authenticated;
create policy services_crear on public.services for insert to authenticated
  with check (private.owns_provider(provider_id));
create policy services_editar on public.services for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id));
create policy services_borrar on public.services for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.shifts to anon, authenticated;
create policy shifts_publico on public.shifts for select to anon
  using (private.provider_is_public(provider_id));
create policy shifts_ver on public.shifts for select to authenticated
  using ((private.provider_is_public(provider_id)) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert, update, delete on public.shifts to authenticated;
create policy shifts_crear on public.shifts for insert to authenticated
  with check (private.owns_provider(provider_id));
create policy shifts_editar on public.shifts for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id));
create policy shifts_borrar on public.shifts for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.visit_hours to anon, authenticated;
create policy visit_hours_publico on public.visit_hours for select to anon
  using (private.provider_is_public(provider_id));
create policy visit_hours_ver on public.visit_hours for select to authenticated
  using ((private.provider_is_public(provider_id)) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert, update, delete on public.visit_hours to authenticated;
create policy visit_hours_crear on public.visit_hours for insert to authenticated
  with check (private.owns_provider(provider_id));
create policy visit_hours_editar on public.visit_hours for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id));
create policy visit_hours_borrar on public.visit_hours for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.resources to anon, authenticated;
create policy resources_publico on public.resources for select to anon
  using (private.provider_is_public(provider_id));
create policy resources_ver on public.resources for select to authenticated
  using ((private.provider_is_public(provider_id)) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert, update, delete on public.resources to authenticated;
create policy resources_crear on public.resources for insert to authenticated
  with check (private.owns_provider(provider_id));
create policy resources_editar on public.resources for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id));
create policy resources_borrar on public.resources for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.service_addons to anon, authenticated;
create policy service_addons_publico on public.service_addons for select to anon
  using (private.service_is_public(service_id));
create policy service_addons_ver on public.service_addons for select to authenticated
  using ((private.service_is_public(service_id)) or private.owns_service(service_id) or (select private.is_admin()));
grant insert, update, delete on public.service_addons to authenticated;
create policy service_addons_crear on public.service_addons for insert to authenticated
  with check (private.owns_service(service_id));
create policy service_addons_editar on public.service_addons for update to authenticated
  using (private.owns_service(service_id))
  with check (private.owns_service(service_id));
create policy service_addons_borrar on public.service_addons for delete to authenticated
  using (private.owns_service(service_id));
grant select on public.service_amenities to anon, authenticated;
create policy service_amenities_publico on public.service_amenities for select to anon
  using (private.service_is_public(service_id));
create policy service_amenities_ver on public.service_amenities for select to authenticated
  using ((private.service_is_public(service_id)) or private.owns_service(service_id) or (select private.is_admin()));
grant insert, update, delete on public.service_amenities to authenticated;
create policy service_amenities_crear on public.service_amenities for insert to authenticated
  with check (private.owns_service(service_id));
create policy service_amenities_editar on public.service_amenities for update to authenticated
  using (private.owns_service(service_id))
  with check (private.owns_service(service_id));
create policy service_amenities_borrar on public.service_amenities for delete to authenticated
  using (private.owns_service(service_id));
grant select on public.prices to anon, authenticated;
create policy prices_publico on public.prices for select to anon
  using (private.service_is_public(service_id));
create policy prices_ver on public.prices for select to authenticated
  using ((private.service_is_public(service_id)) or private.owns_service(service_id) or (select private.is_admin()));
grant insert, update, delete on public.prices to authenticated;
create policy prices_crear on public.prices for insert to authenticated
  with check (private.owns_service(service_id));
create policy prices_editar on public.prices for update to authenticated
  using (private.owns_service(service_id))
  with check (private.owns_service(service_id));
create policy prices_borrar on public.prices for delete to authenticated
  using (private.owns_service(service_id));
grant select on public.service_resources to anon, authenticated;
create policy service_resources_publico on public.service_resources for select to anon
  using (private.service_is_public(service_id));
create policy service_resources_ver on public.service_resources for select to authenticated
  using ((private.service_is_public(service_id)) or (private.owns_service(service_id) and private.owns_resource(resource_id)) or (select private.is_admin()));
grant insert, update, delete on public.service_resources to authenticated;
create policy service_resources_crear on public.service_resources for insert to authenticated
  with check ((private.owns_service(service_id) and private.owns_resource(resource_id)));
create policy service_resources_editar on public.service_resources for update to authenticated
  using ((private.owns_service(service_id) and private.owns_resource(resource_id)))
  with check ((private.owns_service(service_id) and private.owns_resource(resource_id)));
create policy service_resources_borrar on public.service_resources for delete to authenticated
  using ((private.owns_service(service_id) and private.owns_resource(resource_id)));
grant select on public.availability to anon, authenticated;
create policy availability_publico on public.availability for select to anon
  using (private.resource_is_public(resource_id));
create policy availability_ver on public.availability for select to authenticated
  using ((private.resource_is_public(resource_id)) or private.owns_resource(resource_id) or (select private.is_admin()));
grant insert, update, delete on public.availability to authenticated;
create policy availability_crear on public.availability for insert to authenticated
  with check (private.owns_resource(resource_id));
create policy availability_editar on public.availability for update to authenticated
  using (private.owns_resource(resource_id))
  with check (private.owns_resource(resource_id));
create policy availability_borrar on public.availability for delete to authenticated
  using (private.owns_resource(resource_id));

-- Fotos y videos: el público solo ve lo aprobado; el proveedor no puede aprobarse solo.
grant select on public.media to anon, authenticated;
create policy media_publico on public.media for select to anon
  using (moderation_status = 'aprobado' and private.provider_is_public(provider_id));
create policy media_ver on public.media for select to authenticated
  using ((moderation_status = 'aprobado' and private.provider_is_public(provider_id)) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert (provider_id, service_id, type, url, section, position, is_main) on public.media to authenticated;
create policy media_crear on public.media for insert to authenticated
  with check (private.owns_provider(provider_id) and (service_id is null or private.owns_service(service_id)));
grant update (service_id, type, url, section, position, is_main) on public.media to authenticated;
create policy media_editar on public.media for update to authenticated
  using (private.owns_provider(provider_id))
  with check (private.owns_provider(provider_id) and (service_id is null or private.owns_service(service_id)));
grant delete on public.media to authenticated;
create policy media_borrar on public.media for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.floor_plans to authenticated;
create policy floor_plans_ver on public.floor_plans for select to authenticated
  using (owner_id = (select auth.uid()) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert (provider_id, owner_id, layout, capacity) on public.floor_plans to authenticated;
create policy floor_plans_crear on public.floor_plans for insert to authenticated
  with check (owner_id = (select auth.uid()) and private.provider_is_public(provider_id) or private.owns_provider(provider_id) and owner_id = (select auth.uid()));
grant update (layout, capacity) on public.floor_plans to authenticated;
create policy floor_plans_editar on public.floor_plans for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
grant delete on public.floor_plans to authenticated;
create policy floor_plans_borrar on public.floor_plans for delete to authenticated
  using (owner_id = (select auth.uid()));

-- ============================================================ Datos de referencia (todos leen, solo admin escribe)
grant select on public.categories to anon, authenticated;
create policy categories_publico on public.categories for select to anon, authenticated
  using (true);
grant insert, update, delete on public.categories to authenticated;
create policy categories_admin on public.categories for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select on public.amenities to anon, authenticated;
create policy amenities_publico on public.amenities for select to anon, authenticated
  using (true);
grant insert, update, delete on public.amenities to authenticated;
create policy amenities_admin on public.amenities for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select on public.banners to anon, authenticated;
create policy banners_publico on public.banners for select to anon, authenticated
  using (true);
grant insert, update, delete on public.banners to authenticated;
create policy banners_admin on public.banners for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select on public.event_templates to anon, authenticated;
create policy event_templates_publico on public.event_templates for select to anon, authenticated
  using (true);
grant insert, update, delete on public.event_templates to authenticated;
create policy event_templates_admin on public.event_templates for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select on public.invitation_templates to anon, authenticated;
create policy invitation_templates_publico on public.invitation_templates for select to anon, authenticated
  using (true);
grant insert, update, delete on public.invitation_templates to authenticated;
create policy invitation_templates_admin on public.invitation_templates for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));

-- ============================================================ Solo administración
grant select, insert, update, delete on public.app_settings to authenticated;
create policy app_settings_admin on public.app_settings for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select, insert, update, delete on public.coupons to authenticated;
create policy coupons_admin on public.coupons for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select, insert, update, delete on public.notification_templates to authenticated;
create policy notification_templates_admin on public.notification_templates for all to authenticated
  using ((select private.is_admin()))
  with check ((select private.is_admin()));
grant select on public.audit_logs to authenticated;
create policy audit_logs_ver on public.audit_logs for select to authenticated
  using ((select private.is_admin()));

-- ============================================================ Calendario
-- Libre u ocupado, sin decir quién: booking_id no se expone. Se escribe solo con funciones.
grant select (resource_id, during, kind, expires_at) on public.resource_slots to anon, authenticated;
create policy resource_slots_publico on public.resource_slots for select to anon
  using (private.resource_is_public(resource_id));
create policy resource_slots_ver on public.resource_slots for select to authenticated
  using (private.resource_is_public(resource_id) or private.owns_resource(resource_id) or (select private.is_admin()));
grant select (id, provider_id, type, ical_url, sync_minutes, last_sync_at, created_at, updated_at) on public.calendar_connections to authenticated;
create policy calendar_connections_ver on public.calendar_connections for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant delete on public.calendar_connections to authenticated;
create policy calendar_connections_borrar on public.calendar_connections for delete to authenticated
  using (private.owns_provider(provider_id));
grant select on public.external_events to authenticated;
create policy external_events_ver on public.external_events for select to authenticated
  using (exists (select 1 from public.calendar_connections c where c.id = connection_id) );

-- ============================================================ Eventos y reservas
grant select on public.events to authenticated;
create policy events_ver on public.events for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));
grant insert (user_id, type, name, date, guest_count, budget, status, wizard_step) on public.events to authenticated;
create policy events_crear on public.events for insert to authenticated
  with check (user_id = (select auth.uid()));
grant update (type, name, date, guest_count, budget, status, wizard_step) on public.events to authenticated;
create policy events_editar on public.events for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant delete on public.events to authenticated;
create policy events_borrar on public.events for delete to authenticated
  using (user_id = (select auth.uid()));
grant select on public.event_items to authenticated;
create policy event_items_ver on public.event_items for select to authenticated
  using (private.owns_event(event_id) or (select private.is_admin()));
grant insert (event_id, service_id, estimated_price) on public.event_items to authenticated;
create policy event_items_crear on public.event_items for insert to authenticated
  with check (private.owns_event(event_id));
grant update (service_id, estimated_price) on public.event_items to authenticated;
create policy event_items_editar on public.event_items for update to authenticated
  using (private.owns_event(event_id))
  with check (private.owns_event(event_id));
grant delete on public.event_items to authenticated;
create policy event_items_borrar on public.event_items for delete to authenticated
  using (private.owns_event(event_id));
grant select on public.event_tasks to authenticated;
create policy event_tasks_ver on public.event_tasks for select to authenticated
  using (private.owns_event(event_id) or (select private.is_admin()));
grant insert (event_id, title, essential, done_at, remind_at) on public.event_tasks to authenticated;
create policy event_tasks_crear on public.event_tasks for insert to authenticated
  with check (private.owns_event(event_id));
grant update (title, essential, done_at, remind_at) on public.event_tasks to authenticated;
create policy event_tasks_editar on public.event_tasks for update to authenticated
  using (private.owns_event(event_id))
  with check (private.owns_event(event_id));
grant delete on public.event_tasks to authenticated;
create policy event_tasks_borrar on public.event_tasks for delete to authenticated
  using (private.owns_event(event_id));

-- La comisión no se lee directo: ver provider_booking_commissions().
grant select (id, event_id, user_id, provider_id, service_id, resource_id, during, guest_count, notes, status, total, deposit_amount, user_fee, discount, coupon_id, confirmed_at, deposit_due_at, provider_free_cancel_until, cancelled_at, cancelled_by, cancel_reason, policy_snapshot, created_at, updated_at) on public.bookings to authenticated;
create policy bookings_ver on public.bookings for select to authenticated
  using (user_id = (select auth.uid()) or private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.booking_addons to authenticated;
create policy booking_addons_ver on public.booking_addons for select to authenticated
  using (private.booking_party(booking_id) or (select private.is_admin()));
grant select on public.booking_changes to authenticated;
create policy booking_changes_ver on public.booking_changes for select to authenticated
  using (private.booking_party(booking_id) or (select private.is_admin()));
grant select on public.coupon_redemptions to authenticated;
create policy coupon_redemptions_ver on public.coupon_redemptions for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));
grant select on public.quote_requests to authenticated;
create policy quote_requests_ver on public.quote_requests for select to authenticated
  using (user_id = (select auth.uid()) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert (user_id, provider_id, event_id, date, guest_count, requirements, budget) on public.quote_requests to authenticated;
create policy quote_requests_crear on public.quote_requests for insert to authenticated
  with check (user_id = (select auth.uid()) and private.provider_is_public(provider_id) and (event_id is null or private.owns_event(event_id)));
grant select on public.quotes to authenticated;
create policy quotes_ver on public.quotes for select to authenticated
  using (exists (select 1 from public.quote_requests r where r.id = request_id) );
grant insert (request_id, amount, detail, valid_until) on public.quotes to authenticated;
create policy quotes_crear on public.quotes for insert to authenticated
  with check (exists (select 1 from public.quote_requests r where r.id = request_id and private.owns_provider(r.provider_id)));
grant select on public.visits to authenticated;
create policy visits_ver on public.visits for select to authenticated
  using (user_id = (select auth.uid()) or private.owns_provider(provider_id) or (select private.is_admin()));
grant insert (user_id, provider_id, scheduled_at) on public.visits to authenticated;
create policy visits_crear on public.visits for insert to authenticated
  with check (user_id = (select auth.uid()) and private.provider_is_public(provider_id));
grant update (scheduled_at, status) on public.visits to authenticated;
create policy visits_editar on public.visits for update to authenticated
  using (user_id = (select auth.uid()) or private.owns_provider(provider_id))
  with check (user_id = (select auth.uid()) or private.owns_provider(provider_id));
grant select on public.visit_questions to anon;
create policy visit_questions_plantillas on public.visit_questions for select to anon
  using (user_id is null);
grant select on public.visit_questions to authenticated;
create policy visit_questions_ver on public.visit_questions for select to authenticated
  using (user_id is null or user_id = (select auth.uid()) or (select private.is_admin()));
grant insert (user_id, category_id, provider_id, question, asked) on public.visit_questions to authenticated;
create policy visit_questions_crear on public.visit_questions for insert to authenticated
  with check (user_id = (select auth.uid()));
grant update (question, asked) on public.visit_questions to authenticated;
create policy visit_questions_editar on public.visit_questions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant delete on public.visit_questions to authenticated;
create policy visit_questions_borrar on public.visit_questions for delete to authenticated
  using (user_id = (select auth.uid()));

-- ============================================================ Pagos y dinero
-- Todo lo escribe el servidor (pasarela). La división de cada pago no se lee directo.
grant select (id, booking_id, kind, method, msi, amount, gateway, status, due_at, paid_at, release_at, created_at, updated_at) on public.payments to authenticated;
create policy payments_ver on public.payments for select to authenticated
  using (private.booking_party(booking_id) or (select private.is_admin()));
grant select on public.payment_attempts to authenticated;
create policy payment_attempts_ver on public.payment_attempts for select to authenticated
  using (exists (select 1 from public.payments p where p.id = payment_id));
grant select on public.refunds to authenticated;
create policy refunds_ver on public.refunds for select to authenticated
  using (exists (select 1 from public.payments p where p.id = payment_id));
grant select (id, user_id, legal_name, cfdi_use, tax_regime, zip, created_at, updated_at) on public.billing_profiles to authenticated;
create policy billing_profiles_ver on public.billing_profiles for select to authenticated
  using (user_id = (select auth.uid()) or (select private.is_admin()));
grant select on public.invoices to authenticated;
create policy invoices_ver on public.invoices for select to authenticated
  using (receiver_id = (select auth.uid()) or (select private.is_admin()));
grant select on public.payouts to authenticated;
create policy payouts_ver on public.payouts for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.claims to authenticated;
create policy claims_ver on public.claims for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.provider_penalties to authenticated;
create policy provider_penalties_ver on public.provider_penalties for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.subscriptions to authenticated;
create policy subscriptions_ver on public.subscriptions for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant insert (provider_id, payout_id, description) on public.claims to authenticated;
create policy claims_crear on public.claims for insert to authenticated
  with check (private.owns_provider(provider_id));
grant select on public.subscription_charges to authenticated;
create policy subscription_charges_ver on public.subscription_charges for select to authenticated
  using (exists (select 1 from public.subscriptions s where s.id = subscription_id));
grant select on public.disputes to authenticated;
create policy disputes_ver on public.disputes for select to authenticated
  using (private.booking_party(booking_id) or (select private.is_admin()));
grant insert (booking_id, opened_by, description) on public.disputes to authenticated;
create policy disputes_crear on public.disputes for insert to authenticated
  with check (opened_by = (select auth.uid()) and private.booking_party(booking_id));
grant select on public.dispute_evidence to authenticated;
create policy dispute_evidence_ver on public.dispute_evidence for select to authenticated
  using (private.dispute_party(dispute_id) or (select private.is_admin()));
grant insert (dispute_id, uploaded_by, file_path, note) on public.dispute_evidence to authenticated;
create policy dispute_evidence_crear on public.dispute_evidence for insert to authenticated
  with check (uploaded_by = (select auth.uid()) and private.dispute_party(dispute_id));

-- ============================================================ Chat
-- El admin no lee chats directo: admin_read_conversation() exige disputa y lo anota en la bitácora.
grant select on public.conversations to authenticated;
create policy conversations_ver on public.conversations for select to authenticated
  using (user_id = (select auth.uid()) or private.owns_provider(provider_id));
grant insert (user_id, provider_id, event_id) on public.conversations to authenticated;
create policy conversations_crear on public.conversations for insert to authenticated
  with check (user_id = (select auth.uid()) and private.provider_is_public(provider_id) and (event_id is null or private.owns_event(event_id)));
grant select on public.messages to authenticated;
create policy messages_ver on public.messages for select to authenticated
  using (private.conversation_party(conversation_id));
grant insert (conversation_id, sender_id, body, attachment_path) on public.messages to authenticated;
create policy messages_crear on public.messages for insert to authenticated
  with check (sender_id = (select auth.uid()) and private.conversation_party(conversation_id));
grant update (read_at) on public.messages to authenticated;
create policy messages_editar on public.messages for update to authenticated
  using (sender_id <> (select auth.uid()) and private.conversation_party(conversation_id))
  with check (sender_id <> (select auth.uid()) and private.conversation_party(conversation_id));

-- ============================================================ Reseñas
-- A ciegas: nadie ve la reseña del otro lado hasta que published_at tenga fecha.
grant select on public.reviews to anon, authenticated;
create policy reviews_publicas on public.reviews for select to anon
  using (published_at is not null);
create policy reviews_ver on public.reviews for select to authenticated
  using (published_at is not null or private.booking_is_mine(booking_id) or (select private.is_admin()));
grant insert (booking_id, rating, punctuality, quality, service, value, comment, photos) on public.reviews to authenticated;
create policy reviews_crear on public.reviews for insert to authenticated
  with check (private.booking_is_mine(booking_id) and private.booking_completed(booking_id));
grant update (reply, replied_at) on public.reviews to authenticated;
create policy reviews_editar on public.reviews for update to authenticated
  using (published_at is not null and private.booking_is_for_my_business(booking_id))
  with check (published_at is not null and private.booking_is_for_my_business(booking_id));

-- Calificación de clientes: nunca pública y el cliente no la lee (solo su promedio).
grant select on public.client_reviews to authenticated;
create policy client_reviews_ver on public.client_reviews for select to authenticated
  using (private.booking_is_for_my_business(booking_id) or (published_at is not null and private.paid_client_of_booking(booking_id) and not private.booking_is_mine(booking_id)) or (select private.is_admin()));
grant insert (booking_id, rating, payment_punctuality, respect, agreements, comment) on public.client_reviews to authenticated;
create policy client_reviews_crear on public.client_reviews for insert to authenticated
  with check (private.booking_is_for_my_business(booking_id) and private.booking_completed(booking_id));
grant select on public.review_reports to authenticated;
create policy review_reports_ver on public.review_reports for select to authenticated
  using (reporter_id = (select auth.uid()) or (select private.is_admin()));
grant insert (review_id, client_review_id, reporter_id, reason) on public.review_reports to authenticated;
create policy review_reports_crear on public.review_reports for insert to authenticated
  with check (reporter_id = (select auth.uid()));

-- ============================================================ Favoritos y actividad
grant select, insert, delete on public.favorites to authenticated;
create policy favorites_propios on public.favorites for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, delete on public.favorite_shares to authenticated;
create policy favorite_shares_propios on public.favorite_shares for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant insert (user_id, type, provider_id, query, source) on public.activity_events to anon, authenticated;
create policy activity_events_anonimo on public.activity_events for insert to anon
  with check (user_id is null);
create policy activity_events_crear on public.activity_events for insert to authenticated
  with check (user_id is null or user_id = (select auth.uid()));
grant select on public.activity_events to authenticated;
create policy activity_events_ver on public.activity_events for select to authenticated
  using ((select private.is_admin()));

-- ============================================================ Invitaciones (el invitado entra con get_invitation / rsvp_invitation)
grant select on public.invitations to authenticated;
create policy invitations_ver on public.invitations for select to authenticated
  using (private.owns_event(event_id) or (select private.is_admin()));
grant insert (event_id, public_token, template_id, design, place, lat, lng, status, max_companions) on public.invitations to authenticated;
create policy invitations_crear on public.invitations for insert to authenticated
  with check (private.owns_event(event_id));
grant update (template_id, design, place, lat, lng, status, max_companions) on public.invitations to authenticated;
create policy invitations_editar on public.invitations for update to authenticated
  using (private.owns_event(event_id))
  with check (private.owns_event(event_id));
grant delete on public.invitations to authenticated;
create policy invitations_borrar on public.invitations for delete to authenticated
  using (private.owns_event(event_id));
grant select on public.guests to authenticated;
create policy guests_ver on public.guests for select to authenticated
  using (private.owns_invitation(invitation_id) or (select private.is_admin()));
grant insert (invitation_id, name, phone, email, token, private_notes) on public.guests to authenticated;
create policy guests_crear on public.guests for insert to authenticated
  with check (private.owns_invitation(invitation_id));
grant update (name, phone, email, private_notes) on public.guests to authenticated;
create policy guests_editar on public.guests for update to authenticated
  using (private.owns_invitation(invitation_id))
  with check (private.owns_invitation(invitation_id));
grant delete on public.guests to authenticated;
create policy guests_borrar on public.guests for delete to authenticated
  using (private.owns_invitation(invitation_id));
grant select on public.invitation_sends to authenticated;
create policy invitation_sends_ver on public.invitation_sends for select to authenticated
  using (private.owns_guest(guest_id) or (select private.is_admin()));
grant insert (guest_id, channel) on public.invitation_sends to authenticated;
create policy invitation_sends_crear on public.invitation_sends for insert to authenticated
  with check (private.owns_guest(guest_id));

-- ============================================================ Notificaciones
grant select on public.notifications to authenticated;
create policy notifications_ver on public.notifications for select to authenticated
  using (user_id = (select auth.uid()));
grant update (read_at) on public.notifications to authenticated;
create policy notifications_editar on public.notifications for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.notification_preferences to authenticated;
create policy notification_preferences_propias on public.notification_preferences for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.push_subscriptions to authenticated;
create policy push_subscriptions_propias on public.push_subscriptions for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- ============================================================ Integraciones del proveedor (llaves y secretos los crea el servidor)
grant select (id, provider_id, scopes, revoked_at, created_at) on public.api_keys to authenticated;
create policy api_keys_ver on public.api_keys for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select (id, provider_id, url, events, created_at, updated_at) on public.webhooks to authenticated;
create policy webhooks_ver on public.webhooks for select to authenticated
  using (private.owns_provider(provider_id) or (select private.is_admin()));
grant select on public.webhook_deliveries to authenticated;
create policy webhook_deliveries_ver on public.webhook_deliveries for select to authenticated
  using (exists (select 1 from public.webhooks w where w.id = webhook_id));
-- Sin acceso desde la app: gateway_events y notification_deliveries (solo el servidor).

-- ============================================================ Funciones que la app puede llamar
-- Datos del cliente para el proveedor: teléfono y correo solo con el anticipo pagado.
create function public.booking_client(p_booking uuid)
returns table (full_name text, last_name text, phone text, email text)
language sql stable security definer set search_path = '' as $$
  select pr.full_name, pr.last_name,
    case when b.status in ('anticipo_pagado', 'pagada', 'completada') then pr.phone end,
    case when b.status in ('anticipo_pagado', 'pagada', 'completada') then u.email::text end
  from public.bookings b
  join public.profiles pr on pr.id = b.user_id
  left join auth.users u on u.id = b.user_id
  where b.id = p_booking
    and (private.booking_is_for_my_business(b.id) or private.is_admin())
$$;

create function public.provider_booking_commissions(p_provider uuid)
returns table (booking_id uuid, commission_rate numeric, commission_amount numeric)
language sql stable security definer set search_path = '' as $$
  select b.id, b.commission_rate, b.commission_amount from public.bookings b
  where b.provider_id = p_provider and (private.owns_provider(p_provider) or private.is_admin())
$$;

create function public.my_provider_internal(p_provider uuid)
returns table (cancel_rate numeric, closing_rate numeric, payment_account_id text)
language sql stable security definer set search_path = '' as $$
  select p.cancel_rate, p.closing_rate, p.payment_account_id from public.providers p
  where p.id = p_provider and (private.owns_provider(p_provider) or private.is_admin())
$$;

-- Reseñas publicadas de un proveedor, sin exponer las reservas.
create function public.provider_reviews(p_provider uuid)
returns table (id uuid, rating int, punctuality int, quality int, service int, value int,
  comment text, photos text[], reply text, replied_at timestamptz, published_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.id, r.rating, r.punctuality, r.quality, r.service, r.value, r.comment, r.photos,
    r.reply, r.replied_at, r.published_at
  from public.reviews r join public.bookings b on b.id = r.booking_id
  where b.provider_id = p_provider and r.published_at is not null
  order by r.published_at desc
$$;

-- Lo único que el cliente ve de sus calificaciones.
create function public.my_client_rating() returns numeric
language sql stable security definer set search_path = '' as $$
  select round(avg(c.rating), 2) from public.client_reviews c
  join public.bookings b on b.id = c.booking_id
  where b.user_id = (select auth.uid()) and c.published_at is not null
$$;

create function public.admin_read_conversation(p_conversation uuid)
returns setof public.messages
language plpgsql security definer set search_path = '' as $$
begin
  if not private.is_admin() then
    raise exception 'Solo administración' using errcode = '42501';
  end if;
  if not exists (
    select 1 from public.conversations c
    join public.bookings b on b.user_id = c.user_id and b.provider_id = c.provider_id
    join public.disputes d on d.booking_id = b.id
    where c.id = p_conversation
  ) then
    raise exception 'No hay una disputa entre estas partes' using errcode = '42501';
  end if;
  insert into public.audit_logs (actor_id, action, entity, entity_id)
  values (auth.uid(), 'leer_chat', 'conversations', p_conversation);
  return query select * from public.messages m
    where m.conversation_id = p_conversation order by m.created_at;
end $$;

-- Invitado sin cuenta: solo ve la invitación publicada y su propio renglón.
create function public.get_invitation(p_token text)
returns table (guest_name text, rsvp text, companions int, max_companions int,
  event_name text, event_date date, place text, lat double precision, lng double precision, design jsonb)
language sql stable security definer set search_path = '' as $$
  select g.name, g.rsvp, g.companions, i.max_companions, e.name, e.date, i.place, i.lat, i.lng, i.design
  from public.guests g
  join public.invitations i on i.id = g.invitation_id
  join public.events e on e.id = i.event_id
  where g.token = p_token and i.status = 'publicada'
$$;

create function public.rsvp_invitation(p_token text, p_rsvp text, p_companions int default 0,
  p_diet_notes text default null)
returns void
language plpgsql security definer set search_path = '' as $$
begin
  if p_rsvp not in ('confirmado', 'declinado') then
    raise exception 'Respuesta no válida' using errcode = '22023';
  end if;
  update public.guests g
     set rsvp = p_rsvp,
         companions = case when p_rsvp = 'confirmado' then p_companions else 0 end,
         diet_notes = left(p_diet_notes, 500)
    from public.invitations i
   where g.token = p_token and i.id = g.invitation_id and i.status = 'publicada'
     and p_companions between 0 and i.max_companions;
  if not found then
    raise exception 'Invitación no válida o demasiados acompañantes' using errcode = '22023';
  end if;
end $$;

revoke execute on function public.booking_client(uuid), public.provider_booking_commissions(uuid),
  public.my_provider_internal(uuid), public.provider_reviews(uuid), public.my_client_rating(),
  public.admin_read_conversation(uuid), public.get_invitation(text),
  public.rsvp_invitation(text, text, int, text) from public, anon, authenticated;
grant execute on function public.booking_client(uuid), public.provider_booking_commissions(uuid),
  public.my_provider_internal(uuid), public.my_client_rating(),
  public.admin_read_conversation(uuid) to authenticated;
grant execute on function public.provider_reviews(uuid), public.get_invitation(text),
  public.rsvp_invitation(text, text, int, text) to anon, authenticated;
