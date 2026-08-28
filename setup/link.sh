#!/usr/bin/env bash
# Instala el dev-toolkit en el proyecto actual: symlinks para Claude Code,
# Gemini CLI y Codex CLI, + archivos de contexto (CLAUDE.md/GEMINI.md/AGENTS.md).
# Se auto-verifica: si un symlink no se crea de verdad (típico en Windows sin
# Modo Desarrollador), lo detecta y te avisa en vez de fallar en silencio.
#
# Correr desde la raíz del proyecto, con tools/dev-toolkit ya presente
# (clonado o como submodule).

set -e

TOOLKIT_DIR="tools/dev-toolkit"
FAILED_LINKS=()

if [ ! -d "$TOOLKIT_DIR" ]; then
  echo "Error: no se encontró $TOOLKIT_DIR."
  exit 1
fi

bash "$TOOLKIT_DIR/agents/build.sh"

verify_link() {
  # $1 = path que debería ser symlink
  if [ ! -L "$1" ]; then
    FAILED_LINKS+=("$1")
  fi
}

# ---------- Claude Code ----------
mkdir -p .claude/agents .claude/skills .claude/commands .claude/evidence
ln -sfn "../../$TOOLKIT_DIR/agents/dist/claude" .claude/agents/base
verify_link ".claude/agents/base"
ln -sfn "../../$TOOLKIT_DIR/skills" .claude/skills/base
verify_link ".claude/skills/base"
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
verify_link ".gemini/skills/base"

# ---------- Codex CLI (OpenAI) ----------
mkdir -p .codex/skills .codex/skills/local
ln -sfn "../../$TOOLKIT_DIR/skills" .codex/skills/base
verify_link ".codex/skills/base"
for d in "$TOOLKIT_DIR"/agents/dist/codex/*/; do
  role=$(basename "$d")
  ln -sfn "../../$d" ".codex/skills/$role"
done

# ---------- Contexto del proyecto (siempre, no solo en bootstrap) ----------
if [ ! -f PROJECT.md ]; then
  cp "$TOOLKIT_DIR/templates/PROJECT.md.template" PROJECT.md
fi
ln -sf PROJECT.md CLAUDE.md
ln -sf PROJECT.md GEMINI.md
ln -sf PROJECT.md AGENTS.md

echo "Listo. Estructura:"
echo "  .claude/agents/base    -> agents/dist/claude/ (genérico, actualizable)"
echo "  .claude/skills/base    -> skills/ (genérico, actualizable)"
echo "  .claude/commands/*.md  -> commands/*.md (solo Claude Code)"
echo "  .gemini/agents/*.md    -> agents/dist/gemini/*.md (uno por uno)"
echo "  .gemini/skills/base    -> skills/ (mismas skills, mismo formato)"
echo "  .codex/skills/base     -> skills/ (mismas skills, mismo formato)"
echo "  .codex/skills/<rol>    -> los 5 roles ADF, expuestos como skills"
echo "  CLAUDE.md, GEMINI.md, AGENTS.md -> symlinks a PROJECT.md"
echo "  */agents/local, */skills/local -> específicos de este proyecto"
echo ""

if [ ${#FAILED_LINKS[@]} -gt 0 ]; then
  echo "⚠️  ATENCIÓN: estos symlinks NO se crearon como symlinks reales"
  echo "   (probablemente quedaron como carpetas vacías):"
  for f in "${FAILED_LINKS[@]}"; do
    echo "     - $f"
  done
  echo ""
  echo "   En Windows, esto pasa sin el Modo Desarrollador activo:"
  echo "   Configuración → Privacidad y seguridad → Para desarrolladores"
  echo "   → activar 'Modo de desarrollador' → cerrar y reabrir la terminal"
  echo "   → volver a correr este script."
else
  echo "✅ Todos los symlinks se verificaron correctamente."
fi

TOOLKIT_VERSION=$(git -C "$TOOLKIT_DIR" rev-parse --short HEAD 2>/dev/null || echo "desconocida")
TOOLKIT_DATE=$(git -C "$TOOLKIT_DIR" log -1 --format=%cd --date=short 2>/dev/null || echo "?")
echo ""
echo "Versión del toolkit instalada: $TOOLKIT_VERSION ($TOOLKIT_DATE)"

bash "$TOOLKIT_DIR/setup/check-global-tools.sh"
