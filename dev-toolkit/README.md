# dev-toolkit

Espacio de trabajo personal con la arquitectura ADF base (agentes + skills,
genérica, sin información de negocio) y una librería curada de skills de
terceros que aportan al desarrollo (ej. optimización de tokens, sistemas de
estilos frontend, etc.). Compatible con **Claude Code** y **Gemini CLI** a la
vez, sin duplicar contenido.

Este repo se consume como **git submodule** dentro de cualquier proyecto
nuevo. El contenido de negocio (stack, convenciones, paths) NUNCA vive acá —
vive en un `PROJECT.md` local de cada proyecto consumidor.

## Por qué funciona con los dos CLIs

- **Skills**: Claude Code y Gemini CLI implementan el mismo estándar abierto
  "Agent Skills" (carpeta con `SKILL.md`). La carpeta `skills/` de este repo
  se symlinkea tal cual a `.claude/skills/base` y a `.gemini/skills/base` —
  cero duplicación.
- **Agentes (subagentes)**: el mecanismo es equivalente (.md + YAML
  frontmatter) pero el frontmatter difiere (nombres de tools, campo `model`).
  Por eso el cuerpo del prompt vive una sola vez en `agents/shared/`, y hay un
  frontmatter por proveedor en `agents/frontmatter/{claude,gemini}/`. Un
  script (`agents/build.sh`) combina ambos y genera `agents/dist/{claude,gemini}/`,
  que es lo que se symlinkea en cada proyecto.
- **Contexto de proyecto**: `CLAUDE.md` y `GEMINI.md` en cada proyecto son
  symlinks al mismo `PROJECT.md` — el negocio se escribe una sola vez.

## Estructura

```
agents/
├── shared/            # cuerpo del prompt por rol, provider-agnostic
├── frontmatter/
│   ├── claude/         # frontmatter específico de Claude Code por rol
│   └── gemini/          # frontmatter específico de Gemini CLI por rol
├── dist/               # generado por build.sh — esto es lo que se symlinkea
└── build.sh
skills/
├── agent_orchestrator/SKILL.md
├── evidence_logger/SKILL.md
├── project_bootstrap/SKILL.md    # detecta stack y completa PROJECT.md
├── adf_health_check/SKILL.md     # smoke test del setup ("prueba de blancura")
└── CATALOG.md          # cómo agregar skills de terceros (grapify, etc.)
commands/
├── new-task.md          # solo Claude Code — atajo para agent_orchestrator
└── README.md
templates/
└── PROJECT.md.template  # a copiar y completar en cada proyecto nuevo
setup/
└── link.sh              # instala este toolkit en un proyecto (Claude + Gemini)
```

## Uso en un proyecto nuevo

```bash
cd mi-proyecto-nuevo
git submodule add <url-de-este-repo> tools/dev-toolkit
bash tools/dev-toolkit/setup/link.sh

cp tools/dev-toolkit/templates/PROJECT.md.template PROJECT.md
ln -s PROJECT.md CLAUDE.md
ln -s PROJECT.md GEMINI.md
# completar PROJECT.md con stack, convenciones y paths del proyecto
```

## Actualizar el toolkit en un proyecto existente

```bash
git submodule update --remote tools/dev-toolkit
bash tools/dev-toolkit/setup/link.sh   # re-symlinkea por si hay agentes nuevos
```

## Modificar un agente (rol ADF)

1. Editar el cuerpo en `agents/shared/<rol>.md` (aplica a ambos CLIs), y/o el
   frontmatter en `agents/frontmatter/claude/<rol>.md` o `.../gemini/<rol>.md`.
2. Correr `bash agents/build.sh` para regenerar `agents/dist/`.
3. Commit + push. Cada proyecto lo recibe con `git submodule update --remote`.

## Agregar una nueva librería/skill de terceros

Ver `skills/CATALOG.md`.
