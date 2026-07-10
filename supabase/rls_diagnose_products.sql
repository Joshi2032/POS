-- ============================================================================
-- Diagnóstico: ¿qué política sigue dejando leer `products` sin login?
-- ============================================================================
-- Corre esto primero en el SQL Editor de Supabase y revisa el resultado.
-- Verás una o más filas. La que tenga "qual" = "true" (o similar, sin
-- referencia a auth.uid()) y "roles" incluyendo "anon" o "public" es la
-- que está dejando pasar la lectura anónima.

select
  polname            as policy_name,
  polcmd             as command,
  pg_get_expr(polqual, polrelid)      as using_expression,
  pg_get_expr(polwithcheck, polrelid) as with_check_expression,
  (select array_agg(rolname) from pg_roles where oid = any(polroles)) as roles
from pg_policy
where polrelid = 'public.products'::regclass;

-- ============================================================================
-- Una vez que identifiques el nombre de la política vieja (columna
-- policy_name de arriba), bórrala así (reemplaza NOMBRE_VIEJO):
--
--   drop policy "NOMBRE_VIEJO" on public.products;
--
-- Si por alguna razón SÍ quieres que el catálogo de productos activos sea
-- público (por ejemplo, para un menú digital sin login), en vez de borrarla
-- por completo, edítala para que solo exponga columnas/filas seguras, por
-- ejemplo solo productos activos:
--
--   drop policy "NOMBRE_VIEJO" on public.products;
--   create policy "public_read_active_products" on public.products
--     for select
--     using (active = true);
--
-- (Esa alternativa es razonable para products porque no tiene datos
-- sensibles, pero NO la repliques en employees, payroll ni profiles).
-- ============================================================================
