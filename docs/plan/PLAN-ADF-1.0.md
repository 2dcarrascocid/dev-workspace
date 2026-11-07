# Plan ADF 1.0 — del toolkit al framework

Documento de trabajo para el agente que ejecuta el plan. Se lee completo al
inicio de cada sesión y se ejecuta **una fase a la vez**.

---

## A. Contexto

- Estás en el repo `dev-workspace` (contenido = dev-toolkit del ADF,
  Agentic Development Framework).
- El ADF tiene 6 roles (`db-architect`, `backend-dev`, `frontend-dev`,
  `mobile-dev`, `security-reviewer`, `qa-tester`) coordinados por
  `agent_orchestrator`, que nunca cierra una tarea sin un Validator.
- Prompts por rol en `agents/shared/`, frontmatter por proveedor en
  `agents/frontmatter/{claude,gemini,codex}/`, generados en `agents/dist/`
  con `agents/build.sh`. Skills en `skills/`. Setup en `setup/`.
- Hoy cada proyecto lo consume como clon directo en `tools/dev-toolkit`,
  siguiendo siempre `main`.
- El repo es **genérico**: nunca agregues información de negocio, nombres
  de tablas, rutas ni datos de ningún proyecto real. Los ejemplos son
  neutros.

## B. Objetivo

Publicar el ADF 1.0.0 como framework:

1. versionado con semver;
2. reglas nuevas de calidad (findings, evidencia verificable, standards
   con escenarios);
3. manifiesto `adf.yaml` por proyecto y perfiles de stack fuera de los
   roles;
4. comando único `adf`;
5. **cumplimiento determinista**: las reglas críticas se verifican con
   código (hooks, `adf check`, CI), no solo con instrucciones al modelo;
6. pruebas del propio framework.

## C. Restricciones (no negociables)

- Solo bash + git. Sin npm, sin binarios descargados, sin servicios de
  red, sin telemetría.
- Funciona en macOS, Linux y Windows con Git Bash (Modo Desarrollador +
  `MSYS=winsymlinks:nativestrict`). Archivos `.sh` y `.md` en LF.
- Compatibilidad: un proyecto sin los archivos nuevos sigue funcionando
  como hoy, con un aviso que sugiere migrar.
- Los roles en `agents/shared/` son genéricos. Lo específico de una
  tecnología va en `profiles/`.
- Nada aprueba solo: ningún modo autónomo, ninguna autoaprobación.
- Nunca editar `agents/dist/` a mano: siempre `agents/build.sh`, y los
  3 proveedores quedan consistentes.

## D. Forma de trabajo (todas las fases)

1. **Modo Consultivo**: al empezar cada fase, propón el diseño o el texto
   exacto de los cambios. Espera mi aprobación explícita. Recién ahí
   implementa.
2. Si un cambio choca con una regla existente (Modo Consultivo, reglas
   backend por grupos, componentización frontend, contratos aditivos de
   mobile), **señálalo**; no lo resuelvas en silencio.
3. Rama de trabajo: `feat/framework`. Al menos un commit por fase, en
   Conventional Commits. **Nunca push, merge ni tags sin mi
   confirmación.**
4. Progreso: mantén `docs/plan/ESTADO.md` con una línea por fase
   (pendiente / en curso / hecha / bloqueada + fecha + commit + nota).
   Es lo primero que lees al iniciar sesión.
5. Validación antes de cada commit: criterio de `security-reviewer` y de
   `qa-tester`, con evidencia ejecutada (comando + resultado). Lo que no
   se pudo correr se informa como `not_run` con su motivo.
6. Registra cada fase con `evidence_logger`.
7. Al cerrar la fase: diff resumido por archivo, resultado de la
   validación, decisiones pendientes y qué sigue. Luego **detente**.

---

## Fase 0 — Diagnóstico (solo lectura)

1. `git status`, rama actual y `git log --oneline -15`. Si el árbol no
   está limpio, detente. Crea la rama `feat/framework` y
   `docs/plan/ESTADO.md`.
2. Inventario: cada archivo de `agents/shared/`, `skills/`, `standards/`,
   `templates/` y `setup/`, con una línea sobre qué hace.
