---
name: code_error_cleanup_unification
description: Aplica el sistema estándar de control de errores (catálogo RW + middlewares de trazabilidad), limpieza de código muerto y unificación de servicios/funciones sobre una ruta específica de routes/api/. Usar SIEMPRE que se pida "aplicar el sistema de control de errores, limpieza de código muerto y unificación de servicios" sobre cualquier módulo del backend. Mismo procedimiento en Claude Code, Codex CLI y Gemini CLI — no improvisar criterio propio.
---

# code_error_cleanup_unification

## Cuándo se invoca
Cuando el usuario pide, en cualquier CLI, algo equivalente a:
> "Aplicá el sistema de control de errores, limpieza de código muerto y unificación de servicios y funciones solo en la ruta @routes/api/..."

## Alcance (obligatorio)
- Operar **únicamente** dentro de la ruta indicada en el mismo mensaje. No tocar archivos fuera de esa carpeta.
- Si la ruta no existe o está vacía, detenerse y avisar.

## Paso 0 — Pre-flight: chequear trabajo paralelo
Antes de tocar nada:
1. `git pull` limpio sobre el branch actual.
2. Revisar si hay commits recientes de otras sesiones/agentes tocando módulos hermanos dentro de `api-rendicion/` (mismo tipo de migración en otra carpeta). Si los hay, **no asumir que no afecta** — puede haber funciones de cliente compartido, numeración de migraciones SQL, o catálogos ya creados por esa sesión que hay que reusar en vez de duplicar.
3. Si existe un cliente de servicio compartido (ej. Gasto Electoral client) revisar qué funciones ya agregaron otras sesiones antes de crear una nueva.

## Paso 1 — Control de errores
Patrón fijo (no improvisar otro):
1. **Catálogo RW**: si el módulo no tiene su propio bloque de códigos en el catálogo `RW` (ej. `#RW2000`–`#RW2007`, uno por área temática), crearlo en `db/schema/NN_seed_catalogo_RW_<modulo>.sql`, siguiendo la numeración secuencial siguiente al último archivo existente (chequear el paso 0 — otra sesión pudo haber tomado el número siguiente).
2. **Wrapper de ruta obligatorio**: todo módulo debe pasar por su `route-*.js` correspondiente, wireado con `traceIdMiddleware` y `createErrorMiddleware`. Si se detecta que `routes/api.js` o `routes/api-servel.js` (u otro mount point) importa la clase de servicio **directamente**, saltándose el wrapper — eso es un gap, no una decisión de diseño. Corregirlo: wirear el wrapper con los middlewares y actualizar los mount points para usarlo. Sin esto el sistema de errores nunca se activa para esa ruta, aunque el resto del código esté bien.
3. **`logError`**: agregar la llamada en cada rama de falla existente (todos los `catch`, todos los early-return de error) que todavía no la tenga.

## Paso 2 — Limpieza de código muerto
Criterio verificable (no subjetivo, confirmar con grep real sobre todo el repo, no asumir):
- Funciones/exports sin ningún import ni mount point que los alcance (ej. `revision`, `getRegistroOrganizaciones` no montadas/no llamadas).
- Imports no utilizados.
- Antes de borrar, listar qué se elimina y por qué en la evidencia — no borrar silenciosamente.

**Bugs reales encontrados en el camino**: si aparece un bug real mientras se revisa el código (variable inexistente usada, `res` no recibido pero invocado, retorno de una variable equivocada, catch vacío que cae a una query no relacionada), corregirlo si es autocontenido y de bajo riesgo (ej. `getElecciones` llamando `res.status()` sin tener `res`, `getFormularios103` devolviendo `filter` en vez de `resp`). Si el bug requiere una decisión de negocio o toca lógica ambigua (ej. un catch vacío con fallback a una query no relacionada), **documentarlo, no arreglarlo por cuenta propia** — dejarlo anotado para decisión humana.

## Paso 3 — Unificación de servicios y funciones
Criterio fijo:
- Buscar sitios con llamadas manuales repetidas al mismo patrón (ej. `TokenGasto` + `axios` armado a mano en cada función) y migrarlos al cliente compartido correspondiente (ej. Gasto Electoral client).
- Si el cliente compartido no tiene la función necesaria, agregarla ahí — no crear un cliente nuevo ni duplicar lógica dentro del módulo.
- Antes de agregar una función nueva al cliente compartido, confirmar que no la haya agregado ya otra sesión en paralelo (ver Paso 0).

## Paso 4 — Documentación de la migración
Generar (o actualizar) `docs/manejo-errores-<modulo>.md` con: códigos RW agregados, gaps de wrapper corregidos, código muerto eliminado, bugs encontrados (arreglados y solo documentados por separado), y funciones de cliente unificadas/agregadas.

## Paso 5 — Cierre obligatorio (todos los CLIs)
1. Correr el suite de tests completo — no se considera terminado si algún test falla.
2. **No commitear automáticamente.** Dejar los cambios sin commit para revisión, y listar en la evidencia qué archivos se tocaron.
3. Registrar plan + resultado con `evidence_logger`, incluyendo lo encontrado en el Paso 0 (trabajo paralelo detectado, si lo hubo).
4. No cerrar la tarea sin paso de `security-reviewer`/Validator sobre los cambios.

## Cómo invocarlo
> "Aplicá el skill `code_error_cleanup_unification` en @routes/api/api-gasto/administrador"

Esto asegura que Claude, Codex y Gemini partan del mismo criterio escrito — catálogo RW, wrapper obligatorio, criterio de código muerto, y patrón de unificación — aunque trabajen en rutas distintas del proyecto.
