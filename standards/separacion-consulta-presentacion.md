# Separación entre consulta y presentación en frontend y mobile

Standard genérico del dev-toolkit. En un proyecto se lee desde
`tools/dev-toolkit/standards/separacion-consulta-presentacion.md`. Si el
proyecto tiene un standard local equivalente, prevalece el local y el agente
señala la diferencia (Modo Consultivo, punto 4).

---

## Nombre del standard
Separación entre unidades de consulta, componentes de presentación y
contenedores.

## Cuándo aplica
Todo código **nuevo** de frontend (web) o mobile que lee datos del backend.
El código existente que no lo cumple se reporta como hallazgo; no se
refactoriza en masa ni en silencio.

## Criterio (obligatorio, no interpretable)

### Unidad de consulta
- Cada consulta al backend vive en **una** unidad de consulta reutilizable:
  hace la llamada, maneja sus estados y expone `data`, `cargando`, `error` y
  `vacío`.
- Si es un listado: expone además `next` y una acción `cargarMás`, y consume
  la paginación de `paginacion-cursor.md` (sin total ni número de páginas;
  vuelve a la primera página si cambian los filtros). Los listados usan una
  unidad genérica de listado paginado, no una implementación por pantalla.
- No dibuja UI ni conoce componentes.
- Antes de crear una, buscar una equivalente (mismo endpoint y mismos
  parámetros). Dos unidades para la misma consulta son un hallazgo.

### Componente de presentación
- Recibe los datos por props/inputs/parámetros y comunica acciones emitiendo
  eventos o callbacks.
- **Nunca** llama al backend: no importa un cliente HTTP, un SDK de datos ni
  una unidad de consulta.

### Contenedor
- Página o sección que acopla unidades de consulta con componentes de
  presentación: obtiene los datos de la unidad y se los pasa al componente.
- Es el "componente padre" de las reglas de componentización de
  `frontend-dev` y `mobile-dev`.

### Patrón de estado del proyecto
- Si el proyecto ya tiene un patrón de estado o de acceso a datos (store,
  librería de caché de consultas, gestor de estado móvil), la unidad de
  consulta se implementa con ese patrón. Nunca se introduce otro.
- Si no hay patrón definido: Modo Consultivo.

## Escenarios
<!-- Los tests llevan el ID en su nombre o descripción, ej.
     `it("SCP-04: ItemCard se renderiza con datos de prueba")`. -->
- Prefijo: SCP
- **SCP-01** — dado el código nuevo de la tarea, ningún componente de
  presentación importa un cliente HTTP, un SDK de datos ni una unidad de
  consulta.
- **SCP-02** — dada una consulta (endpoint + parámetros), existe una sola
  unidad que la hace; no hay dos unidades para la misma consulta.
- **SCP-03** — dada la unidad de consulta, cuando el backend responde con
  datos, con error o con una colección vacía, entonces expone
  respectivamente `data`, `error` y `vacío`, y `cargando` mientras espera;
  cada estado tiene su test.
- **SCP-04** — dado un componente de presentación, cuando se renderiza en un
  test con datos de prueba, entonces funciona sin backend ni mocks de red.

## Ejemplo de referencia
Sin caso aplicado en el toolkit; ejemplos neutros. Las equivalencias por
stack son solo ejemplos, no amarres:

| Stack | Unidad de consulta | Presentación | Contenedor |
|---|---|---|---|
| React | hook (`useItems`) | componente con props | página/sección |
| Vue | composable (`useItems`) | componente con props/emits | vista |
| Angular | servicio (o efectos/selectores si el proyecto usa un store) | componente con `@Input`/`@Output` | componente de página |
| Flutter | repositorio + controller/notifier del gestor de estado del proyecto | widget con parámetros del constructor | pantalla |

Pseudocódigo (TypeScript neutro):
```ts
// Unidad de consulta: llamada + estados, sin UI.
function useItems(filtros) {
  const lista = usePaginatedList((next) => api.get('/items', { ...filtros, next }));
  return lista; // { data, cargando, error, vacio, next, cargarMas }
}

// Presentación: solo datos y eventos.
function ItemList({ items, puedeCargarMas, onCargarMas }) { /* render */ }

// Contenedor: acopla.
function ItemsPage() {
  const { data, cargando, error, vacio, next, cargarMas } = useItems({});
  // estados de carga / error / vacío y luego:
  // <ItemList items={data} puedeCargarMas={next !== null} onCargarMas={cargarMas} />
}
```

## Excepciones conocidas
- Prototipos o pantallas descartables declarados como tales en el output del
  Specialist, con motivo.
- Código existente: se reporta como hallazgo, no se refactoriza en masa.
- Caso no contemplado acá: se señala (Modo Consultivo), no se decide por
  cuenta propia.

## Historial
- Creado: 2026-11-07
- Aprobado por: responsable del dev-toolkit (Modo Consultivo, Fase 3 del plan ADF 1.0)
- Última revisión: 2026-11-07
