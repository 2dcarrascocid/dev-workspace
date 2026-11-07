# Paginación por cursor en listados del backend

Standard genérico del dev-toolkit. En un proyecto se lee desde
`tools/dev-toolkit/standards/paginacion-cursor.md`. Si el proyecto tiene un
standard local de listados, prevalece el local y el agente señala la
diferencia (Modo Consultivo, punto 4).

---

## Nombre del standard
Paginación por cursor (keyset) en listados del backend.

## Cuándo aplica
Todo endpoint nuevo que devuelva una colección. Sin umbral de tamaño: todo
listado pagina siempre. Endpoints existentes: ver "Compatibilidad".

## Criterio (obligatorio, no interpretable)

### Parámetros
- `limit`: opcional, entero positivo en base 10. Por defecto `10`; máximo `50`.
  - `limit` > 50 → se recorta a 50, sin error.
  - `limit` ≤ 0, no entero o no numérico (`0`, `-1`, `abc`, `10.5`, `10abc`)
    → `400` con código `INVALID_LIMIT`.
- `next`: opcional, el cursor recibido en la respuesta anterior. Sin `next` =
  primera página.

### Orden
- Siempre `ORDER BY` estable y determinista sobre columnas `NOT NULL` únicas
  en conjunto; por defecto `created_at DESC, id DESC`. Nunca paginar sin
  `ORDER BY`.
- Índice sobre las columnas de orden en el mismo sentido (lo crea
  `db-architect`).

### Consulta
- Keyset, nunca `OFFSET`.
- Pedir `limit + 1` registros: si vuelven más de `limit`, hay página
  siguiente; se devuelven `limit` y el cursor se arma con el último
  devuelto. Sin `COUNT`.

### Respuesta
```json
{ "data": [ ... ], "next": "<cursor opaco>" }
```
- `next: null` cuando no hay más registros. Colección vacía:
  `{ "data": [], "next": null }`.
- Sin total ni número de páginas. El cliente pide la siguiente con
  `?next=<cursor>`.

### Cursor
- Opaco para el cliente: base64url de un JSON con **solo** los valores de
  orden del último registro y un hash de filtros + orden:
  `{"v":1,"k":["<created_at>","<id>"],"f":"<hash>"}`. Nunca otros campos ni
  datos sensibles.
- `created_at` va como texto exacto de la base (con microsegundos); nunca
  pasa por un `Date` de JS (trunca a milisegundos y repite u omite
  registros).
- Al recibirlo, el backend lo decodifica y valida: estructura, `v`, tipo y
  formato de cada valor (timestamp ISO 8601, `id` del tipo de la columna) y
  que `f` coincida con los filtros y el orden actuales. Cualquier falla →
  `400` `INVALID_CURSOR`. Nunca un `500` ni valores sin validar en la
  consulta (siempre como parámetros, nunca concatenados sin validar).
- Si cambian los filtros o el orden, `f` no coincide → `400`
  `INVALID_CURSOR`; el cliente reinicia sin `next`.
- Los valores decodificados del cursor se validan por tipo (cada uno contra
  el tipo de su columna de orden) y van **siempre como parámetros** de la
  consulta (`$1`, `?`, binding del driver u ORM), nunca concatenados al SQL
  ni a un filtro textual. Si el cliente de base de datos solo acepta un
  filtro como texto (ej. `.or()` de supabase-js), se interpolan únicamente
  valores ya validados por tipo y formato.
- "Cursor manipulado" significa malformado, de otra versión (`v`) o emitido
  con otros filtros u orden (`f`): en todos esos casos `400`
  `INVALID_CURSOR`.
- No se firma: un cursor alterado pero válido solo cambia el punto de
  partida. La autorización y los filtros se aplican siempre en el servidor,
  nunca se deducen del cursor.
- Codificar/decodificar el cursor vive en el módulo global compartido (regla
  de grupos de `backend-dev`); si el proyecto no lo definió, Modo
  Consultivo.

