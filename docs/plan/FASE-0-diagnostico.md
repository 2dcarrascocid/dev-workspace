# Fase 0 — Diagnóstico

Fecha: 2026-11-07 · Rama: `feat/framework` (creada desde `main` @ `c72ceee`).
Solo lectura: no se modificó ningún archivo del toolkit fuera de `docs/plan/`.

## 0.1 Estado del repo

- `git status`: limpio. `main` 1 commit por delante de `origin/main` (`c72ceee`, el plan).
- La rama `feat/framework` **no existía**; se creó en esta fase desde `main`.
- `git log --oneline -15` (resumen): `c72ceee` plan · `6c6a864` "actulizacion" ·
  `f760508` fix(link) MSYS · `0b756c0` docs(catalog) · `5790313` chequeos `.adf/` ·
  `576e0b7` findings y gate veraz · `0f1e2c4` fichas de módulo · `cc954ab` skills
  locales · `e875dd6` topología B versionada · `adaf985` estado por frente y `./tmp` ·
  `f7e09f8` router · `80646a7` `check-adf.sh` · `7fe6511` docs · `9dbc64c` evidence_logger ·
  `d56d1db` Copilot y OpenCode.

## 0.2 Inventario

### `agents/shared/`
| Archivo | Qué hace |
|---|---|
| `_blocks/modo-consultivo.md` | Bloque canónico de Modo Consultivo; `check-adf.sh` lo sincroniza en los 6 roles entre marcadores `adf:modo-consultivo`. |
| `backend-dev.md` | Specialist backend: agrupación por dominio, globales compartidos, contratos aditivos si hay mobile. |
| `db-architect.md` | Specialist DB: migraciones versionadas/reversibles, riesgos destructivos marcados. |
| `frontend-dev.md` | Specialist web: componentización por materia/submateria, consumo de contrato. |
| `mobile-dev.md` | Specialist móvil, hoy escrito para Flutter (alcance, paquetes, comandos). |
| `qa-tester.md` | Validator de calidad: gate veraz, revisión de CI, severidad por `adopcion`, findings `F-…` con regresión. |
| `security-reviewer.md` | Validator de seguridad: OWASP siempre bloquea, madurez según `adopcion`, checklist móvil. |

Además: `agents/frontmatter/{claude,gemini,codex,copilot,opencode}/` (6 archivos cada uno) y
`agents/dist/` generado (30 archivos).

### `skills/`
| Archivo | Qué hace |
|---|---|
| `CATALOG.md` | Catálogo de herramientas externas (Tipo A vendoreada / Tipo B global) e ideas tomadas/descartadas. |
| `agent_orchestrator/SKILL.md` | Router por objetivo, flujo estándar, `ESTADO.md`, fichas, findings, contrato de delegación. |
| `evidence_logger/SKILL.md` | Evidencia en `.claude/evidence/<task-id>/` + certificación liviana en `.adf/certifications/`. |
| `project_bootstrap/SKILL.md` | Detecta stack por manifiestos, propone `PROJECT.md` y `.gitignore` de la raíz. |
| `adf_health_check/SKILL.md` | Chequeo de solo lectura del setup (agentes, skills, `PROJECT.md`, toolchain, `check-adf.sh`). |
| `secrets_scanner/SKILL.md` | Valores reales en archivos `.env` de ejemplo y exposición en el historial git. |

### `standards/`
**No existe en el toolkit.** `standards/_TEMPLATE.md` se eliminó en `6c6a864` (ver hallazgo H1).

### `templates/`
| Archivo | Qué hace |
|---|---|
| `PROJECT.md.template` | Contexto del proyecto (capas, mobile, pruebas, `adopcion`). |
| `ESTADO.md.template` | Estado por frente + "Para ti" (comandos solo humanos). |
| `FINDING.md.template` | Finding `F-AAAAMMDD-HHMMSS` con prueba de regresión. |
| `MODULE.md.template` | Ficha de módulo (`borrador`/`aprobada`, rutas, invariantes). |
| `.gitignore.template` | `.gitignore` de la raíz: repos hijos, evidencia, `tmp/`, `.env`. |
| `root-tracking.gitignore.template` | Lista blanca para topología B con raíz versionada. |

### `setup/`
| Archivo | Qué hace |
|---|---|
| `bootstrap.sh` | Crea proyecto nuevo: clona el toolkit en `tools/dev-toolkit` y corre `link.sh`. |
| `link.sh` | `build.sh` + symlinks para 5 CLIs + `PROJECT.md`/`CLAUDE.md`/`GEMINI.md`/`AGENTS.md` + `.adf/ESTADO.md`. Falla temprano sin `MSYS` en Git Bash. |
| `update.sh` | `git pull origin main` en `tools/dev-toolkit` + `link.sh`. |
| `check-adf.sh` | Lint del toolkit (13 checks; `--fix`, `--project`, `--deny-file`). |
| `check-global-tools.sh` | Reporta herramientas Tipo B, CLIs instalados y toolchain Flutter. |

