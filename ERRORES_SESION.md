# Errores encontrados y corregidos — ZAPATA POS

Registro completo de todos los bugs encontrados durante esta sesión de revisión, en orden cronológico. Incluye los ya corregidos y los que se están corrigiendo en este momento (marcados como **[EN PROGRESO]**).

---

## Ronda 1 — Dinero/inventario, seguridad RLS, impresión, responsividad

**Bugs de integridad de dinero e inventario:**
- Race condition que permitía doble cobro en `registrarCobro` (corregido con compare-and-swap por status)
- Se usaba el total obsoleto del cliente en vez del total real del servidor al cobrar
- Fallos al registrar el movimiento de caja se ocultaban en silencio (ahora se avisa al cajero)
- Órdenes huérfanas: si fallaba el insert de items, la orden ya creada quedaba fantasma (ahora se elimina)
- `obtenerTotalEnCaja` ocultaba errores reales detrás de un falso $0.00
- No se bloqueaba stock negativo en `ajustarStock`
- `agregarItemsAOrden` no reintentaba el recálculo de total si fallaba la primera vez
- Doble envío de órdenes; doble-submit en gastos/proveedores/combos/mesas/empleados/categorías
- Faltaba confirmación antes de cancelar órdenes y eliminar recetas/productos
- El nombre de empleado no se guardaba en pagos de nómina (faltaba `employee_id` + join)
- No se validaba precio/stock numérico antes de guardar productos/inventario

**Seguridad de base de datos (Supabase RLS):**
- Acceso público sin login a todas las tablas (leíble/escribible por cualquiera con la anon key)
- Políticas viejas dejaban leer/escribir de más a usuarios autenticados sin rol de Admin/Gerente
- 7 tablas sin RLS habilitado (discounts, payroll_items, payroll_runs, purchase_items, purchases, suppliers, user_roles)

**Impresión térmica:**
- Crash potencial con montos negativos/NaN en el monto en letras
- Faltaban timeouts a connect/send/disconnect (podía colgar la app si la impresora estaba apagada)
- Un timeout en `connect()` podía dejar el puerto USB sin liberar
- `imprimirTicketRapido` — código muerto, nunca se usaba (eliminado)
- Faltaba permiso USB host en AndroidManifest

**Responsividad:**
- Diálogos con ancho fijo se desbordaban en celulares (login, caja, tomar orden, empleados)
- Overflow en lista de productos, reportes y recetas con textos largos

**Otros:**
- Pantalla de error controlada si fallaban las credenciales de Supabase en el arranque
- Pull-to-refresh agregado en Caja, Órdenes y Reservaciones
- `database.types.dart` eliminado (no era Dart válido, quedó desactualizado)

---

## Ronda 2 — Pendientes de caja/inventario, impresión, UI

- Auto-logout no reaccionaba a cambios de sesión en vivo (ahora GoRouter usa `refreshListenable` con el stream de auth de Supabase)
- Faltaba botón de reimprimir ticket en órdenes ya pagadas
- Faltaba el flujo completo de UI para "Cerrar Corte de Caja"
- Vender un producto con receta nunca descontaba el insumo de inventario (agregadas funciones de Postgres para descuento por receta y ajuste atómico de stock)
- Ticket físico: nombres largos de MESA/MESERO podían pasarse del ancho del papel y romper el ticket
- Ticket físico: nombres de producto largos se truncaban con "..." en vez de imprimirse completos
- Productos y combos desactivados se podían seguir agregando a una orden nueva
- Cambiar el tipo de orden reasignaba la mesa en silencio si se tocaba el mismo tipo dos veces con el carrito lleno
- `PaymentsProvider` no usaba la misma zona horaria de México que `caja_repository` para sus KPIs
- Faltaba confirmación antes de eliminar en inventario, pagos a proveedores y reservaciones
- Faltaban banners de error de carga en caja, órdenes, reservaciones, inventario, proveedores y recetas
- Faltaba spinner de guardando en el diálogo de inventario
- Colores fijos en `mesas_page` rompían el modo claro (reemplazados por colores de Theme)
- Tooltips faltantes en varios `IconButton`
- `dashboard_provider` y `caja_provider` corrían consultas secuenciales en vez de en paralelo

---

## Ronda 3 — Movimientos de caja, más bugs, animaciones

