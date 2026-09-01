# dev-toolkit

Espacio de trabajo personal con la arquitectura ADF base (agentes + skills,
genérica, sin información de negocio) y una librería curada de skills de
terceros que aportan al desarrollo (ej. optimización de tokens con grafos de
conocimiento, sistemas de estilos frontend, etc.). Compatible con
**Claude Code**, **Gemini CLI** y **Codex CLI** a la vez, sin duplicar
contenido.

El contenido de negocio (stack, convenciones, paths) NUNCA vive acá — vive en
un `PROJECT.md` local de cada proyecto consumidor.

Este toolkit se aplica igual en **Windows, Linux y Mac**, e igual sea el
proyecto un repo único, una carpeta padre con varios repos hijos, o un
monorepo — ver "Topologías de proyecto soportadas" más abajo.

## Por qué funciona con los tres CLIs

- **Skills**: Claude Code, Gemini CLI y Codex CLI implementan el mismo
  estándar abierto "Agent Skills" (carpeta con `SKILL.md`). La carpeta
  `skills/` de este repo se symlinkea tal cual a `.claude/skills/base`,
  `.gemini/skills/base` y `.codex/skills/base` — cero duplicación.
- **Agentes (subagentes)**: Claude Code y Gemini CLI tienen subagentes reales
  (contexto aislado); el mecanismo es equivalente (.md + YAML frontmatter)
  pero el frontmatter difiere (nombres de tools, campo `model`). Por eso el
  cuerpo del prompt vive una sola vez en `agents/shared/`, y hay un
  frontmatter por proveedor en `agents/frontmatter/{claude,gemini}/`. Codex
  no tiene ese mecanismo de subagente confirmado, así que ahí los 5 roles se
  exponen como **skills** en su lugar (`.codex/skills/<rol>/SKILL.md`), no
  como agentes.
  Un script (`agents/build.sh`) combina cuerpo + frontmatter y genera
  `agents/dist/{claude,gemini,codex}/`, que es lo que se symlinkea en cada
  proyecto.
- **Contexto de proyecto**: `CLAUDE.md`, `GEMINI.md` y `AGENTS.md` en cada
  proyecto son symlinks al mismo `PROJECT.md` — el negocio se escribe una
  sola vez.

## Estructura

```
agents/
├── shared/                        # cuerpo del prompt por rol, provider-agnostic
├── frontmatter/{claude,gemini,codex}/  # config específica por CLI
├── dist/{claude,gemini,codex}/    # generado por build.sh — esto es lo que se symlinkea
└── build.sh
skills/
├── agent_orchestrator/SKILL.md    # coordina el flujo completo
├── evidence_logger/SKILL.md       # registra plan + resultado de cada tarea
├── project_bootstrap/SKILL.md     # detecta stack, completa PROJECT.md y .gitignore
├── adf_health_check/SKILL.md      # smoke test del setup ("prueba de blancura")
├── secrets_scanner/SKILL.md       # detecta secretos reales en archivos de ejemplo
└── CATALOG.md                     # herramientas de terceros (graphify, ui-ux-pro-max, etc.)
commands/
├── new-task.md                    # solo Claude Code — atajo para agent_orchestrator
└── README.md
standards/
└── _TEMPLATE.md                   # plantilla genérica para standards de proyecto (viven en local)
templates/
├── PROJECT.md.template            # a copiar y completar en cada proyecto nuevo
└── .gitignore.template            # base que project_bootstrap completa solo
setup/
├── bootstrap.sh                   # arma un proyecto NUEVO de punta a punta (recomendado)
├── link.sh                        # instala/actualiza symlinks en un proyecto ya clonado (auto-verificado)
├── update.sh                      # trae la última versión del toolkit (git pull adentro)
└── check-global-tools.sh          # verifica graphify/ui-ux-pro-max instalados globalmente
.gitattributes                     # fuerza LF en .sh (evita error CRLF en Windows)
```

Cada proyecto consumidor, además, tiene sus propias carpetas `*/agents/local/`
y `*/skills/local/` para standards y skills específicos de ese negocio —
esas nunca viven en este repo.

## Sin submodule, por defecto

`tools/dev-toolkit` se **clona** normal (`git clone`), no se agrega como git
submodule. Esto es intencional: un submodule *requiere* que la carpeta padre
sea su propio repo git — y muchos proyectos (una carpeta que solo agrupa
repos hijos ya existentes, como `backend-x/` + `frontend-x/`) no necesitan ni
quieren esa capa extra de git ni un remoto propio solo para versionar config.

Con clon normal, la carpeta padre **no necesita `git init` ni push en ningún
momento** — es pura estructura local. `tools/dev-toolkit` sigue siendo, en sí
mismo, un repo git normal (por eso `update.sh` funciona con un simple
`git pull`/`git merge --ff-only` ahí adentro).

Si en algún proyecto puntual SÍ preferís submodule (por ejemplo, para que la
carpeta padre sea reconstruible con un número fijo de comandos en cualquier
máquina, versionando también los repos hijos como parte de un monorepo), es
una decisión válida por proyecto — no el default.

## Topologías de proyecto soportadas

