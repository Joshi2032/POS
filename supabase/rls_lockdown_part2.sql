-- ============================================================================
-- ZAPATA POS - Bloqueo de RLS, parte 2 (limpieza de políticas viejas +
-- tablas que faltaron)
-- ============================================================================
-- Con el resultado de pg_policies que me compartiste, encontré que quedaron
-- políticas ANTERIORES a mi primer script, activas al mismo tiempo que las
-- nuevas. Postgres combina políticas permisivas con OR, así que una política
-- vieja "abierta" sigue ganando aunque exista una nueva más estricta.
--
-- Este script:
--   1. Elimina las políticas viejas demasiado permisivas en products,
--      employees, employee_areas y profiles.
--   2. Habilita RLS y agrega políticas básicas en las 7 tablas que quedaron
--      sin RLS: discounts, payroll_items, payroll_runs, purchase_items,
--      purchases, suppliers, user_roles.
--
-- IMPORTANTE:
--   - Antes de correr, confirma que ya ejecutaste supabase/rls_lockdown.sql
--     (la función is_admin_or_manager() debe existir).
--   - user_roles la dejo SOLO para Admin/Gerente (lectura y escritura) como
--     medida de precaución, porque no conozco su estructura ni cómo la usa
--     tu app todavía. Si en el futuro necesitas que cada usuario lea su
--     propio rol, dímelo y ajustamos la política con las columnas reales.
--   - Prueba la app completo después de correr esto (login, ver productos,
--     ver lista de empleados como un Mesero normal — ya NO debería ver
--     salarios de otros, editar mesas, etc).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Limpieza de políticas viejas demasiado permisivas
-- ----------------------------------------------------------------------------

-- products: esta es la política que dejaba leer el catálogo sin login.
drop policy if exists "Permitir lectura pública" on public.products;

-- Si SÍ quieres que el catálogo de productos activos sea público (p. ej.
-- para un menú digital sin necesidad de iniciar sesión), en vez de lo de
-- arriba usa esto (comentado por defecto):
-- create policy "public_read_active_products" on public.products
--   for select
--   using (active = true);

-- employees: cualquier autenticado podía leer TODOS los empleados (salarios
-- incluidos). Ya existe employees_self_read (propio registro o admin).
drop policy if exists "Allow authenticated read employees" on public.employees;

-- employee_areas: cualquier autenticado podía insertar/editar/borrar áreas
-- de cualquier empleado. Ya existen las políticas *_admin_* para eso.
drop policy if exists "Allow authenticated read employee areas" on public.employee_areas;
drop policy if exists "Allow authenticated insert employee areas" on public.employee_areas;
drop policy if exists "Allow authenticated update employee areas" on public.employee_areas;
drop policy if exists "Allow authenticated delete employee areas" on public.employee_areas;

-- profiles: cualquier autenticado podía leer todos los perfiles. Ya existe
-- profiles_select (propio perfil o admin).
drop policy if exists "Allow authenticated read profiles" on public.profiles;

-- ----------------------------------------------------------------------------
-- 2. Tablas que faltaron: habilitar RLS + acceso básico para autenticados
-- ----------------------------------------------------------------------------
do $$
declare
  t text;
  tablas text[] := array[
    'discounts', 'purchases', 'purchase_items', 'suppliers'
  ];
begin
  foreach t in array tablas loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists "authenticated_full_access" on public.%I;', t);
    execute format(
      'create policy "authenticated_full_access" on public.%I
         for all
         using (auth.uid() is not null)
         with check (auth.uid() is not null);',
      t
    );
  end loop;
end $$;

-- payroll_items / payroll_runs: mismo criterio que payroll (solo Admin/Gerente).
alter table public.payroll_items enable row level security;
alter table public.payroll_runs enable row level security;

drop policy if exists "payroll_items_admin_only" on public.payroll_items;
create policy "payroll_items_admin_only" on public.payroll_items
  for all
  using (public.is_admin_or_manager())
  with check (public.is_admin_or_manager());

drop policy if exists "payroll_runs_admin_only" on public.payroll_runs;
create policy "payroll_runs_admin_only" on public.payroll_runs
  for all
  using (public.is_admin_or_manager())
  with check (public.is_admin_or_manager());

-- user_roles: por precaución, solo Admin/Gerente hasta que definamos cómo
-- la usa la app (ver nota arriba).
alter table public.user_roles enable row level security;

drop policy if exists "user_roles_admin_only" on public.user_roles;
create policy "user_roles_admin_only" on public.user_roles
  for all
  using (public.is_admin_or_manager())
  with check (public.is_admin_or_manager());

-- ============================================================================
-- FIN. Verificación sugerida después de correr esto:
--
-- 1. Sin login (anon key), esto debe devolver [] :
--    curl "https://<tu-proyecto>.supabase.co/rest/v1/products?select=*" \
--         -H "apikey: <tu-anon-key>" -H "Authorization: Bearer <tu-anon-key>"
--
-- 2. Vuelve a correr la consulta de pg_policies de schema_dump.sql y
--    confirma que ya NO aparezcan las políticas "Allow authenticated..." ni
--    "Permitir lectura pública" que borramos arriba.
-- ============================================================================