- `MovimientoCajaProvider` estaba inerte (nunca se instanciaba en ninguna pantalla) — se conectó a una vista real
- `combo_repository`/`recipe_repository`: `update()`/`create()` podían dejar el combo o receta sin productos/insumos si el insert fallaba a medias
- Edge Function `create-employee-user`: el rollback no borraba la fila de `profiles` que él mismo había creado
- `productos_page.dart`: el botón "Actualizar categorías" cerraba el diálogo y nunca lo reabría (el `mounted` se comprobaba sobre un contexto que el mismo código acababa de popear)
- `mesas_provider.cambiarEstadoMesa` reconstruía la mesa completa desde caché local, pudiendo perder cambios de otro admin (ahora hace update parcial de solo el estado)
- Zona horaria de México faltante en `reservaciones_provider.dart`
- Modales de detalle (órdenes, gastos, reservaciones) aparecían de golpe (agregadas transiciones de entrada)
- Icono de expandir/colapsar en caja_page cambiaba de golpe en vez de rotar
- Chips de filtro en `mesas_page` cambiaban de color de golpe

---

## Ronda 4 — Porcentajes falsos y categorización del dashboard

- Las tarjetas de Ventas Hoy/Ingreso/Utilidad mostraban porcentajes de cambio **fijos en el código** (+12.5%, +8.2%, +15.3%), sin relación con datos reales
- Zona horaria de México faltante en el cálculo de "Ventas Hoy"
- La tabla de "Rendimiento de Productos" adivinaba la categoría por palabras clave en vez de usar la categoría real del catálogo

## Ronda 5 — Unificación de categorización Dashboard/Reportes

- `reportes_provider.dart` usaba una lista fija de categorías (`'Alimentos'/'Bebidas'/'Combos'/'Otros'`) que no correspondía a las categorías reales del negocio
- La categoría "dominante" de una orden se adivinaba por palabras clave en el nombre concatenado de todos los productos, en vez de usar la categoría real del producto de mayor importe
- El filtro de categoría no se reseteaba si la categoría seleccionada dejaba de existir tras recargar

---

## Ronda 6 — Fix profundo de zona horaria + consolidación

- **Bug de fondo grave**: todo el dashboard comparaba directamente el `created_at` (UTC) contra "hoy" del dispositivo — una venta de la tarde/noche en México cae en UTC del día siguiente, así que se contaba en el día/semana/mes equivocado. Corregido con lógica de "día-calendario de México" (`_diaMexico`/`_hoyEnMexico`), verificado con un script de prueba standalone
- Se creó `lib/utils/mexico_time.dart` para centralizar el offset UTC-6 de México, antes duplicado por separado en `caja_repository.dart`, `provider_payment.dart`, `reservaciones_provider.dart`, `dashboard_provider.dart` y `caja_page.dart`
- Se quitó el flujo de estados de cocina (pendiente→preparando→lista→entregada): toda orden creada queda disponible para cobrar de inmediato; se conserva pagada/cancelada
- "Ver Movimientos de Caja" se convirtió en página independiente (`/movimientos-caja`) con entrada en el sidebar, en vez de diálogo dentro de Caja
- El nombre del proveedor nunca se guardaba en los pagos (la tabla `supplier_payments` solo tiene `supplier_id`, sin columna de texto) — se construyó un selector real de proveedores (autocompletar + creación al vuelo)
- Sobrescritura de stock obsoleto al editar un insumo — corregido con ajuste atómico (delta) en vez de sobrescribir con el valor que traía el formulario al abrirse
- `setAreasForEmployee` no restauraba las áreas anteriores si la inserción de las nuevas fallaba después de borrar las viejas
- Condición de carrera en `chargeSelectedOrder` (podía cerrar el panel de una orden distinta a la recién cobrada)
- `BaseProvider.dispose()` no evitaba `notifyListeners()` tras haberse desechado
- Campos muertos `oldPrice`/`ahorro`/`tags` en `ComboItem` (nunca se guardaban ni se mostraban en ningún lado) — eliminados
- Patrón de limpieza de campos UUID vacíos duplicado en 11 repositorios — consolidado en `lib/utils/json_payload_utils.dart`, y corregido para preservar `null`/`''` en columnas de texto (antes borraba silenciosamente cualquier campo opcional vaciado, como notas o descripción)
- Fugas de `TextEditingController` sin `dispose()` en proveedores/inventario/categorías/productos/recetas
- Condición de carrera por doble-edición rápida en `empleados_page`; faltaban guardas `mounted` en el diálogo de inventario
- Parseo de embeds PostgREST (Map-o-Lista) duplicado en 4 archivos — consolidado en `lib/utils/embed_utils.dart`
- Fallback de categoría por palabras clave duplicado en 2 archivos — consolidado en `lib/utils/categoria_utils.dart`
- `NumberFormat.currency` duplicado en 3 páginas en vez de reusar `Formatters.money` ya existente

