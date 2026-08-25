# commands/ — solo Claude Code

Los slash commands (`.md` en esta carpeta) son específicos de Claude Code —
Gemini CLI no comparte este mecanismo, a diferencia de `skills/` que sí es
cross-provider. Por eso `link.sh` solo los symlinkea en `.claude/commands/`.

En Gemini CLI, para lograr lo mismo que `/new-task <descripción>`, simplemente
describí la tarea en lenguaje natural — la skill `agent_orchestrator` se
activa igual por su `description`, sin necesidad de un comando explícito.
