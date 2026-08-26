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
├── project_bootstrap/SKILL.md    # detecta stack, completa PROJECT.md y .gitignore
├── adf_health_check/SKILL.md     # smoke test del setup ("prueba de blancura")
├── secrets_scanner/SKILL.md      # detecta secretos reales en archivos de ejemplo
└── CATALOG.md          # cómo agregar skills de terceros (grapify, etc.)
commands/
├── new-task.md          # solo Claude Code — atajo para agent_orchestrator
└── README.md
templates/
├── PROJECT.md.template     # a copiar y completar en cada proyecto nuevo
└── .gitignore.template     # base que project_bootstrap completa solo
setup/
├── link.sh              # instala este toolkit en un proyecto ya clonado
├── update.sh             # trae la última versión (git pull adentro del toolkit)
└── bootstrap.sh          # arma un proyecto NUEVO de punta a punta (recomendado)
```

## Sin submodule, a propósito

`tools/dev-toolkit` se **clona** normal (`git clone`), no se agrega como git
submodule. Esto es intencional: un submodule *requiere* que la carpeta padre
sea su propio repo git — y muchos proyectos (una carpeta que solo agrupa
repos hijos ya existentes, como `backend-x/` + `frontend-x/`) no necesitan ni
quieren esa capa extra de git ni un remoto propio para versionar solo config.

Con clon normal, la carpeta padre **no necesita `git init` ni push en ningún
momento** — es pura estructura local. `tools/dev-toolkit` sigue siendo, en sí
mismo, un repo git normal (por eso `update.sh` funciona con un simple
`git pull` ahí adentro).

Si en algún proyecto puntual SÍ querés versionar la carpeta padre (para
portabilidad entre máquinas, por ejemplo), nada te lo impide — `git init` ahí
cuando quieras, agregando `tools/dev-toolkit/` a tu propio `.gitignore` (ya
que ese sí tiene su remoto propio, no hace falta anidarlo).

## Uso en un proyecto nuevo (recomendado — un solo comando)

Guardá `bootstrap.sh` en un lugar fijo de tu máquina (no depende de estar
dentro de ningún proyecto), y usalo cada vez que arranques uno:

```bash
bash ~/bootstrap.sh mi-proyecto-nuevo
```

Hace `git init`, agrega el submodule (con guardas para no anidarlo por
error), corre `link.sh`, y crea `PROJECT.md`/`CLAUDE.md`/`GEMINI.md`. Después,
adentro de una sesión de Claude Code o Gemini CLI en la raíz del proyecto:

```
detectá el stack de este proyecto y completá PROJECT.md
```

Esto también arma el `.gitignore` automáticamente.

## Uso manual (si ya tenés el proyecto inicializado)

```bash
cd mi-proyecto-existente
git clone <url-de-este-repo> tools/dev-toolkit
bash tools/dev-toolkit/setup/link.sh

cp tools/dev-toolkit/templates/PROJECT.md.template PROJECT.md
ln -s PROJECT.md CLAUDE.md
ln -s PROJECT.md GEMINI.md
```

## Actualizar el toolkit en un proyecto existente

```bash
bash tools/dev-toolkit/setup/update.sh
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

## ⚠️ Importante: dónde abrir la sesión

Si tu proyecto tiene repos hijos separados (ej. `backend-x/`, `frontend-x/`,
cada uno con su propio `.git`), **siempre abrí Claude Code / Gemini CLI desde
la raíz del proyecto padre**, nunca parado adentro de un repo hijo.

Motivo: la detección de agentes/skills se corta en el borde de cada
repositorio git. Un repo hijo con su propio `.git` NO ve el `.claude/agents/`
del padre, aunque esté físicamente dentro de esa carpeta. El
`agent_orchestrator` delega internamente en los Specialists, que leen/escriben
archivos dentro de cada repo hijo sin necesitar una sesión propia ahí — no
hace falta (ni conviene) hacer `cd backend-x` para trabajar en esa capa.