Fuera del alcance pedido pero relevante: `commands/` (`/new-task` para Claude/OpenCode y Copilot),
`README.md`, `.gitattributes` (LF para `.sh`, `.md`, `.template`).

## 0.3 Auditoría de amarres

Clasificación: **genérico** (vale para cualquier stack) · **ejemplo** (lista ilustrativa, se
mantiene) · **amarre** (asume una tecnología; va a `profiles/` en Fase 4).

| Archivo | Línea | Tecnología | Clasificación | Propuesta |
|---|---|---|---|---|
| agents/shared/backend-dev.md | 54 | REST/GraphQL | ejemplo | mantener |
| agents/shared/frontend-dev.md | 51 | React/Angular/Vue | ejemplo | mantener |
| agents/shared/mobile-dev.md | 35 | widgets Flutter | amarre | "componentes de UI"; detalle a `profiles/flutter.md` |
| agents/shared/mobile-dev.md | 42-46 | `lib/features/`, `lib/shared/`, `lib/core/` | amarre | regla genérica "por feature + compartido"; rutas al perfil |
| agents/shared/mobile-dev.md | 53-54 | Flutter, Dart | amarre | "app Android + iOS"; framework según perfil |
| agents/shared/mobile-dev.md | 60-61 | `lib/`, `integration_test/`, `pubspec.yaml` | amarre | alcance desde `PROJECT.md`/perfil |
| agents/shared/mobile-dev.md | 66 | modelos Dart | amarre | "modelos tipados" |
| agents/shared/mobile-dev.md | 71-72 | Keychain/Keystore | genérico | mantener |
| agents/shared/mobile-dev.md | 71-72 | `flutter_secure_storage`, `SharedPreferences` | amarre | "almacenamiento no cifrado"; paquetes al perfil |
| agents/shared/mobile-dev.md | 73-74 | OAuth por navegador del sistema | genérico | mantener |
| agents/shared/mobile-dev.md | 74 | `flutter_appauth`, `google_sign_in` | amarre | al perfil |
| agents/shared/mobile-dev.md | 75-77 | `--dart-define`, flavors | amarre | "config por ambiente; binario extraíble" (genérico) + flags al perfil |
| agents/shared/mobile-dev.md | 78-79, 89-92 | `Info.plist`, `AndroidManifest.xml`, keystores, cleartext | genérico | mantener (plataforma nativa, no framework) |
| agents/shared/mobile-dev.md | 90 | `google-services.json` | ejemplo | mantener como ejemplo |
| agents/shared/mobile-dev.md | 93 | pub.dev | amarre | "registro de paquetes" |
| agents/shared/mobile-dev.md | 94 | versión de Flutter | amarre | "versión del framework" |
| agents/shared/mobile-dev.md | 98-102 | iOS requiere macOS/Xcode | genérico | mantener |
| agents/shared/mobile-dev.md | 105 | `flutter analyze`, `flutter test` | amarre | "análisis estático y pruebas del perfil" |
| agents/shared/security-reviewer.md | 63-64 | código Dart, `--dart-define` | amarre | genérico + perfil |
| agents/shared/security-reviewer.md | 65-66 | `SharedPreferences`, `print`/`debugPrint` | amarre | "almacenamiento no cifrado, logs" + perfil |
| agents/shared/security-reviewer.md | 67-72, 75 | PKCE, deep links, HTTPS, permisos, firma | genérico | mantener |
| agents/shared/security-reviewer.md | 73 | pub.dev | amarre | "registro de paquetes" |
| agents/shared/security-reviewer.md | 76 | `--obfuscate --split-debug-info` | amarre | "ofuscación en release si el perfil la define" |
| agents/shared/qa-tester.md | 44-46 | npm, pytest, dotnet, go, mvn, flutter | ejemplo | mantener |
| agents/shared/qa-tester.md | 55-67 | Azure Pipelines, GitHub Actions, GitLab, Bitbucket | ejemplo | mantener (cubre varias plataformas) |
| agents/shared/qa-tester.md | 109-110 | `flutter analyze/test`, `integration_test` | amarre | comandos del perfil |
| agents/shared/qa-tester.md | 113-114 | casos borde móviles | genérico | mantener |
| agents/shared/db-architect.md | — | ninguna | genérico | — |
| skills/agent_orchestrator/SKILL.md | 25 | "Android + iOS en Flutter" | amarre | "app móvil (framework según perfil)" |
| skills/agent_orchestrator/SKILL.md | 65 | `package.json`, `pubspec.yaml` | ejemplo | mantener |
| skills/adf_health_check/SKILL.md | 38-41 | `flutter doctor`, Xcode, CocoaPods | amarre | "toolchain del perfil declarado" |
| skills/project_bootstrap/SKILL.md | 14-29 | tabla de detección multi-stack | ejemplo | mantener (detectar es su función) |
| skills/secrets_scanner/SKILL.md | 28-29, 60 | JWT, AWS, Stripe, Supabase | ejemplo | mantener |
| templates/PROJECT.md.template | 14 | "Flutter — Android + iOS" fijo | amarre | `{{FRAMEWORK_MOBILE}}` |
| templates/PROJECT.md.template | 19 | dart-define/flavors | amarre | "ambientes" genérico |
| templates/.gitignore.template | 28 | `node_modules/` | ejemplo | mantener |
| setup/check-global-tools.sh | 70-114 | toolchain Flutter/Android/Xcode | amarre | ejecutar según perfiles de `adf.yaml` |
| setup/check-global-tools.sh | 51-55 | `npm install -g` de CLIs | ejemplo | mantener (sugerencia al humano, el ADF no depende de npm) |