3. Auditoría de amarres: busca menciones de tecnologías concretas y
   clasifícalas como **genérico**, **ejemplo** o **amarre**. Tabla:
   archivo · línea · tecnología · clasificación · propuesta.
4. Estado de `evidence_logger`: ¿el commit `a5f772a` ya integró la
   certificación liviana (`.adf/certifications/*.yaml`)? Sí / parcial /
   no, citando líneas.
5. ¿`agents/dist/` está versionado? ¿`build.sh` es determinista (dos
   corridas seguidas sin diff)?
6. Soporte de hooks: según la documentación vigente de cada CLI, ¿qué
   eventos de hooks ofrecen Claude Code, Gemini CLI y Codex CLI, y
   pueden bloquear una acción? Cita la fuente. No asumas.

## Fase 1 — Versionado

- `VERSION` en la raíz (`1.0.0-rc.1` mientras dure la rama).
- `CHANGELOG.md` (Keep a Changelog, en español). Sección breve
  "Historial previo a 1.0.0" reconstruida desde `git log`, sin inventar.
- `docs/versionado.md`, política semver:
  - **MAJOR**: cambia el contrato de `adf.yaml`, se renombra o elimina un
    rol, skill o standard, cambia el formato de evidencia o
    certificaciones, o un proyecto necesita pasos manuales para
    actualizar.
  - **MINOR**: rol, skill, standard, perfil o regla nueva, compatible.
  - **PATCH**: correcciones sin cambio de comportamiento esperado.
- `setup/update.sh [vX.Y.Z] [--main] [--force]`: sin argumento sube a la
  última versión estable etiquetada; muestra el CHANGELOG entre versiones
  antes de aplicar; avisa si es MAJOR; rechaza bajar de versión sin
  `--force`; deja `tools/dev-toolkit` en el tag. `--main` sigue `main`.

## Fase 2 — Calidad: findings, evidencia y escenarios

**2.1 Findings con ID y regresión obligatoria**
- `evidence_logger` registra cada hallazgo como `FND-NNN` (correlativo
  por proyecto): `id`, `descripcion`, `severidad`, `status`
  (`open | resolved | wontfix`, obligatorio, nunca inferido),
  `test_result` (obligatorio si `resolved`), `motivo` (obligatorio si
  `wontfix`).
- `qa-tester`: todo bug corregido lleva un test de regresión que nombra
  su `FND-NNN`.

**2.2 "Sin medir" nunca es "aprobado"**
- En los 6 roles: una verificación que no se pudo correr es `not_run`
  con motivo; no bloquea por sí sola, pero jamás cuenta como `passed`.

**2.3 Standards con escenarios**
- `standards/_TEMPLATE.md`: sección "Escenarios" con IDs
  (`<PREFIJO>-01`…), cada uno verificable; un escenario puede declararse
  `fuera` con motivo.
- `qa-tester`: por cada standard aplicado, existe un test que lleva el ID
  de cada escenario no declarado `fuera`.

**2.4 Evidencia verificable y certificación en capas**
- Cada cierre de tarea registra: `commit`, `files_touched`, comandos
  ejecutados con su código de salida y resumen de salida, `findings`,
  `scenarios_covered`.
- Al cerrar una tarea validada, escribir
  `.adf/certifications/<path-normalizado>.yaml` (path, tags,
  standard_applied separando genéricos y locales, validated_by,
  files_touched, tests_passed, scenarios_covered, findings, commit).
- Si el proyecto tiene standards locales y la tarea no aplica ninguno
  que corresponda: hallazgo `MISSING-PROJECT-STANDARD` (no bloqueante en
  proyectos sin standards locales).
- Antes de reimplementar una ruta, consultar si ya está certificada.

**2.5 Convención `./tmp`**
- `templates/.gitignore.template` ignora `tmp/`. Regla en los roles:
  scripts de un uso, pruebas manuales, descargas y logs van en `./tmp`.
- `project_bootstrap` crea `./tmp` salvo que el proyecto ya versione
  archivos en `tmp/` (en ese caso avisa y no lo toca).

