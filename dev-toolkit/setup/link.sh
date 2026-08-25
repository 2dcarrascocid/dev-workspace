#!/usr/bin/env bash
# Instala el dev-toolkit en el proyecto actual vía symlinks, para Claude Code
# Y Gemini CLI a la vez.
#
# Correr desde la raíz del proyecto, después de agregar el submodule:
#   git submodule add <url> tools/dev-toolkit
#   bash tools/dev-toolkit/setup/link.sh

set -e

TOOLKIT_DIR="tools/dev-toolkit"

if [ ! -d "$TOOLKIT_DIR" ]; then
  echo "Error: no se encontró $TOOLKIT_DIR. Agregá primero el submodule."
  exit 1
fi

bash "$TOOLKIT_DIR/agents/build.sh"

# ---------- Claude Code ----------
mkdir -p .claude/agents .claude/skills .claude/commands .claude/evidence
ln -sfn "../../$TOOLKIT_DIR/agents/dist/claude" .claude/agents/base
ln -sfn "../../$TOOLKIT_DIR/skills" .claude/skills/base
mkdir -p .claude/agents/local .claude/skills/local
for f in "$TOOLKIT_DIR"/commands/*.md; do
  ln -sfn "../../$f" ".claude/commands/$(basename "$f")"
done

# ---------- Gemini CLI ----------
mkdir -p .gemini/agents .gemini/skills .gemini/agents/local .gemini/skills/local
for f in "$TOOLKIT_DIR"/agents/dist/gemini/*.md; do
  ln -sfn "../../$f" ".gemini/agents/$(basename "$f")"
done
ln -sfn "../../$TOOLKIT_DIR/skills" .gemini/skills/base

echo "Listo. Estructura:"
echo "  .claude/agents/base    -> agents/dist/claude/ (genérico, actualizable)"
echo "  .claude/skills/base    -> skills/ (genérico, actualizable)"
echo "  .claude/commands/*.md  -> commands/*.md (solo Claude Code)"
echo "  .gemini/agents/*.md    -> agents/dist/gemini/*.md (uno por uno)"
echo "  .gemini/skills/base    -> skills/ (mismas skills, mismo formato)"
echo "  */agents/local, */skills/local -> específicos de este proyecto"
echo ""
echo "Siguiente paso: crear el archivo de contexto del proyecto"
echo "  cp $TOOLKIT_DIR/templates/PROJECT.md.template PROJECT.md"
echo "  ln -s PROJECT.md CLAUDE.md"
echo "  ln -s PROJECT.md GEMINI.md"
echo ""
echo "O pedile directamente al agente: 'detectá el stack de este proyecto"
echo "y completá PROJECT.md' — dispara la skill project_bootstrap."