`setup/link.sh`, `setup/update.sh`, `setup/bootstrap.sh`, `setup/check-adf.sh`, `agents/build.sh` y
`commands/`: sin menciones de tecnologías de stack (las coincidencias en `check-adf.sh` son falsos
positivos: `next`, `BLOCK`).

## 0.4 `evidence_logger` y `a5f772a`

**Respuesta: no.** `a5f772a` ("actulizacion de skills", 2026-08-31) solo reescribió un *borrador
de addendum* sin frontmatter (desde `8220254` el archivo no era detectable como skill). La
certificación liviana quedó integrada en `9dbc64c` y se amplió en `576e0b7`. Hoy, en
`skills/evidence_logger/SKILL.md`:

- l. 43-48: se escribe solo con `status: approved` sin `bloquea`.
- l. 50-58: ruta `.adf/certifications/<path-normalizado>.yaml`.
- l. 64-82: campos obligatorios `task_id, path, tags, standard_applied, validated_by, files_touched, tests_passed, date, commit`.
- l. 84-89: sin commit no hay certificación.
- l. 98-108: vigencia con `git log <commit>..HEAD -- <files_touched>`.

Frente a la Fase 2.4 faltan: `scenarios_covered`, `findings`, `standard_applied` separado en
genéricos y locales, comandos con código de salida, `MISSING-PROJECT-STANDARD`.

Nota: el diff de `a5f772a` guarda en el historial rutas de un proyecto real (los ejemplos se
limpiaron en `9dbc64c`; HEAD está limpio). No se cita acá. Reescribir el historial queda a tu
decisión.

## 0.5 `agents/dist/` y determinismo de `build.sh`

- **Versionado:** sí, 30 archivos, todos `i/lf w/lf` (`git ls-files --eol`). `.gitignore` lo
  deja fuera a propósito.
- **Determinista:** sí. Dos corridas en una copia (`scratchpad/build-test`): run1 = run2
  (`diff -rq` rc 0) y run1 = `agents/dist` commiteado (rc 0). `check-adf.sh` check 5: OK.
- Observaciones: `build.sh` no borra de `dist/` lo que ya no existe en `shared/` (roles
  eliminados quedarían huérfanos); un frontmatter faltante solo emite "Aviso" (lo cubre el
  check 4).

## 0.6 Hooks por CLI (documentación vigente al 2026-11-07)

