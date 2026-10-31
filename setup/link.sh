#!/usr/bin/env bash
# Instala el dev-toolkit en el proyecto actual: symlinks para Claude Code,
# Gemini CLI, Codex CLI, GitHub Copilot y OpenCode, + archivos de contexto
# (CLAUDE.md/GEMINI.md/AGENTS.md).
# Se auto-verifica: si un symlink no se crea de verdad (típico en Windows sin
# Modo Desarrollador), lo detecta y te avisa en vez de fallar en silencio.
#
# Correr desde la raíz del proyecto, con tools/dev-toolkit ya presente
# (clonado o como submodule).

set -e

# En Git Bash / MSYS / Cygwin, sin winsymlinks:nativestrict `ln -s` copia en
# vez de enlazar y el script queda a medias: se corta antes de crear nada.
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    case "${MSYS:-}" in
      *winsymlinks:nativestrict*) ;;
      *)
        echo "Error: falta MSYS=winsymlinks:nativestrict (sin eso ln -s copia en vez de enlazar)."
        echo "  1. Agregá a ~/.bashrc:  export MSYS=winsymlinks:nativestrict"
        echo "  2. Activá el Modo Desarrollador: Configuración → Privacidad y seguridad"
        echo "     → Para desarrolladores → 'Modo de desarrollador'."
        echo "  3. Cerrá y reabrí la terminal y volvé a correr este script."
        echo "No se creó ni modificó nada."
        exit 1
        ;;
    esac
    ;;
esac

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

# ---------- GitHub Copilot (VS Code Chat, Copilot CLI, coding agent) ----------
# Skills una por una: Copilot espera .github/skills/<nombre>/SKILL.md directo.
mkdir -p .github/agents .github/skills .github/prompts .github/skills/local
for f in "$TOOLKIT_DIR"/agents/dist/copilot/*.agent.md; do
  ln -sfn "../../$f" ".github/agents/$(basename "$f")"
done
for d in "$TOOLKIT_DIR"/skills/*/; do
  skill=$(basename "$d")
  ln -sfn "../../$TOOLKIT_DIR/skills/$skill" ".github/skills/$skill"
  verify_link ".github/skills/$skill"
done
for f in "$TOOLKIT_DIR"/commands/copilot/*.prompt.md; do
  ln -sfn "../../$f" ".github/prompts/$(basename "$f")"
done

# ---------- OpenCode ----------
mkdir -p .opencode/agents .opencode/skills .opencode/commands .opencode/skills/local
for f in "$TOOLKIT_DIR"/agents/dist/opencode/*.md; do
  ln -sfn "../../$f" ".opencode/agents/$(basename "$f")"
done
for d in "$TOOLKIT_DIR"/skills/*/; do
  skill=$(basename "$d")
  ln -sfn "../../$TOOLKIT_DIR/skills/$skill" ".opencode/skills/$skill"
  verify_link ".opencode/skills/$skill"
done
for f in "$TOOLKIT_DIR"/commands/*.md; do
  [ "$(basename "$f")" = "README.md" ] && continue
  ln -sfn "../../$f" ".opencode/commands/$(basename "$f")"
done

# ---------- Skills locales del proyecto (skills/local/<x>/) ----------
# Solo Claude, Gemini y Codex: Copilot y OpenCode quedan pendientes hasta
# verificar que detectan skills a 2 niveles. Nunca pisa lo existente ni borra
# symlinks colgantes: solo avisa (check-adf.sh --project los marca).
LOCAL_WARNINGS=()
for c in .claude .gemini .codex; do
  for d in skills/local/*/; do
    [ -f "${d}SKILL.md" ] || continue
    skill=$(basename "$d")
    dest="$c/skills/local/$skill"
    target="../../../skills/local/$skill"
    if [ -L "$dest" ]; then
      [ "$(readlink "$dest")" = "$target" ] \
        || LOCAL_WARNINGS+=("$dest: symlink a otro destino ($(readlink "$dest")), no se tocó")
      continue
    fi
    if [ -e "$dest" ]; then
      LOCAL_WARNINGS+=("$dest: ya existe como carpeta/archivo real, no se tocó")
      continue
    fi
    ln -sfn "$target" "$dest"
    verify_link "$dest"
  done
  for e in "$c"/skills/local/*; do
    if [ -L "$e" ] && [ ! -e "$e" ]; then
      LOCAL_WARNINGS+=("$e: symlink colgante (la skill ya no existe en la fuente), no se borró")
    fi
  done
done

# ---------- Contexto del proyecto (siempre, no solo en bootstrap) ----------
if [ ! -f PROJECT.md ]; then
  cp "$TOOLKIT_DIR/templates/PROJECT.md.template" PROJECT.md
fi
ln -sf PROJECT.md CLAUDE.md
ln -sf PROJECT.md GEMINI.md
ln -sf PROJECT.md AGENTS.md

# ---------- Estado por frente (.adf/ESTADO.md) ----------
# Igual que PROJECT.md: se copia de la plantilla solo si no existe uno.
ESTADO_NUEVO=0
if [ ! -f .adf/ESTADO.md ] && [ ! -f ESTADO.md ]; then
  mkdir -p .adf
  cp "$TOOLKIT_DIR/templates/ESTADO.md.template" .adf/ESTADO.md
  ESTADO_NUEVO=1
fi

echo "Listo. Estructura:"
echo "  .claude/agents/base    -> agents/dist/claude/ (genérico, actualizable)"
echo "  .claude/skills/base    -> skills/ (genérico, actualizable)"
echo "  .claude/commands/*.md  -> commands/*.md (solo Claude Code)"
echo "  .gemini/agents/*.md    -> agents/dist/gemini/*.md (uno por uno)"
echo "  .gemini/skills/base    -> skills/ (mismas skills, mismo formato)"
echo "  .codex/skills/base     -> skills/ (mismas skills, mismo formato)"
echo "  .codex/skills/<rol>    -> los roles ADF, expuestos como skills"
echo "  .github/agents/*.agent.md -> agents/dist/copilot/ (Copilot custom agents)"
echo "  .github/skills/<skill>  -> skills/<skill> (una por una)"
echo "  .github/prompts/*.prompt.md -> commands/copilot/ (/new-task en Copilot Chat)"
echo "  .opencode/agents/*.md   -> agents/dist/opencode/ (subagentes OpenCode)"
echo "  .opencode/skills/<skill> -> skills/<skill> (una por una)"
echo "  .opencode/commands/*.md -> commands/*.md (/new-task en OpenCode)"
echo "  CLAUDE.md, GEMINI.md, AGENTS.md -> symlinks a PROJECT.md"
echo "  .adf/ESTADO.md         -> estado por frente (lo mantiene agent_orchestrator)"
echo "  (Copilot y OpenCode leen AGENTS.md como contexto del proyecto)"
echo "  */agents/local, */skills/local -> específicos de este proyecto"
echo "  .{claude,gemini,codex}/skills/local/<x> -> skills/local/<x> (fuente local)"
echo ""

if [ ${#LOCAL_WARNINGS[@]} -gt 0 ]; then
  echo "⚠️  Skills locales sin enlazar o desfasadas (revisar a mano):"
  for w in "${LOCAL_WARNINGS[@]}"; do
    echo "     - $w"
  done
  echo ""
fi

if [ "$ESTADO_NUEVO" -eq 1 ] && ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ℹ️  La raíz no es un repo git (topología B): .adf/ESTADO.md queda local"
  echo "   y no se sincroniza entre máquinas."
  echo ""
fi

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