| Escenario | Ejemplo real | `.git` en la raíz del proyecto |
|---|---|---|
| **A.** Repo único | proyecto típico chico | sí |
| **B.** Carpeta padre + repos hijos independientes | rendicion (core + web + web-servel) | no — cada repo hijo tiene el suyo |
| **C.** Monorepo (repos hijos integrados) | superliga | sí |

El setup de `link.sh` es idéntico en los tres casos. Lo único que cambia es
el `.graphifyignore` para la base de conocimiento (ver más abajo) y, en el
escenario B, que no hay git hooks posibles a nivel raíz.

## Uso en un proyecto nuevo (recomendado — un solo comando)

Guardá `bootstrap.sh` en un lugar fijo de tu máquina (no depende de estar
dentro de ningún proyecto), y usalo cada vez que arranques uno:

```bash
bash ~/bootstrap.sh mi-proyecto-nuevo
```

Hace `git init` (si corresponde), clona el toolkit, corre `link.sh`, y crea
`PROJECT.md`/`CLAUDE.md`/`GEMINI.md`/`AGENTS.md`. Después, adentro de una
sesión de Claude Code / Gemini CLI / Codex CLI en la raíz del proyecto:

```
detectá el stack de este proyecto y completá PROJECT.md
```

Esto también arma el `.gitignore` automáticamente.

## Uso manual (si ya tenés el proyecto inicializado)

```bash
cd mi-proyecto-existente
git clone https://github.com/2dcarrascocid/dev-workspace.git tools/dev-toolkit
bash tools/dev-toolkit/setup/link.sh

cp tools/dev-toolkit/templates/PROJECT.md.template PROJECT.md
ln -s PROJECT.md CLAUDE.md
ln -s PROJECT.md GEMINI.md
ln -s PROJECT.md AGENTS.md
```

### ⚠️ Windows (Git Bash / MINGW64) — leer antes de correr `link.sh`

Git Bash **no crea symlinks nativos de Windows por defecto, aunque el Modo
Desarrollador esté activo** — es una limitación de MSYS, no de Windows en sí.
Sin este fix, `link.sh` falla con `ln: failed to create symbolic link '...':
Not a directory`, o peor: crea carpetas con archivos **copiados** en vez de
symlinks reales, que después se desincronizan en silencio de `agents/dist/`.

**Fix, una sola vez por máquina/terminal:**
```bash
echo 'export MSYS=winsymlinks:nativestrict' >> ~/.bashrc
source ~/.bashrc
```
Confirmá que el Modo Desarrollador también esté activo (Configuración →
Privacidad y seguridad → Para desarrolladores) — es necesario pero no
suficiente por sí solo; hace falta la variable `MSYS` además.

Si `link.sh` sigue fallando después de aplicar el fix, buscá restos de una
corrida previa interrumpida: carpetas con nombre random (8 caracteres
alfanuméricos) dentro de `.claude/agents/`, `.claude/skills/`, `.gemini/...`,
`.codex/...`. Son temporales que `link.sh` usa para crear el symlink de
forma atómica y no llegaron a promoverse. Borralas junto con el symlink que
falló, y reintentá:
```bash
rm -rf .claude/agents/<carpeta-random> .claude/agents/base
tools/dev-toolkit/setup/link.sh
```

### Windows — terminales múltiples

WSL, Git Bash y PowerShell tienen cada uno su propio `$HOME` y `PATH`. Un CLI
o skill instalada en una terminal **no aparece en las otras**. Reglas
prácticas:
- Elegí una terminal de trabajo por proyecto y quedate ahí durante todo el
  setup (no alternes Git Bash ↔ WSL a mitad de tarea).
- Instalar `claude`/`gemini`/`codex` en una terminal no lo hace disponible en
  las otras. Confirmá con `which <comando>` en la terminal específica que
  estás usando.
- `check-global-tools.sh` ya contempla esto: detecta si corre en WSL y
  también busca en `/mnt/c/Users/*/` por si las skills globales quedaron
  instaladas del lado Windows.

### Linux / Mac

Symlinks nativos, sin configuración adicional. Si `link.sh` falla ahí, es un
problema real (permisos, ruta rota) y no el bug de MSYS de arriba.

## Actualizar el toolkit en un proyecto existente

```bash
cd tools/dev-toolkit
git fetch origin
git log HEAD..origin/main --oneline   # ver qué trae antes de aplicar
git merge origin/main --ff-only
cd ../..
bash tools/dev-toolkit/setup/link.sh  # re-symlinkea por si hay agentes/skills nuevos
```

`update.sh` hace esto mismo en un paso.

## Base de conocimiento (graphify)

Cada proyecto puede tener su propio grafo de código consultable, agnóstico
de qué CLI estés usando en el momento.

### Instalar/actualizar graphify (una vez por máquina)

```bash
graphify --version
graphify install                     # actualiza la skill de Claude Code
graphify install --platform agents   # actualiza la skill compartida de Gemini CLI / Codex CLI
```

### `.graphifyignore` — según la topología (A/B/C de arriba)

