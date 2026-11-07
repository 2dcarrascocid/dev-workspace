---
name: evidence_logger
description: Registra la evidencia y trazabilidad de cada tarea ADF (plan, outputs por capa, resultado de validación) en .claude/evidence/<task-id>/ y, cuando el Validator aprueba, la certificación liviana en .adf/certifications/. Úsalo al cierre de cualquier tarea coordinada por agent_orchestrator, o cuando el usuario pida "dejá registro de esto" o "¿esta ruta ya está certificada?". No usar para crear standards nuevos (eso pasa por Modo Consultivo y aprobación del usuario).
---

# Evidence Logger

Registrás, para cada `task_id`, un rastro auditable de qué se decidió, qué
capa hizo qué, y qué validación se aplicó.

## Estructura a generar

```
.claude/evidence/<task-id>/
├── plan.md              # decisión del orchestrator: capas, orden, objetivo
├── db.md                 # output de db-architect, si aplicó
├── backend.md             # output de backend-dev, si aplicó
├── frontend.md            # output de frontend-dev, si aplicó
├── mobile.md              # output de mobile-dev, si aplicó
├── security-review.md    # output de security-reviewer
└── qa-report.md          # output de qa-tester
```

Cada archivo debe incluir: timestamp, agente que lo generó, status, y el
output estructurado que ese agente devolvió (ver formato en cada agente).

Además, siempre:
- **`plan.md`**: fichas de módulo usadas (`.adf/modules/<id>.md`, con su
  `estado` en ese momento) y fichas en borrador creadas en la tarea.
- **`qa-report.md` / `security-review.md`**: resultado del gate — comando de
  pruebas ejecutado y su resultado real, `adopcion` vigente, y cada hallazgo
  con su gate (`bloquea` / `recomienda`). Las rutas cambiadas sin prueba
  que quedaron en `recomienda` se registran como "sin cobertura".
- **`qa-report.md`**: findings creados o actualizados
  (`.adf/findings/<id>.md`), con su `status`, la ruta de su prueba de
  regresión y su `test_result` (falló antes / pasó después del fix).
- **Cierre de la tarea** (al final de `plan.md`), con datos reales, nunca
  inferidos:
  ```yaml
  cierre:
    status: approved | blocked | needs_review
    commit: <hash> | null                # null si aún no hay commit
    files_touched: [<ruta>, ...]
    comandos:                            # cada verificación ejecutada
      - {cmd: "<comando>", exit: <código>, resumen: "<1-2 líneas de la salida real>"}
    not_run: [{check: "...", motivo: "..."}]
    findings: [FND-NNN, ...]             # con su status final
    scenarios_covered: [<PREFIJO>-NN, ...]
  ```
  Un comando sin `exit` real no cuenta como ejecutado: va en `not_run`.

## Reglas
- Nunca sobrescribas evidencia de tareas anteriores — cada `task_id` tiene su
  propia carpeta.
- Si una tarea queda "blocked" o "needs_review", eso debe quedar explícito en
  `plan.md` para que sea auditable después.

## Certificación liviana

Complementa la evidencia de arriba, no la reemplaza. **Solo se escribe cuando
el Validator aprueba la tarea** (`status: approved`, sin ningún hallazgo
`bloquea`; los `recomienda` no la impiden); si queda `blocked`, `failed` o
`needs_review`, no se genera certificación.

### Dónde
```
.adf/certifications/<path-normalizado>.yaml
```
`<path-normalizado>` es la ruta real trabajada en esa tarea (tomada de la
instrucción del usuario o de los archivos tocados), con `/` reemplazado por
`_`. Ejemplo: `src/api/pagos/servicios` →
`.adf/certifications/src_api_pagos_servicios.yaml`. Cambia en cada tarea:
nunca es un valor fijo.

### Contenido
Un YAML corto y estructurado (no prosa), armado con los datos reales de la
tarea — nunca copiando el ejemplo literal:

```yaml
task_id: T-20260115-103000               # evidencia en .claude/evidence/<task-id>/
path: src/api/pagos/servicios            # ruta real trabajada
tags: [backend, error-handling]          # capas y temas de la tarea
standard_applied:                        # listas vacías si no aplicó ninguno
  generic: [tools/dev-toolkit/standards/<archivo>.md]   # del toolkit
  local: [standards/<archivo>.md]                       # del proyecto
scenarios_covered: [ERR-01, ERR-02]      # IDs con test (qa-tester); [] si no hay escenarios
scenarios_out: [{id: ERR-03, motivo: "..."}]
findings: [FND-003]                      # findings de la tarea, todos con status final (los F-… legado también valen)
hallazgos: [MISSING-PROJECT-STANDARD]    # recomienda que quedaron abiertos
validated_by: security-reviewer          # Validator que aprobó
files_touched:
  - src/api/pagos/servicios/pagos.service.js
tests_passed: true
date: 2026-01-15T10:42:00-03:00          # ISO 8601, momento de la aprobación
commit: 3f2a9c1                          # hash, en el repo donde vive la ruta
agent: claude                            # CLI que ejecutó la tarea
notes: >
  Resumen de una o dos líneas; el detalle vive en .claude/evidence/<task-id>/.
```

Campos obligatorios: `task_id`, `path`, `tags`, `standard_applied`,
`scenarios_covered`, `findings`, `validated_by`, `files_touched`,
`tests_passed`, `date`, `commit` (`scenarios_covered` y `findings` pueden
ser `[]`). Opcionales: `scenarios_out`, `hallazgos`, `agent`, `notes`.

- Una certificación anterior con `standard_applied` como texto se lee como
  `local` o `generic` según la ruta, y se pasa al formato nuevo al
  actualizarla.

- `task_id` debe corresponder a una carpeta existente en
  `.claude/evidence/<task-id>/`.
- `commit` es el hash del commit que contiene los cambios, en el repo donde
  está la ruta (en un proyecto con repos hijos, el repo hijo, no la carpeta
  padre). Si los cambios todavía no están commiteados, la certificación no se
  escribe: queda pendiente en `plan.md` hasta que exista el commit.

Si ya existe una certificación para esa ruta, se actualiza (es el estado
vigente de la ruta); el historial queda en `.claude/evidence/`.

### Cómo se usa
Antes de tocar una ruta, cualquier agente (de cualquier CLI) revisa
`.adf/certifications/` para esa ruta.

**Vigencia (obligatorio antes de confiar en una certificación):** en el repo
donde está la ruta, correr

```bash
git log --oneline <commit>..HEAD -- <files_touched>
```

Si devuelve algún commit, la certificación está **vencida**: esos archivos
cambiaron después de certificarse y no sirve para saltarse trabajo. Si el
comando falla (por ejemplo, el `commit` no existe en ese repo), también se
trata como vencida.

Solo con una certificación vigente:
- Si tiene el mismo `standard_applied` (ambas listas) y `tests_passed: true`, el agente
  parte de ese estado certificado en vez de rehacer el trabajo.
- Si el standard cambió después de la `date` del registro, lo trata como
  vencido y lo señala, en vez de asumir que sigue vigente.
- Si dos sesiones en paralelo tocan rutas hermanas, la segunda sabe qué ya se
  hizo sin leer commits a mano.

Alcance: un YAML por ruta alcanza. Sin schema validator ni dashboard hasta
que el volumen lo justifique.