### Errores
`400` con el formato de error del proyecto y código `INVALID_LIMIT` o
`INVALID_CURSOR`.

### Compatibilidad
- No cambiar la forma de respuesta de un endpoint existente que hoy devuelve
  un array.
- Aplicar en endpoints nuevos; en existentes, solo con versión nueva
  (`/v2/...`) o un parámetro explícito (ej. `?paginate=cursor`), coordinado
  vía orchestrator con `frontend-dev` y `mobile-dev`.
- Endpoint existente sin paginar: se reporta como hallazgo, no se cambia en
  silencio.

## Escenarios
<!-- Cada endpoint paginado tiene sus propios tests; el nombre lleva el ID y
     el endpoint, ej. `PAG-03 GET /items: no repite ni omite`. -->
- Prefijo: PAG
- **PAG-01** — dado 11+ registros, cuando se pide sin `next` ni `limit`,
  entonces devuelve 10 registros y `next` ≠ `null`.
- **PAG-02** — dada la última página, entonces `next` es `null`.
- **PAG-03** — dado registros que comparten `created_at`, cuando se recorren
  todas las páginas siguiendo `next`, entonces cada registro aparece
  exactamente una vez y en orden.
- **PAG-04** — cuando `limit=51` o mayor, entonces devuelve como máximo 50 y
  `200`.
- **PAG-05** — cuando `limit` es `0`, `-1`, `abc` o `10.5`, entonces `400`
  `INVALID_LIMIT`.
- **PAG-06** — cuando el cursor está malformado (no base64url, JSON
  inválido, tipo o formato incorrecto) o fue emitido con otros filtros,
  entonces `400` `INVALID_CURSOR`, nunca `500`.
- **PAG-07** — dada una colección vacía, entonces `data: []` y `next: null`.

## Ejemplo de referencia
Sin caso aplicado en el toolkit; ejemplos neutros.

Postgres:
```sql
-- Primera página: sin la condición del cursor.
SELECT id, created_at /* , ... */
FROM items
WHERE /* filtros */ (created_at, id) < ($1, $2)   -- valores del cursor
ORDER BY created_at DESC, id DESC
LIMIT $3;                                         -- limit + 1

-- Índice (db-architect):
-- CREATE INDEX items_created_at_id_idx ON items (created_at DESC, id DESC);
```

supabase-js (`.lt` solo sobre `created_at` se salta los registros que
comparten timestamp; por eso `.or`):
```js
let q = supabase
  .from('items')
  .select('id, created_at')
  .order('created_at', { ascending: false })
  .order('id', { ascending: false })
  .limit(limit + 1);

if (cursor) {
  // cursor ya decodificado y validado: sin eso, una coma o paréntesis rompe el filtro
  const [createdAt, id] = cursor.k;
  q = q.or(`created_at.lt.${createdAt},and(created_at.eq.${createdAt},id.lt.${id})`);
}

const { data, error } = await q;
if (error) throw error;
const hasNext = data.length > limit;
const page = hasNext ? data.slice(0, limit) : data;
const last = page[page.length - 1];
const next = hasNext
  ? Buffer.from(JSON.stringify({ v: 1, k: [last.created_at, last.id], f: filtersHash }))
      .toString('base64url')
  : null;
return { data: page, next };
```

## Excepciones conocidas
- Catálogos chicos y acotados por diseño (ej. lista de regiones): pueden
  devolver un array sin paginar solo si se declaran como excepción en el
  `api_contract` del endpoint, con motivo y tamaño máximo esperado. No se
  asume.
- Endpoints existentes: ver "Compatibilidad".
- Caso no contemplado acá: se señala (Modo Consultivo), no se decide por
  cuenta propia.

## Historial
- Creado: 2026-11-06
- Aprobado por: responsable del dev-toolkit (Modo Consultivo, T-20261106-paginacion)
- Última revisión: 2026-11-07 (validación por tipo y parámetros; definición de cursor manipulado)