**Escenarios A y C** (hay `.git` en la raíz): el `.gitignore` ya se respeta
automáticamente por directorio. El `.graphifyignore` solo agrega exclusiones
extra:
```
tools/dev-toolkit/
CLAUDE.md
GEMINI.md
AGENTS.md
.claude/
.gemini/
.codex/
```

**Escenario B** (carpeta padre sin `.git`, repos hijos independientes): cada
repo hijo respeta su propio `.gitignore` en su subárbol, pero conviene forzar
la inclusión explícita de cada repo hijo por si graphify saltea carpetas con
`.git` anidado (no confirmado, mejor no asumir):
```
tools/dev-toolkit/
CLAUDE.md
GEMINI.md
AGENTS.md
.claude/
.gemini/
.codex/
!repo-hijo-1/**
!repo-hijo-2/**
```

### Primera extracción

```bash
graphify extract . --code-only      # AST local, sin LLM — rápido, valida cobertura
graphify cluster-only .             # genera GRAPH_REPORT.md, graph.html y nombra comunidades
```
El output cae en `<raíz-del-proyecto>/graphify-out/` por default. Revisá los
warnings de la extracción: graphify marca archivos `.env*` como
"potencialmente sensibles" y los lista sin extraerlos — es una señal útil
para auditar credenciales expuestas, no solo ruido a ignorar.

### Mantener el grafo actualizado (elegir uno)

- **Manual** (proyectos con actividad esporádica):
  ```bash
  graphify update .
  graphify cluster-only .
  ```
  Correrlo al empezar una sesión larga o después de un merge grande.

- **`watch`** (sesiones de desarrollo activo, funciona en cualquier
  escenario A/B/C, no depende de `.git`):
  ```bash
  graphify watch .
  ```

- **Git hooks** (solo escenarios A y C, con `.git` en la raíz):
  ```bash
  graphify hook install
  ```
  No aplica al escenario B: sin `.git` en la carpeta padre no hay dónde
  enganchar el hook — usar `watch` o la actualización manual ahí.

- **Pasada semántica completa** (opcional, requiere API key de un LLM):
  ```bash
  graphify extract . --mode deep --backend <claude|gemini|openai|...>
  ```
  Da nombres de comunidad reales en vez de `Community N`. No es necesaria
  para el uso diario.

### Consultar el grafo (agnóstico de agente)

```bash
graphify query "<pregunta>" --graph graphify-out/graph.json
graphify god-nodes --top 15 --graph graphify-out/graph.json    # mapa de arquitectura real
graphify affected "<símbolo>" --graph graphify-out/graph.json  # qué se rompe si cambio X
```
El path es el mismo para los tres CLIs — no importa con cuál trabajes en un
momento dado.

## Modificar un agente (rol ADF)

1. Editar el cuerpo en `agents/shared/<rol>.md` (aplica a los tres CLIs), y/o
   el frontmatter en `agents/frontmatter/{claude,gemini}/<rol>.md`.
2. Correr `bash agents/build.sh` para regenerar `agents/dist/`.
3. Commit + push. Cada proyecto lo recibe con `update.sh` + `link.sh`.

## Agregar una nueva librería/skill de terceros

Ver `skills/CATALOG.md`.

## ⚠️ Importante: dónde abrir la sesión

Si tu proyecto tiene repos hijos separados (ej. `backend-x/`, `frontend-x/`,
cada uno con su propio `.git`), **siempre abrí Claude Code / Gemini CLI /
Codex CLI desde la raíz del proyecto padre**, nunca parado adentro de un
repo hijo.

Motivo: la detección de agentes/skills se corta en el borde de cada
repositorio git. Un repo hijo con su propio `.git` NO ve el `.claude/agents/`
del padre, aunque esté físicamente dentro de esa carpeta. El
`agent_orchestrator` delega internamente en los Specialists, que leen/escriben
archivos dentro de cada repo hijo sin necesitar una sesión propia ahí — no
hace falta (ni conviene) hacer `cd backend-x` para trabajar en esa capa.

## Troubleshooting

**Symlinks fallan en Windows (`base` queda como carpeta vacía o con archivos
copiados, no como link)**
→ Ver la sección "Windows (Git Bash / MINGW64)" más arriba — el fix es la
variable `MSYS=winsymlinks:nativestrict`, el Modo Desarrollador solo no
alcanza.

**`claude`/`gemini`/`codex` da "command not found" después de instalarlo**
→ Cada CLI (y cada terminal — WSL, Git Bash, PowerShell son entornos
distintos con su propio PATH) necesita su propia instalación. Confirmá con
`which <comando>` en la terminal específica que estás usando.

**No sé si tengo la última versión del toolkit en este proyecto**
→ `link.sh` (o `update.sh`) siempre imprime al final la versión instalada
(hash corto + fecha del commit). Compará con el último commit del repo en
GitHub si tenés dudas.

**Clon quedó anidado (`tools/dev-toolkit/dev-toolkit/`)**
→ Pasa cuando `git clone` se corre estando parado *adentro* de `tools/` o
`tools/dev-toolkit/` en vez de la raíz del proyecto. Confirmá con `pwd` antes
de clonar. `bootstrap.sh` ya incluye una guarda que aborta si detecta esta
situación.