---

## Ronda 7 — 5 bugs adicionales

- `tomar_orden_provider.sendOrder()` no limpiaba la orden existente seleccionada; como ese provider vive a nivel de app, la próxima vez que se abría "Tomar Orden" podía seguir apuntando a la orden ya enviada
- Editar Mesa y Editar Producto podían revertir un cambio de estado concurrente (mesa ocupada por otro mesero, producto desactivado por otro admin) porque el formulario reenviaba el estado viejo que traía al abrirse
- El buscador de proveedores no escapaba `_`/`%` en `ilike`, pudiendo emparejar el proveedor equivocado o crashear con `maybeSingle()` si había 2+ coincidencias
- El campo Salario en Empleados no validaba nada — escribir "12,000" con coma se guardaba como `null` sin aviso

---

## Ronda 8 — Animaciones del dashboard (varias iteraciones)

- Animación de flujo (dibujado progresivo), pulso continuo en el último punto de cada línea, y franja de brillo continua agregadas a las gráficas
- **Bug real encontrado por el usuario**: la franja de brillo no se animaba — `Positioned` estaba envuelto dentro de `IgnorePointer` (un `RenderObjectWidget`) *antes* de llegar al `Stack`, rompiendo el mecanismo de `ParentDataWidget` de Flutter y lanzando "Incorrect use of ParentDataWidget". Corregido y verificado con un test aislado
- Cambiar de filtro (semana/mes/año) forzaba destruir y recrear la gráfica completa (crossfade entre dos imágenes estáticas, los datos nunca "fluían"). Corregido: el mismo widget persiste entre cambios de filtro con `duration`/`curve` explícitos, así fl_chart interpola cada punto/barra del valor viejo al nuevo

---

## Ronda 9 — Auditoría exhaustiva (48 hallazgos)

Búsqueda con 5 agentes en paralelo cubriendo páginas restantes, servicios/auth/SQL, seguridad de tipos en modelos, condiciones de carrera, y lógica de negocio/dinero. Reporte completo publicado como artifact. Estado de cada uno marcado abajo.

### Críticos (5) — ✅ Todos corregidos

1. ✅ **Editar un combo borraba sus productos vinculados** — `combos_page.dart` no precargaba los productos ya vinculados al abrir "Editar"; al guardar, `combo_repository.update()` borraba los `combo_items` existentes y no reinsertaba ninguno. *Corregido: `ComboItem` ahora trae `productIds` desde el embed, y el formulario los precarga.*
2. ✅ **Ajustes nunca se guardaba** — `ajustes_provider.dart` solo animaba un ícono de éxito con `Future.delayed`; no existía ningún repositorio ni escritura real. *Corregido: nueva tabla `restaurant_settings` (ver `supabase/restaurant_settings.sql`, falta correrlo en Supabase), `SettingsRepository`, y `AjustesProvider` reescrito para cargar/guardar de verdad.*
3. ✅ **Vender un combo nunca descontaba inventario** — los combos usan `combos.id` como `product_id`, que no existe en la tabla `products`; el JOIN de `descontar_inventario_por_venta` no encontraba nada. *Corregido: `orden_repository.dart` ahora expande cada combo a sus productos reales (vía `combo_items`) antes de llamar al RPC.*
4. ✅ **`obtenerPagosProveedoresHoy()` sumaba pagos a proveedores de CUALQUIER método** (efectivo, tarjeta, transferencia) y los restaba completos del efectivo esperado en el corte de caja. *Corregido: ahora filtra solo `method = 'cash'`.*
5. ✅ **El cierre de turno nunca incluía los movimientos manuales de caja** (Movimientos de Caja). *Corregido: nuevo `obtenerNetoMovimientosManualesHoy()`, con cuidado de no contar dos veces las filas auto-generadas por cada cobro de orden.*

### Altos (16) — **[EN PROGRESO]**

