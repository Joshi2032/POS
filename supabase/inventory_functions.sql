-- ============================================================================
-- ZAPATA POS - Funciones de inventario: incremento atómico + descuento por venta
-- ============================================================================
-- CONTEXTO: se detectaron dos problemas en cómo la app maneja el inventario:
--
--   1. "Lost update": ajustarStock() en la app lee la cantidad actual, calcula
--      la nueva cantidad EN EL CLIENTE, y la manda como valor absoluto. Si dos
--      personas ajustan el mismo insumo casi al mismo tiempo (dos meseros, o
--      un ajuste manual + una venta), el segundo UPDATE sobreescribe por
--      completo el resultado del primero sin combinarlos.
--
--   2. Vender un producto que tiene una receta configurada (recipe_supplies)
--      NUNCA descuenta el insumo de inventory_items. Se puede vender
--      indefinidamente sin que el stock de insumos baje.
--
-- Este script agrega dos funciones de Postgres (RPC) que Flutter invoca vía
-- `_client.rpc('nombre_funcion', params: {...})`. Ejecutarlas en el
-- SQL Editor de Supabase ANTES de que el código Flutter las use (ya está
-- conectado en el repositorio, pero fallará con "function does not exist"
-- hasta que corras esto).
--
-- ⚠️ SUPUESTO IMPORTANTE QUE DEBES VALIDAR ANTES DE CONFIAR EN LOS NÚMEROS:
--    Se asume que `recipe_supplies.quantity` es la cantidad de ese insumo
--    necesaria para preparar `recipes.yield_portions` porciones COMPLETAS
--    (es decir, es una cantidad "por lote", no "por porción individual").
--    Por eso el descuento por cada producto vendido es:
--        (recipe_supplies.quantity / recipes.yield_portions) * cantidad_vendida
--    Si en realidad `recipe_supplies.quantity` ya es "por porción" (no por
--    lote), quita la división entre yield_portions más abajo. Pruébalo con
--    una venta real de una receta que conozcas y compara el descuento.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Incremento/decremento ATÓMICO de stock (reemplaza el UPDATE absoluto)
-- ----------------------------------------------------------------------------
-- delta puede ser positivo (entrada/compra) o negativo (salida/merma/venta).
-- Nunca deja la cantidad por debajo de 0 (usa GREATEST).
-- Devuelve la cantidad final ya aplicada.
create or replace function public.adjust_inventory_stock(
  p_item_id uuid,
  p_delta numeric,
  p_reason text default null
)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nueva_cantidad numeric;
begin
  update public.inventory_items
     set quantity = greatest(quantity + p_delta, 0)
   where id = p_item_id
   returning quantity into v_nueva_cantidad;

  if v_nueva_cantidad is null then
    raise exception 'No existe el insumo con id %', p_item_id;
  end if;

  insert into public.inventory_movements (inventory_item_id, change_qty, reason)
  values (p_item_id, p_delta, coalesce(p_reason, 'Ajuste'));

  return v_nueva_cantidad;
end;
$$;

grant execute on function public.adjust_inventory_stock(uuid, numeric, text)
  to authenticated;

-- ----------------------------------------------------------------------------
-- 2. Descuento de inventario al vender productos (por receta)
-- ----------------------------------------------------------------------------
-- Recibe un arreglo JSON como:
--   [{"product_id": "uuid-del-producto", "quantity": 2}, {...}]
-- Por cada producto CON receta asignada (products.recipe_id no nulo), busca
-- sus insumos en recipe_supplies y descuenta de inventory_items la cantidad
-- proporcional. Los productos SIN receta se ignoran (no hay nada que
-- descontar). Nunca dej a un insumo en negativo (clamp a 0).
--
-- Devuelve un jsonb con la lista de insumos que quedaron en 0 (para que la
-- app pueda avisar "se agotó tal insumo"), para no tener que hacer otra
-- consulta desde Flutter.
create or replace function public.descontar_inventario_por_venta(
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
  v_supply record;
  v_cantidad_a_descontar numeric;
  v_nueva_cantidad numeric;
  v_insumos_agotados jsonb := '[]'::jsonb;
begin
  for v_item in
    select
      (elem->>'product_id')::uuid as product_id,
      (elem->>'quantity')::numeric as quantity
    from jsonb_array_elements(p_items) as elem
  loop
    for v_supply in
      select
        rs.supply_id,
        rs.quantity as receta_cantidad,
        greatest(r.yield_portions, 1) as yield_portions
      from public.products p
      join public.recipes r on r.id = p.recipe_id
      join public.recipe_supplies rs on rs.recipe_id = r.id
      where p.id = v_item.product_id
    loop
      v_cantidad_a_descontar :=
        (v_supply.receta_cantidad / v_supply.yield_portions) * v_item.quantity;

      update public.inventory_items
         set quantity = greatest(quantity - v_cantidad_a_descontar, 0)
       where id = v_supply.supply_id
       returning quantity into v_nueva_cantidad;

      insert into public.inventory_movements (inventory_item_id, change_qty, reason)
      values (v_supply.supply_id, -v_cantidad_a_descontar, 'Venta de producto');

      if v_nueva_cantidad = 0 then
        v_insumos_agotados := v_insumos_agotados || jsonb_build_object(
          'supply_id', v_supply.supply_id
        );
      end if;
    end loop;
  end loop;

  return jsonb_build_object('insumos_agotados', v_insumos_agotados);
end;
$$;

grant execute on function public.descontar_inventario_por_venta(jsonb)
  to authenticated;

-- ============================================================================
-- FIN. Después de correr esto:
--   1. Prueba vender un producto con receta conocida y confirma en
--      inventory_movements que se registró el descuento esperado.
--   2. Si el número no coincide con lo que esperas, ajusta la fórmula de
--      v_cantidad_a_descontar (quita la división entre yield_portions si
--      recipe_supplies.quantity ya es "por porción").
-- ============================================================================
