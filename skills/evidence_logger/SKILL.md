---
name: evidence_logger
description: Registra evidencia y trazabilidad de cada tarea agentic (plan, outputs por capa, resultado de validación). Úsalo al final de cualquier tarea coordinada por agent_orchestrator.
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
├── security-review.md    # output de security-reviewer
└── qa-report.md          # output de qa-tester
```

Cada archivo debe incluir: timestamp, agente que lo generó, status, y el
output estructurado que ese agente devolvió (ver formato en cada agente).

## Reglas
- Nunca sobrescribas evidencia de tareas anteriores — cada `task_id` tiene su
  propia carpeta.
- Si una tarea queda "blocked" o "needs_review", eso debe quedar explícito en
  `plan.md` para que sea auditable después.