6. Reportes: `paymentMethod` se fijaba como `'Efectivo'` para TODAS las ventas, sin leer el método real de la orden
7. Reportes: filtros Hoy/Esta Semana/Este Mes comparaban el string UTC crudo contra la fecha local del dispositivo, sin usar `mexico_time.dart`
8. Reportes: cada orden se atribuía por completo a la "categoría dominante" (producto de mayor importe), distorsionando ingresos por categoría en órdenes mixtas
9. Dashboard: `_calcularTotalesPeriodoAnterior` comparaba el período actual PARCIAL contra el período anterior COMPLETO, mostrando caídas de ventas ficticias
10. Gastos: el chip decía `'Todos'` pero el provider filtraba contra `'Todas'` — nunca coincidían, dejando la lista vacía al tocar "mostrar todos"
11. Mesas: nombre de mesa con `color: Colors.white` fijo sobre tarjeta blanca en modo claro — ilegible
12. Mesas: el bloqueo para eliminar solo revisaba `estado == 'ocupada'`, no `'por cobrar'` (cuenta pendiente de pago)
13. `tomar_orden_provider.cargarAreasDelUsuario()` se saltaba la recarga para siempre tras la primera carga por sesión — cambios de área/puesto de un admin no se reflejaban hasta cerrar sesión
14. `sidebar.dart` mostraba todos los ítems del menú a cualquier usuario autenticado, sin filtrar por rol/puesto
15. `inventory_functions.sql`: el registro de movimientos de inventario guardaba el delta SOLICITADO, no el aplicado tras el recorte a 0 — la bitácora de auditoría queda descuadrada
16-21. 6 diálogos de guardar sin `barrierDismissible: false` (empleados, combos, categorías, mesas, productos, proveedores) — tocar fuera durante un guardado en curso descarta el resultado en silencio

### Medios (23) — **[EN PROGRESO]**

- `printer_service.dart`: redondeo de centavos puede dar exactamente 100 por imprecisión de punto flotante
- `historial_cortes_page.dart`: `cutAt` no pasa por `mexico_time.dart`
- `gastos_provider.dart`: `totalGastosLength` está definido igual al total YA filtrado
- `theme_provider.dart`: modo oscuro fijo en `true`, sin persistencia (no existe `shared_preferences` en el proyecto)
- `routes.dart`: no hay redirect para la ruta raíz `"/"` estando logueado; no hay `errorBuilder`
- `login_page.dart`: la contraseña se recorta con `.trim()` antes de enviarla
- `printer_service.dart`: la fecha/hora del ticket usa `DateTime.now()` del dispositivo, no la hora de México centralizada
- `tomar_orden_provider` (singleton de app): el carrito no se limpia al cerrar sesión — riesgo en terminal compartida
- `rls_lockdown.sql`: el bloque de `employee_areas` no tiene `drop policy if exists` por cada política nueva
- `create-employee-user`: los 4 pasos de rollback no tienen try/catch individual; verificación de correo duplicado sin bloqueo (condición de carrera)
- 5 confirmaciones de eliminar sin revisar `mounted` tras un `await` (productos, recetas, inventario, proveedores, reservaciones)
- 2 casos en `tomar_orden_page.dart` con el mismo patrón (mensajes de error tras enviar orden / cambiar estado de mesa)
- 4 modelos con casts sin protección o sin usar `asEmbedMap()`: `product.dart`, `nomina_pago.dart`, `corte_caja.dart`, `provider_payment.dart`

### Bajos / informativos (4) — **[EN PROGRESO]**

- `printer_service.dart`: `_numeroALetras` no convierte montos ≥ $1,000,000 a palabras
- `mesa.dart`: `capacidad` cae silenciosamente a 4 si el valor llega como decimal (ej. "4.0")
- `product_item.dart` y `cart_item.dart`: casts sin protección, pero código muerto — no se usan en ningún lugar actual

---

## Nota sobre scripts SQL pendientes de correr manualmente

Estos archivos deben ejecutarse en el SQL Editor de Supabase para que las funciones correspondientes existan en producción:

- `supabase/inventory_functions.sql` — ajuste atómico de stock y descuento de inventario por receta
- `supabase/rls_lockdown.sql` — políticas de seguridad RLS
- `supabase/restaurant_settings.sql` — **nuevo**, tabla para que Ajustes persista de verdad

Sin correr `restaurant_settings.sql`, el fix de Ajustes de esta ronda cargará valores en blanco y el guardado no tendrá ninguna fila que actualizar.
