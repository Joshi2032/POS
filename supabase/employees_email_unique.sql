-- Restricción única en employees.email: sin esto, la Edge Function
-- create-employee-user solo hace un SELECT-luego-INSERT para checar
-- correos duplicados, que no bloquea nada — dos altas casi simultáneas con
-- el mismo correo (doble clic, dos admins) pueden pasar ambas el chequeo
-- antes de que cualquiera inserte. Esta restricción a nivel de base de
-- datos es la que realmente evita el duplicado; el código en index.ts ya
-- está preparado para traducir el error 23505 resultante a un mensaje
-- claro en vez de dejarlo como el genérico de rollback.
--
-- Nota: si ya existen empleados con correos duplicados en la tabla, este
-- script fallará al crear la restricción. Revisa primero con:
--   select email, count(*) from public.employees group by email having count(*) > 1;
--
-- Postgres no soporta "ADD CONSTRAINT IF NOT EXISTS", así que se checa
-- manualmente antes de intentar crearla (para poder volver a correr este
-- script sin que truene con "relation already exists" si ya se había
-- aplicado antes).
do $$
begin
  if not exists (
    select 1 from information_schema.table_constraints
    where constraint_name = 'employees_email_unique'
      and table_name = 'employees'
      and table_schema = 'public'
  ) then
    alter table public.employees
      add constraint employees_email_unique unique (email);
  end if;
end $$;