**2.6 `skills/CATALOG.md`**
- QDD-framework: "Descartado (reconfirmado 2026-11-05, v2.9.10)".
  Motivos: escribe un bloque propio en `AGENTS.md`/`CLAUDE.md` (choca con
  los symlinks a `PROJECT.md`), relay móvil y publicación automática de
  incidentes, modo goal con autoaprobación, instalación frágil en
  Windows/Git Bash. Ideas tomadas: Modo Consultivo, `_TEMPLATE.md`,
  findings + regresión, sin medir ≠ aprobado, escenarios, certificación
  en capas, `./tmp`, gate determinista.

## Fase 3 — Standards genéricos nuevos

**3.1 `standards/paginacion-cursor.md`** (escenarios `PAG-`)
- Aplica a todo endpoint que devuelve una colección; sin umbral.
- `limit` por defecto 10, máximo 50 (mayor se recorta; inválido → 400
  con código de error específico).
- Paginación por cursor (keyset): orden estable y determinista por
  columna única o compuesta (ej. `created_at` + `id`); nunca sin
  `ORDER BY`; se piden `limit + 1` registros para saber si hay más, sin
  `COUNT`.
- Respuesta `{ "data": [...], "next": "<cursor opaco>" | null }`;
  siguiente página con `?next=<cursor>`.
- Cursor opaco (ej. base64url de los valores de orden), validado al
  recibirlo; malformado o manipulado → 400. Solo contiene valores de
  orden, nunca datos sensibles. Si cambian los filtros, el cursor
  anterior no vale (definir y documentar el comportamiento).
- Compatibilidad: no cambiar la forma de respuesta de un endpoint
  existente; aplicar en nuevos y, en existentes, solo versionado o con
  parámetro explícito, coordinado con frontend y mobile.
- Excepciones: catálogos chicos y acotados por diseño, declarados.
- Ejemplos neutros para SQL (`WHERE (created_at, id) < ($1, $2) ORDER BY
  created_at DESC, id DESC LIMIT $3`) y para un cliente tipo supabase-js,
  como ejemplos, no como amarre.
- Escenarios: PAG-01 primera página con 10 y `next`; PAG-02 última con
  `next` null; PAG-03 recorrer todo sin repetir ni omitir; PAG-04 limit
  > 50 se recorta; PAG-05 limit inválido → 400; PAG-06 cursor
  manipulado → 400; PAG-07 colección vacía → `[]` y null.

**3.2 `standards/separacion-consulta-presentacion.md`** (escenarios `SCP-`)
- Cada consulta al backend vive en su propia **unidad de consulta**
  reutilizable (llamada, estados cargando/error/vacío, paginación con
  `next`); no dibuja UI.
- **Componentes de presentación**: reciben datos por props/inputs y
  emiten eventos; no llaman al backend.
- **Contenedores** (páginas/secciones) acoplan consultas y
  presentación.
- Antes de crear una unidad, buscar una equivalente; la duplicación es
  hallazgo. Listados usan una unidad genérica alineada con PAG.
- Si el proyecto ya tiene un patrón de estado, se respeta (no introducir
  otro). Equivalencias por stack solo como ejemplo.
- Escenarios: SCP-01 ningún componente de presentación llama al backend;
  SCP-02 una sola unidad por consulta; SCP-03 la unidad expone
  cargando/error/vacío; SCP-04 un componente de presentación se renderiza
  con datos de prueba sin backend.

**3.3 Roles**
- `backend-dev`: todo listado nuevo aplica PAG; un listado existente sin
  paginar se reporta como hallazgo, no se cambia en silencio.
- `frontend-dev` y `mobile-dev`: aplican SCP y consumen listados con
  `next` sin asumir total ni número de páginas. Lo existente se reporta;
  no se refactoriza masivamente.
- `qa-tester`: tests con los IDs PAG-* y SCP-*.
- `security-reviewer`: tope de `limit`, validación del cursor, cursor sin
  datos sensibles.

## Fase 4 — Manifiesto `adf.yaml` y perfiles de stack

1. Esquema de `adf.yaml` en la raíz de cada proyecto, documentado en
   `docs/adf-yaml.md` con ejemplo neutro. Campos propuestos (ajusta y
   justifica): `adf_version`, `topologia` (A repo único · B carpeta padre
   sin git con repos hijos · C monorepo), `repos`, `proveedores`, `roles`
   activos, `perfiles`, `standards_locales`, `skills_locales`,
   `excepciones` (con motivo). Nunca secretos.
