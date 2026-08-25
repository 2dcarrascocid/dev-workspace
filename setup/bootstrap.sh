#!/usr/bin/env bash
# Arma un proyecto nuevo de punta a punta: git init, submodule del dev-toolkit
# (con guardas anti-anidamiento), link.sh, y PROJECT.md/CLAUDE.md/GEMINI.md.
#
# Uso:
#   bash bootstrap.sh <nombre-o-ruta-de-carpeta-del-proyecto>
#
# Guardá este script en un lugar fijo de tu máquina (no depende de estar
# dentro de ningún proyecto) y reusalo cada vez que arranques uno nuevo.

set -e

TOOLKIT_URL="https://github.com/2dcarrascocid/dev-workspace.git"
PROJECT_DIR="$1"

if [ -z "$PROJECT_DIR" ]; then
  echo "Uso: bash bootstrap.sh <nombre-o-ruta-de-carpeta-del-proyecto>"
  exit 1
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "Trabajando en: $(pwd)"

# ---- Guardas anti-anidamiento ----
if [ -d "tools/dev-toolkit" ]; then
  echo "Error: tools/dev-toolkit ya existe acá. Abortando para no anidar."
  echo "Si es un error viejo, limpiá con:"
  echo "  git submodule deinit -f tools/dev-toolkit"
  echo "  git rm -f tools/dev-toolkit"
  echo "  rm -rf .git/modules/tools/dev-toolkit tools/dev-toolkit"
  exit 1
fi

case "$(basename "$(pwd)")" in
  dev-toolkit|dev-workspace)
    echo "Error: estás parado dentro de una carpeta llamada '$(basename "$(pwd)")'."
    echo "Este script debe correr desde la raíz del proyecto NUEVO, no desde"
    echo "adentro del propio toolkit. Cambiá de directorio y reintentá."
    exit 1
    ;;
esac

# ---- Setup real ----
[ -d .git ] || git init

git submodule add "$TOOLKIT_URL" tools/dev-toolkit

# Confirmar que quedó plano (no anidado tools/dev-toolkit/dev-toolkit/)
if [ -d "tools/dev-toolkit/dev-toolkit" ]; then
  echo "Error: el submodule quedó anidado (tools/dev-toolkit/dev-toolkit/)."
  echo "El repo remoto del toolkit tiene un problema de estructura — revisar"
  echo "que agents/, skills/, etc. estén en la RAÍZ de ese repo, no en una"
  echo "subcarpeta."
  exit 1
fi

if [ ! -d "tools/dev-toolkit/agents" ]; then
  echo "Aviso: no se encontró tools/dev-toolkit/agents — algo no bajó bien."
  echo "Revisá con: ls tools/dev-toolkit/"
  exit 1
fi

bash tools/dev-toolkit/setup/link.sh

if [ ! -f PROJECT.md ]; then
  cp tools/dev-toolkit/templates/PROJECT.md.template PROJECT.md
  ln -sf PROJECT.md CLAUDE.md
  ln -sf PROJECT.md GEMINI.md
fi

echo ""
echo "✅ Proyecto '$PROJECT_DIR' listo."
echo ""
echo "Siguiente paso — adentro de una sesión de Claude Code o Gemini CLI,"
echo "parado en esta raíz (nunca dentro de un repo hijo):"
echo ""
echo "  detectá el stack de este proyecto y completá PROJECT.md"
echo ""
echo "(dispara la skill project_bootstrap, que también arma el .gitignore)"
