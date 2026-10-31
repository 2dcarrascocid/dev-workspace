---
name: adf_health_check
description: Verifica de punta a punta que el setup ADF del proyecto funcione (agentes y skills detectados, PROJECT.md completo, evidencia, herramientas globales y el lint check-adf.sh) sin modificar nada. Úsalo cuando el usuario pregunte "¿está todo instalado?", "¿funciona el setup?", pida un diagnóstico o una prueba de blancura/smoke test. No usar para tareas de desarrollo (eso es agent_orchestrator) ni para escanear secretos en detalle (eso es secrets_scanner).
---

# ADF Health Check

Verificás, en orden, que la arquitectura ADF del proyecto activo esté
funcionando de punta a punta. No modificás nada — es un chequeo de solo
lectura.

## Checklist a correr

1. **Agentes**: listar `.claude/agents/base/` (o `.gemini/agents/*.md`) y
   confirmar que están los 6 roles: db-architect, backend-dev, frontend-dev,
   mobile-dev, security-reviewer, qa-tester. Si el proyecto tiene `agents/local/`,
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
7. **Herramientas globales**: correr `tools/dev-toolkit/setup/check-global-tools.sh`
   y reportar qué herramientas de `skills/CATALOG.md` (Tipo B — graphify,
   ui-ux-pro-max, etc.) faltan instalar en esta máquina.
8. **Toolchain móvil** (solo si `PROJECT.md` tiene capa Mobile o existe un
   `pubspec.yaml`): correr `flutter doctor -v` y reportar Flutter, Android
   toolchain y — solo en macOS — Xcode y CocoaPods. En Windows/Linux reportar
   iOS como ⚠️ "requiere Mac o CI macOS": no es una falla del setup.
9. **Lint del toolkit**: correr
   `bash tools/dev-toolkit/setup/check-adf.sh --project .` (agregando
   `--deny-file local/adf-deny.txt` si ese archivo existe) y volcar su
   resumen en el reporte: cada check FAIL es ❌, WARN y SKIP son ⚠️. No
   repetir a mano lo que el script ya verifica; si sale con código distinto
   de 0, el detalle de cada FAIL dice qué corregir (y si `--fix` lo resuelve).
10. **Versión del toolkit**: reportar `git -C tools/dev-toolkit rev-parse --short HEAD`
   y la fecha del último commit, para que el usuario sepa si está desactualizado
   sin tener que revisarlo a mano.

## Formato de reporte

Devolver una tabla simple: ítem | estado (✅/⚠️/❌) | detalle. Si todo está
✅, decirlo en una línea sin alargar el reporte. Si hay algo en ❌, explicar
el paso concreto para arreglarlo (no solo señalar el problema).
