# commands/ — slash commands por CLI

Los slash commands no son un estándar compartido como `skills/`, así que cada
CLI recibe solo lo que entiende:

- **Claude Code**: `commands/*.md` → `.claude/commands/`.
- **OpenCode**: mismo formato (frontmatter + `$ARGUMENTS`), así que
  `commands/*.md` se symlinkea tal cual a `.opencode/commands/`.
- **GitHub Copilot**: usa *prompt files* (`.prompt.md`, con `${input:...}` en
  vez de `$ARGUMENTS`). Su versión vive en `commands/copilot/` y se
  symlinkea a `.github/prompts/`.

En Gemini CLI y Codex CLI, para lograr lo mismo que `/new-task <descripción>`,
simplemente describí la tarea en lenguaje natural — la skill
`agent_orchestrator` se activa igual por su `description`, sin necesidad de
un comando explícito.

Al agregar un comando nuevo acá, si querés que exista en Copilot, creá también
su `commands/copilot/<nombre>.prompt.md`.
