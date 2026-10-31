---
description: Arranca una tarea nueva del flujo ADF con un task_id autogenerado, delegando a agent_orchestrator.
agent: agent
argument-hint: "descripción de la tarea"
---

Iniciá una tarea nueva del flujo ADF con task_id `T-<YYYYMMDD-HHMMSS>` (fecha y
hora actuales).

Objetivo de la tarea: ${input:tarea:descripción de la tarea}

Usá la skill `agent_orchestrator` para planificar qué capas toca, delegar a
los Specialists correspondientes, exigir validación de al menos un Validator,
y registrar evidencia con `evidence_logger` antes de cerrar la tarea.
