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
