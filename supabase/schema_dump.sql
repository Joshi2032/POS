-- ============================================================================
-- Volcado de esquema: tablas y columnas del schema "public"
-- ============================================================================
-- Corre esto en el SQL Editor de Supabase y pégame el resultado completo.
-- Lo necesito para comparar el esquema REAL de tu base de datos contra lo
-- que el código Flutter espera (nombres de tabla, columnas, y detectar
-- tablas/columnas que ya no se usan o que el código espera pero no existen).

select
  c.table_name,
  c.column_name,
  c.data_type,
  c.is_nullable,
  c.column_default
from information_schema.columns c
where c.table_schema = 'public'
order by c.table_name, c.ordinal_position;

-- ============================================================================
-- Además, corre esto por separado para ver las políticas RLS activas en
-- TODAS las tablas (para confirmar que products y las demás ya quedaron
-- bien bloqueadas, y no solo por el diagnóstico anterior de una tabla):
-- ============================================================================

select
  schemaname,
  tablename,
  policyname,
  cmd as command,
  qual as using_expression,
  with_check
from pg_policies
where schemaname = 'public'
order by tablename, policyname;

-- ============================================================================
-- Y esto para confirmar que RLS esté HABILITADO (no solo con políticas) en
-- cada tabla — si rowsecurity = false, la tabla es pública sin importar
-- las políticas que existan:
-- ============================================================================

select
  relname as table_name,
  relrowsecurity as rls_enabled
from pg_class
where relnamespace = 'public'::regnamespace
  and relkind = 'r'
order by relname;
