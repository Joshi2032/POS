-- ============================================================================
-- ZAPATA POS - Bloqueo de Row Level Security (RLS)
-- ============================================================================
-- CONTEXTO: se detectó que las siguientes tablas son legibles (y en varios
-- casos escribibles/borrables) por CUALQUIER persona en internet usando
-- únicamente la anon key pública (sin iniciar sesión). Esto se confirmó con
-- pruebas de solo lectura y un DELETE contra un id inexistente (que devolvió
-- 204 en vez de 401/403) sobre products, employees, orders y expenses.
--
-- Este script:
--   1. Habilita RLS en las 20 tablas usadas por la app.
--   2. Crea una función helper que determina si el usuario autenticado es
--      Admin o Gerente (basado en employees.position).
--   3. Da acceso operativo (lectura/escritura) SOLO a usuarios autenticados
--      en las tablas del día a día del POS.
--   4. Restringe employees, employee_areas y payroll (nómina) a Admin/Gerente
--      únicamente, porque contienen datos sensibles (salarios, email, etc).
--   5. Da a profiles un manejo especial: cada usuario puede ver/editar su
--      propio perfil; los Admin/Gerente pueden ver todos.
--
-- IMPORTANTE — LEE ANTES DE EJECUTAR:
--   - Este script fue escrito a partir de los nombres de tabla/columna
--     usados en el código Flutter (lib/repositories/*.dart) y de una
--     inspección de solo-lectura vía la anon key pública. NO tengo acceso
--     directo a tu esquema completo (constraints, columnas exactas,
--     triggers), así que revísalo antes de correrlo en producción.
--   - Pruébalo primero en un proyecto de staging/rama si tienes uno.
--   - Después de correr esto, prueba la app a fondo (login, tomar orden,
--     cobrar, nómina, etc.) porque cualquier política mal ajustada puede
--     bloquear una operación legítima en vez de solo bloquear al atacante.
--   - La Edge Function `create-employee-user` usa la service_role key,
--     que IGNORA RLS por diseño, así que el flujo de alta de empleados
--     seguirá funcionando sin cambios.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. FUNCIÓN HELPER: ¿el usuario autenticado es Admin o Gerente?
-- ----------------------------------------------------------------------------
create or replace function public.is_admin_or_manager()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.employees e
    join public.profiles p on p.id = e.profile_id
    where p.user_id = auth.uid()
      and e.position in ('Admin', 'Gerente')
      and e.active = true
  );
$$;

-- ----------------------------------------------------------------------------
-- 2. TABLAS OPERATIVAS: solo usuarios autenticados (cualquier empleado
--    logueado puede usarlas normalmente desde la app).
-- ----------------------------------------------------------------------------
do $$
declare
  t text;
  tablas text[] := array[
    'products', 'categories', 'combos', 'combo_items',
    'orders', 'order_items', 'restaurant_tables',
    'cash_movements', 'cash_register_cuts',
    'inventory_items', 'inventory_movements',
    'expenses', 'supplier_payments', 'reservations',
    'recipes', 'recipe_supplies'
  ];
begin
  foreach t in array tablas loop
    execute format('alter table public.%I enable row level security;', t);

    execute format(
      'drop policy if exists "authenticated_full_access" on public.%I;', t
    );

    execute format(
      'create policy "authenticated_full_access" on public.%I
         for all
         using (auth.uid() is not null)
         with check (auth.uid() is not null);',
      t
    );
  end loop;
end $$;

-- ----------------------------------------------------------------------------
-- 3. TABLAS SENSIBLES: solo Admin/Gerente (nómina y datos de empleados).
-- ----------------------------------------------------------------------------
alter table public.employees enable row level security;
alter table public.employee_areas enable row level security;
alter table public.payroll enable row level security;

drop policy if exists "employees_self_read" on public.employees;
create policy "employees_self_read" on public.employees
  for select
  using (
    public.is_admin_or_manager()
    or exists (
      select 1 from public.profiles p
      where p.id = employees.profile_id and p.user_id = auth.uid()
    )
  );

drop policy if exists "employees_admin_write" on public.employees;
create policy "employees_admin_write" on public.employees
  for insert with check (public.is_admin_or_manager());

drop policy if exists "employees_admin_update" on public.employees;
create policy "employees_admin_update" on public.employees
  for update
  using (public.is_admin_or_manager())
  with check (public.is_admin_or_manager());

drop policy if exists "employees_admin_delete" on public.employees;
create policy "employees_admin_delete" on public.employees
  for delete using (public.is_admin_or_manager());

drop policy if exists "employee_areas_admin_all" on public.employee_areas;
drop policy if exists "employee_areas_read" on public.employee_areas;
create policy "employee_areas_read" on public.employee_areas
  for select using (auth.uid() is not null);
drop policy if exists "employee_areas_admin_write" on public.employee_areas;
create policy "employee_areas_admin_write" on public.employee_areas
  for insert with check (public.is_admin_or_manager());
drop policy if exists "employee_areas_admin_update" on public.employee_areas;
create policy "employee_areas_admin_update" on public.employee_areas
  for update using (public.is_admin_or_manager()) with check (public.is_admin_or_manager());
drop policy if exists "employee_areas_admin_delete" on public.employee_areas;
create policy "employee_areas_admin_delete" on public.employee_areas
  for delete using (public.is_admin_or_manager());

drop policy if exists "payroll_admin_only" on public.payroll;
create policy "payroll_admin_only" on public.payroll
  for all
  using (public.is_admin_or_manager())
  with check (public.is_admin_or_manager());

-- ----------------------------------------------------------------------------
-- 4. PROFILES: cada usuario ve/edita el suyo; Admin/Gerente ven todos.
-- ----------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "profiles_select" on public.profiles;
create policy "profiles_select" on public.profiles
  for select
  using (user_id = auth.uid() or public.is_admin_or_manager());

drop policy if exists "profiles_update_self" on public.profiles;
create policy "profiles_update_self" on public.profiles
  for update
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Los INSERT de profiles normalmente los hace el trigger de alta de usuario
-- o la Edge Function con service_role (que ignora RLS). Si tu app necesita
-- que un usuario recién registrado cree su propio profile desde el cliente,
-- descomenta esto:
-- create policy "profiles_insert_self" on public.profiles
--   for insert with check (user_id = auth.uid());

-- ============================================================================
-- FIN. Después de correr esto, vuelve a probar (sin login) que ya NO se
-- pueda leer nada, por ejemplo:
--   curl "https://<tu-proyecto>.supabase.co/rest/v1/employees?select=*" \
--        -H "apikey: <tu-anon-key>" -H "Authorization: Bearer <tu-anon-key>"
-- Debería devolver [] (RLS bloquea, no hay sesión) en vez de datos reales.
-- ============================================================================