2. Validación del esquema en bash. Si hace falta un parser YAML, propón
   la opción más liviana y **espera mi decisión**.
3. **Decisión a consultarme**: en topología B la raíz no tiene git; propón
   dónde vive o cómo se respalda `adf.yaml`.
4. `profiles/` con un archivo por tecnología (ej. `flutter.md`,
   `postgres.md`, `vue.md`, `angular-ngrx.md`). Mueve ahí todo lo que la
   Fase 0 clasificó como **amarre**. En particular, `mobile-dev`,
   `security-reviewer`, `qa-tester` y `adf_health_check` quedan genéricos
   para cualquier app móvil; lo de Flutter va a `profiles/flutter.md`.
   Los roles aplican los perfiles declarados en `adf.yaml`; sin perfil,
   trabajan con el criterio genérico y lo informan.
5. `link.sh` lee `adf.yaml`: enlaza solo roles activos, para los
   proveedores declarados, con sus perfiles. Sin `adf.yaml`, se comporta
   como hoy y sugiere `adf init`.
6. `project_bootstrap` propone un `adf.yaml` desde el stack detectado; no
   lo escribe sin confirmación.

## Fase 5 — Comando `adf` y verificación determinista

Script bash `bin/adf` que envuelve los scripts existentes (refactoriza
solo lo necesario). Ayuda en español (`adf help`, `adf <cmd> --help`).

- `adf init` — crea `adf.yaml` (vía `project_bootstrap`), clona o
  verifica `tools/dev-toolkit` en la versión indicada, corre `link` e
  instala git hooks.
- `adf update [versión] [--main] [--force]` — `update.sh` + `link`.
- `adf link` — regenera `dist/`, symlinks y git hooks.
- `adf doctor [--fix]` — `adf_health_check` + `check-global-tools` +
  validación de `adf.yaml` + `MSYS` en Windows + versión del proyecto vs.
  la última. `--fix` repara solo lo seguro y dice qué cambió.
- **`adf check`** — verificación sin IA; sale con código ≠ 0 si falla:
  - todo finding tiene `status`; los `resolved` tienen `test_result`;
    los `wontfix`, `motivo`;
  - cada certificación tiene sus campos obligatorios;
  - la evidencia coincide con git: el `commit` existe y `files_touched`
    corresponde a su diff (si no, la evidencia se rechaza);
  - `adf.yaml` válido;
  - escenarios de standards aplicados sin test con su ID (los `fuera`
    se informan, no fallan).
  - `--json` para máquinas.
- **`adf report`** — números desde la evidencia, sin puntajes
  inventados: findings abiertos/resueltos/wontfix, regresiones,
  proporción de `not_run`, cobertura de escenarios por standard.
- `adf new-standard <nombre> [--local]`, `adf profiles`, `adf version`.
- **Git hooks** instalados por `adf link` en cada repo con `.git` (en
  topología B, en cada repo hijo), sin pisar hooks existentes del
  proyecto (encadenarlos o avisar):
  - pre-commit: `secrets_scanner` sobre lo staged; bloquea archivos de
    credenciales (`.env`, `*.env` salvo ejemplos con placeholders).
  - pre-push: `adf check`.
  - Bypass solo con `--no-verify`, que queda documentado como excepción
    del humano, nunca para el agente.
- `agent_orchestrator`: corre `adf check` antes de cerrar cualquier
  tarea; si falla, la tarea no se cierra.
- Instalación de `adf` en el PATH para macOS, Linux y Git Bash (symlink a
  `~/.local/bin` o línea en `~/.bashrc` / `~/.zshrc`), sin tocar archivos
  de sistema.

## Fase 6 — Validator aislado con evidencia ejecutada

- El Validator corre en un **subagente nuevo** (contexto aislado) que
  recibe solo: el diff, los standards aplicables, los criterios de
  aceptación y la evidencia. No recibe la conversación de
  implementación.
- Toda afirmación del Validator va con evidencia ejecutada (comando,
  código de salida, resumen). Afirmación sin evidencia = `not_run`.
- Su veredicto: `approved | changes_requested | needs_review`, con
  findings `FND-NNN` cuando corresponda.
- En Codex, donde los roles son skills y no hay subagentes confirmados,
  documenta la alternativa (sesión nueva con el mismo paquete de
  entrada) y márcala como limitación conocida.

