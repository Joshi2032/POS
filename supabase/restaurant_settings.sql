-- Tabla de ajustes del restaurante: una sola fila compartida entre todas
-- las terminales del POS (a diferencia de una preferencia guardada por
-- dispositivo). Antes de este archivo, la pantalla de Ajustes no escribía
-- nada en ningún lado: el botón "Guardar Cambios" solo animaba un ícono de
-- éxito y todo volvía a los valores por defecto al reiniciar la app.
--
-- Correr este script una sola vez en el SQL Editor de Supabase.

create table if not exists public.restaurant_settings (
  id text primary key default 'default',
  nombre_negocio text not null default '',
  rfc text not null default '',
  direccion text not null default '',
  telefono text not null default '',
  alerta_stock boolean not null default true,
  resumen_diario boolean not null default true,
  nuevas_ordenes boolean not null default true,
  cierre_automatico boolean not null default true,
  pin text not null default '',
  updated_at timestamptz not null default now()
);

-- Garantiza que exista la fila 'default', para que la app siempre pueda
-- hacer un simple select/update sin preocuparse de crearla primero.
insert into public.restaurant_settings (id)
values ('default')
on conflict (id) do nothing;

alter table public.restaurant_settings enable row level security;

drop policy if exists "restaurant_settings_read" on public.restaurant_settings;
create policy "restaurant_settings_read"
  on public.restaurant_settings
  for select
  to authenticated
  using (true);

drop policy if exists "restaurant_settings_update" on public.restaurant_settings;
create policy "restaurant_settings_update"
  on public.restaurant_settings
  for update
  to authenticated
  using (true)
  with check (true);
