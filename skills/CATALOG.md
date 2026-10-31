# Catálogo de herramientas externas adoptadas

Hay dos tipos de herramientas de terceros que vas a ir sumando. Tratalas
distinto:

## Tipo A — Skills sueltas, sin instalador propio

Un `SKILL.md` (o carpeta) que alguien compartió, sin paquete ni updater. Estas
sí se **vendorean** acá:

```
skills/
├── agent_orchestrator/SKILL.md
├── evidence_logger/SKILL.md
└── <nombre-skill>/SKILL.md         <- vendoreada, va directo bajo skills/
```

Pasos:
1. Copiar la carpeta completa (con su `SKILL.md`) dentro de `skills/<nombre>/`.
2. Documentarla en la tabla de abajo.
3. Commit + push. Se propaga con `git submodule update --remote`.

## Tipo B — Herramientas con instalador y updater propio

Ejemplo: **graphify** (github.com/Graphify-Labs/graphify) — mapea el repo a
un knowledge graph consultable, para no leer archivos completos. Se instala
y actualiza con su propio comando; **no se vendorea acá**, se instala directo
en tu máquina y queda disponible en todos los proyectos:

```bash
uv tool install graphifyy
graphify install           # Claude Code (user-level, sin --project)
graphify gemini install    # Gemini CLI
```

Actualizar más adelante:
```bash
uv tool upgrade graphifyy
graphify install            # re-escribe el skill con la versión nueva
```

Estas herramientas solo se **documentan** acá (para acordarte de instalarlas
en una máquina nueva), no se copian.

## Registro

| Herramienta | Tipo | Qué hace | Fuente | Instalación |
|---|---|---|---|---|
| graphify | B (instalador propio) | Mapea el código a un grafo consultable; ahorra tokens vs. leer archivos completos | github.com/Graphify-Labs/graphify | `uv tool install graphifyy && graphify install && graphify gemini install` |
| ui-ux-pro-max | B (instalador propio) | Genera sistemas de diseño (colores, tipografía, patrones) según el tipo de producto; se auto-activa en pedidos de UI/UX | github.com/nextlevelbuilder/ui-ux-pro-max-skill | `npm install -g ui-ux-pro-max-cli && uipro init --ai claude --global && uipro init --ai gemini --global` |

## Evaluados, no adoptados como plataforma

Frameworks o colecciones revisados de los que se tomaron ideas puntuales,
implementadas de forma nativa en el ADF, sin instalarlos.

### QDD Framework — Descartado como plataforma

Fuente: github.com/trdago/qdd-framework. Reevaluado 2026-10-31 (v2.8.0-rc.2).

- **Motivos**: choca con `agent_orchestrator` como router; ejecuta agentes
  con `--dangerously-skip-permissions`; descarga reglas sin versión fija; no
  cubre Gemini ni Codex.
- **Ideas tomadas** (implementación propia):
  1. Modo Consultivo, bloque obligatorio en los roles (a5f772a).
  2. `standards/_TEMPLATE.md` (a5f772a).
  3. Certificación liviana en `.adf/certifications/` (diseñada en a5f772a,
     integrada en 9dbc64c).
  4. Estado por frente (`.adf/ESTADO.md`).
  5. Comandos para el humano (`## Para ti`: push, tags, merges, deploys).
  6. Temporales en `./tmp/`.
  7. Fichas de módulo (`.adf/modules/`, solo el humano aprueba).
  8. Findings con prueba de regresión (`.adf/findings/`).
  9. Gate veraz con adopción gradual (`adopcion: gradual|estricta`).
- **Descartadas a propósito**: score 0-100, blueprints, dashboard,
  keep-alive, equipo resolutor, certificaciones ISO de IA.

### expo/skills — Pendiente, condicionado a stack

Fuente: github.com/expo/skills. Solo si `mobile-dev` pasa de Flutter a
Expo/React Native.

- **Ideas tomadas** (implementación propia): router con mapa por objetivo,
  descriptions con "No usar para…", "Versión antes de opinar", lint de skills
  con bloque canónico.
- **Si se instala**: solo las skills de framework, sin el bloque de feedback
  (envía contexto a Expo) ni el MCP remoto sin evaluar.

### Otras herramientas evaluadas

| Herramienta | Estado | Notas |
|---|---|---|
| ruflo (ex claude-flow) — github.com/ruvnet/ruflo | Descartado | Redundante con `agent_orchestrator` / `evidence_logger`; la federación entre máquinas es un riesgo innecesario. |
| LightRAG — github.com/HKUDS/LightRAG | No aplica | Infra de aplicación (RAG para usuarios finales), no dev-tooling. |
| n8n-mcp — github.com/czlonkowski/n8n-mcp | Pendiente | Sólido y acotado; sin caso de uso hoy. |
| Archify — github.com/tt-a1i/archify | Pendiente | Diagramas HTML interactivos, complementa graphify. Dudas: no confirma soporte de Gemini CLI; consulta updates cada ~72 h (desactivable con `ARCHIFY_UPDATE_CHECK_DISABLED=1`). Probar primero en un monorepo. |
| Ollama + Continue | Instalado (solo Mac) | Modelos locales para tareas acotadas y código que no debe salir de la máquina; complementan, no reemplazan, a los CLIs de pago. La configuración vive fuera del toolkit. |
