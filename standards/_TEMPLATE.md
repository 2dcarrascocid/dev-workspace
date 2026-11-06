# Plantilla de standards/ — dev-toolkit/standards/_TEMPLATE.md

Copiar este archivo como `standards/<nombre-del-criterio>.md` cada vez que Modo
Consultivo proponga (y el usuario apruebe) un criterio nuevo. Nombre de archivo en
kebab-case, descriptivo (ej. `nombre-del-criterio.md`).

---

## Nombre del standard
<!-- ej: Manejo de errores en rutas de backend -->

## Cuándo aplica
<!-- Qué tipo de tarea/instrucción dispara este standard. Sé específico:
     "cualquier tarea que mencione manejo de errores sobre las rutas del
     backend" -->

## Criterio (obligatorio, no interpretable)
<!-- El patrón exacto, con ejemplo de código si aplica. No describir en abstracto
     ("manejar errores correctamente") — mostrar el patrón real, con antes/después
     si existe un caso ya resuelto. -->

## Escenarios
<!-- Casos verificables que prueban que el criterio se cumple. Prefijo único
     por standard (2-5 mayúsculas, ej. ERR) y un ID por escenario:
     ERR-01, ERR-02… Cada test que lo cubre lleva el ID en su nombre o
     descripción (ej. `it("ERR-01: responde 404 si el recurso no existe")`).
     Los IDs no se reutilizan ni se renumeran: un escenario que deja de
     aplicar se marca (retirado), no se borra. Un escenario que no aplica
     a una tarea puntual se declara `fuera` con su motivo (escenarios_fuera
     en el output del Specialist); no se exige test, pero se reporta. -->
- Prefijo: <!-- ERR -->
- **<PREFIJO>-01** — <!-- dado …, cuando …, entonces … -->

## Ejemplo de referencia
<!-- Ruta/commit de un caso ya aplicado en el codebase, si existe, para que el
     agente lo pueda leer directo en vez de solo la descripción. -->

## Excepciones conocidas
<!-- Casos donde este standard NO aplica o requiere ajuste. Si aparece un caso
     nuevo no contemplado acá, el agente debe señalarlo (ver Modo Consultivo)
     en vez de decidir por su cuenta. -->

## Historial
<!-- Fecha de creación, quién lo aprobó, y fecha de la última vez que se ajustó. -->
- Creado: <!-- YYYY-MM-DD -->
- Aprobado por: <!-- usuario -->
- Última revisión: <!-- YYYY-MM-DD -->
