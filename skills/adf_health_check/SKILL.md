---
name: adf_health_check
description: Corre una verificación rápida de que la arquitectura ADF está funcionando correctamente (agentes detectados, skills detectadas, evidencia registrándose). Úsalo cuando el usuario pida un chequeo de salud del setup, un diagnóstico, o una "prueba de blancura"/smoke test del entorno agentic.
---

# ADF Health Check

Verificás, en orden, que la arquitectura ADF del proyecto activo esté
funcionando de punta a punta. No modificás nada — es un chequeo de solo
lectura.

## Checklist a correr

1. **Agentes**: listar `.claude/agents/base/` (o `.gemini/agents/*.md`) y
   confirmar que están los 5 roles: db-architect, backend-dev, frontend-dev,
   security-reviewer, qa-tester. Si el proyecto tiene `agents/local/`,
   listarlos también y aclarar que son específicos de este proyecto.
2. **Skills**: listar `.claude/skills/base/` (o `.gemini/skills/base/`) y
   confirmar que están `agent_orchestrator`, `evidence_logger`,
   `project_bootstrap` y `adf_health_check`. Listar también cualquier skill
   externa vendoreada (ver `skills/CATALOG.md` del dev-toolkit) o instalada
   globalmente en `~/.claude/skills/` / `~/.gemini/skills/`.
3. **Contexto del proyecto**: confirmar que `PROJECT.md` existe y no tiene
   placeholders sin completar (buscar patrones tipo `{{...}}`). Confirmar
   que `CLAUDE.md` y `GEMINI.md` son symlinks al mismo archivo.
4. **Evidencia**: listar `.claude/evidence/` — si está vacía, es normal en un
   setup recién instalado (avisarlo, no es una falla). Si el usuario ya
   corrió tareas, debería haber al menos una carpeta con `plan.md`.
5. **Submodule**: confirmar que `tools/dev-toolkit/agents/dist/claude/` y
   `tools/dev-toolkit/agents/dist/gemini/` no están vacíos (si lo están, el
   submodule no se inicializó — sugerir `git submodule update --init --recursive`).
6. **Secretos**: si aparece algún archivo `ejm.env`/`.env.example`/similar en
   el proyecto, invocar la skill `secrets_scanner` sobre él como parte del
   reporte, en vez de solo mencionar que existe.

## Formato de reporte

Devolver una tabla simple: ítem | estado (✅/⚠️/❌) | detalle. Si todo está
✅, decirlo en una línea sin alargar el reporte. Si hay algo en ❌, explicar
el paso concreto para arreglarlo (no solo señalar el problema).