| | Claude Code | Gemini CLI | Codex CLI |
|---|---|---|---|
| Antes de una herramienta | `PreToolUse`: **bloquea** con exit 2 o `permissionDecision: deny` (deny > defer > ask > allow) | `BeforeTool`: **bloquea** con exit 2 o `decision: deny`; puede reescribir argumentos | `PreToolUse`: **bloquea** con exit 2 o `permissionDecision: deny`; cubre Bash, `apply_patch` (Edit/Write) y MCP |
| Después de una herramienta | `PostToolUse`: no deshace; exit 2/`decision: block` devuelve feedback al modelo | `AfterTool`: no deshace; exit 2 oculta/reemplaza el resultado | `PostToolUse`: no deshace; reemplaza el resultado con feedback |
| Al terminar | `Stop`/`SubagentStop`: exit 2 o `decision: block` obliga a seguir (tope 8 seguidas); también `TaskCompleted` | `AfterAgent`: exit 2/`deny` fuerza reintento con el motivo; **no hay evento de subagente** | `Stop`/`SubagentStop`: `decision: block` continúa con el motivo como prompt |
| Otros que bloquean | `UserPromptSubmit`, `PermissionRequest` (solo JSON, exit 2 no cuenta), `PreCompact`, `ConfigChange`… | `BeforeAgent`, `BeforeModel`, `AfterModel` | `UserPromptSubmit`, `PermissionRequest` |
| Configuración | `.claude/settings.json` (proyecto), `settings.local.json`, `~/.claude/settings.json`, managed, plugins, frontmatter de skill/subagente | `hooks` en `.gemini/settings.json` (proyecto) > `~/.gemini/settings.json` > sistema > extensiones | `hooks.json` o `[hooks]` en `config.toml`, en `~/.codex/` o `<repo>/.codex/`; activo por defecto (`[features] hooks = false` lo apaga) |
| Confianza | requiere aceptar la confianza del workspace (en `-p`/SDK se asume confiable) | fingerprint de hooks de proyecto: un cambio = hook nuevo, avisa antes de correr | hooks no gestionados se revisan y confían con `/hooks`; proyecto solo si `.codex/` es de confianza |
| Windows | Git Bash por defecto o `shell: powershell` | sin guía específica en la doc | `command_windows` para override |
| Timeout por defecto | 600 s (command); fallo/timeout **no bloquea** salvo `onFailure: block` | 60 s | no confirmado |

Implicancias para la Fase 7:
- Los tres pueden bloquear una escritura antes de que ocurra → la regla "antes de una edición" es
  implementable en los tres.
- "Al terminar → `adf check`" es implementable como "seguir trabajando" en los tres, pero en
  Gemini solo a nivel de agente (sin subagentes).
- En Claude Code un hook de política debe usar `exit 2` y `onFailure: block`; si no, un error del
  propio hook deja pasar todo.
- Gemini CLI: la doc anuncia que desde el 2026-06-18 los usuarios sin pago y de Google One pasaron
  a Antigravity CLI. Riesgo para el soporte de Gemini a mediano plazo.

Fuentes:
- Claude Code: https://code.claude.com/docs/en/hooks
- Gemini CLI: https://geminicli.com/docs/hooks/reference/ y https://geminicli.com/docs/hooks/
- Codex CLI: https://developers.openai.com/codex/hooks (redirige a https://learn.chatgpt.com/docs/hooks) y https://learn.chatgpt.com/codex/config-file/config-reference

Límite de la verificación: las tres páginas se leyeron con un agente de fetch. En Claude Code
parte de la sección media (detalles de `Stop`/`SubagentStop`, esquemas de entrada) y en Codex
parte de la página llegaron resumidas, no textuales. Antes de la Fase 7 conviene releer en
detalle el evento exacto que se implemente. No se encontró confirmación de que los hooks de Codex
estén desactivados en Windows (lo dicen guías de terceros, no la doc oficial).

## Hallazgos y choques con reglas existentes

- **H1 — `standards/_TEMPLATE.md` eliminado.** `6c6a864` ("actulizacion", 2026-11-07) lo borró,
  pero lo siguen referenciando: el bloque de Modo Consultivo (6 roles y `dist/`),
  `qa-tester.md:97` y `setup/check-adf.sh:382`. El check 7 de `check-adf.sh` hace `grep` sobre un
  archivo inexistente y **pasa en silencio** (no exige ninguna sección). La Fase 2.3 parte de ese
  archivo. ¿Fue intencional?
- **H2 — 5 proveedores, no 3.** El plan habla de `claude, gemini, codex`; el repo genera y enlaza
  además `copilot` y `opencode`. ¿Las fases 4, 5, 7 y 8 los incluyen?
- **H3 — Formato de findings.** Hoy: `F-AAAAMMDD-HHMMSS` en `.adf/findings/*.md` (plantilla,
  `qa-tester`, orchestrator, check 11). El plan 2.1 pide `FND-NNN` correlativo con `status`.
  Hace falta decidir migración o convivencia.
- **H4 — `not_run` contra el gate veraz.** `qa-tester.md:46-48` dice que si las pruebas no se
  corrieron "la tarea no se aprueba"; el plan 2.2 dice que `not_run` "no bloquea por sí sola".
  Choca con una regla existente; necesita tu decisión.
- **H5 — `adf_health_check` desactualizado.** Habla de submodule (l. 29-31) y solo revisa
  `.claude`/`.gemini` (l. 14-25), aunque hoy es clon directo con 5 CLIs. Lo mismo el comentario de
  `.gitignore:23-25` (`git submodule update --remote`).
- **H6 — Entorno.** `check-adf.sh` sale con 1 en esta sesión solo por el check 13
  (`MSYS=disable_pcon` en el shell del agente). Es del entorno, no del repo.
