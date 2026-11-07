# Estado del plan ADF 1.0

Se lee primero al iniciar sesión. Una línea por fase. Plan: `docs/plan/PLAN-ADF-1.0.md`.

| Fase | Estado | Fecha | Commit | Nota |
|---|---|---|---|---|
| 0 — Diagnóstico | hecha | 2026-11-07 | `864d439` | Rama creada desde `main`. Diagnóstico en `FASE-0-diagnostico.md`. Pendientes de decisión: H1-H5. |
| Limpieza de historial | cancelada | 2026-11-07 | — | Cancelada por la persona. Espejo y archivos de reemplazo borrados; no se hizo push. El historial público sigue con datos de un proyecto real. |
| 1 — Versionado | pendiente | — | — | — |
| 2 — Calidad: findings, evidencia y escenarios | hecha | 2026-11-07 | `96cad2d`..`051ef05` | 7 commits traídos con cherry-pick de `origin/2dcarrascocid/feat-dev-toolkit-generic` + 3 de ajuste (FND-NNN, `not_run` → `needs_review`, comandos en el cierre, checks 7 y 11 con pruebas). `8096f4a` (paginación) queda para la Fase 3.1. |
| 3 — Standards genéricos nuevos | hecha | 2026-11-07 | `3af598b`..`ab0f4d2` | `paginacion-cursor` (cherry-pick de `8096f4a` + validación por tipo y parámetros, cursor sin firma) y `separacion-consulta-presentacion` (SCP-01..04). Modo Consultivo busca standards genéricos. Código nuevo que no cumple un standard: bloquea. Check 7 valida los genéricos. |
| 4 — `adf.yaml` y perfiles | pendiente | — | — | Usa la tabla de amarres de 0.3. |
| 5 — Comando `adf` y verificación | pendiente | — | — | — |
| 6 — Validator aislado | pendiente | — | — | — |
| 7 — Hooks del CLI | pendiente | — | — | Base: 0.6. |
| 8 — CI y banco de pruebas | pendiente | — | — | — |
| 9 — Documentación y release | pendiente | — | — | — |