## Fase 7 — Hooks del CLI

Según lo confirmado en Fase 0.6. Implementa solo lo que cada CLI soporte
de verdad; lo que no, se documenta como limitación.

- Antes de una edición: bloquear escrituras en archivos de credenciales,
  `agents/dist/` y `tools/dev-toolkit/` desde un proyecto.
- Después de una edición: lint y tests de lo tocado cuando el perfil del
  proyecto los define; el error vuelve al agente.
- Al terminar (tarea o subagente): `adf check`; si falla, el agente
  recibe el motivo y no puede declarar la tarea cerrada.
- Hooks rápidos (objetivo < 5 s salvo tests) y sin red.
- Plantillas por proveedor en `hooks/{claude,gemini,codex}/`, instaladas
  por `adf link` según `adf.yaml`, sin pisar configuración existente del
  usuario.
- Referencia de diseño: hooks `PostToolUse`/`Stop` del fork
  `pcvelz/superpowers` (solo como idea; no copiar código sin revisar
  licencia).

## Fase 8 — CI y banco de pruebas del framework

**8.1 CI** — `.github/workflows/ci.yml` en push y PR:
- `shellcheck` sobre todos los `.sh`, `bin/adf` y hooks;
- `build.sh` y verificación de que `agents/dist/` commiteado coincide con
  lo generado;
- prueba de humo en `tests/fixtures/` (un proyecto por topología A, B y
  C): `adf init` → `adf link` → `adf doctor` → `adf check`, en ubuntu,
  macos y windows (`shell: bash`);
- `secrets_scanner` sobre el propio repo;
- ningún archivo de `agents/shared/` menciona una tecnología fuera de la
  lista de ejemplos permitidos.

**8.2 Release** — al empujar un tag `vX.Y.Z`, crear el release de GitHub
con la sección del CHANGELOG. Nada más.

**8.3 Banco de pruebas de comportamiento** — `tests/banco/`:
- Un proyecto de ejemplo con bugs plantados y documentados en un archivo
  de respuestas (fuera del alcance del agente evaluado): endpoint de
  listado sin paginar, update con el body crudo (mass assignment),
  acción sin comparar identidades que deberían coincidir, secreto real
  en un archivo de ejemplo, componente de presentación que llama al
  backend.
- Script `tests/banco/correr.sh` que documenta cómo correr los roles
  contra ese proyecto (manual, con el CLI elegido) y `evaluar.sh`, que
  compara los findings producidos contra las respuestas y reporta
  detectados / omitidos / falsos positivos.
- Regla en `docs/versionado.md`: una versión MINOR o MAJOR se publica
  solo si el banco no detecta menos que la versión anterior. El
  resultado queda en `tests/banco/resultados/<versión>.yaml`.

## Fase 9 — Documentación, migración y release

- README reestructurado: qué es el ADF, inicio rápido con `adf`,
  conceptos (roles, skills, standards, perfiles, `adf.yaml`, capas de
  cumplimiento), referencia de comandos, versionado, troubleshooting
  (conserva MSYS, CRLF, carpetas random de 8 caracteres, terminales de
  Windows).
- `docs/cumplimiento.md`: tabla de capas (hooks del CLI, git hooks,
  `adf check`, Validator aislado, CI del proyecto, banco de pruebas): qué
  evita cada una y si depende del modelo.
- `docs/gate-ci-proyectos.md`: guía genérica para que cada proyecto
  agregue a su propio pipeline (Azure Pipelines, GitHub Actions u otro):
  tests obligatorios, auditoría de dependencias, `secrets_scanner`,
  análisis estático de seguridad y `adf check`. Ejemplos neutros por
  plataforma.
- `docs/migracion-1.0.md`: pasos genéricos para llevar a 1.0.0 un
  proyecto de topología B y uno de C. No ejecutes nada en proyectos
  reales.
- CHANGELOG: sección 1.0.0 completa.
- Cierre: resultado final de CI local, `adf check` y banco; propón merge
  a `main`, `VERSION` → `1.0.0` y tag `v1.0.0`. **No ejecutes ninguno sin
  mi confirmación.** Entrega los comandos de migración por proyecto, sin
  ejecutarlos.
