#!/usr/bin/env bash
# Arma un proyecto nuevo de punta a punta: clona el dev-toolkit (sin
# submodule, sin necesitar que la carpeta padre sea un repo git), corre
# link.sh, y crea PROJECT.md/CLAUDE.md/GEMINI.md.
#
# La carpeta padre (ej. superliga/) NO necesita git ni remoto — solo
# tools/dev-toolkit adentro es, en sí mismo, un repo clonado normal.
#
# Uso:
#   bash bootstrap.sh <nombre-o-ruta-de-carpeta-del-proyecto>

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
  echo "Si es de un intento anterior, borralo primero:"
  echo "  rm -rf tools/dev-toolkit"
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

# ---- Clonar el toolkit (repo propio, NO submodule) ----
mkdir -p tools
git clone "$TOOLKIT_URL" tools/dev-toolkit

if [ ! -d "tools/dev-toolkit/agents" ]; then
  echo "Aviso: no se encontró tools/dev-toolkit/agents — algo no bajó bien."
  echo "Revisá con: ls tools/dev-toolkit/"
  exit 1
fi

bash tools/dev-toolkit/setup/link.sh

bash tools/dev-toolkit/setup/check-global-tools.sh

if [ ! -f PROJECT.md ]; then
  cp tools/dev-toolkit/templates/PROJECT.md.template PROJECT.md
  ln -sf PROJECT.md CLAUDE.md
  ln -sf PROJECT.md GEMINI.md
  ln -sf PROJECT.md AGENTS.md
fi

echo ""
echo "✅ Proyecto '$PROJECT_DIR' listo — 100% local, sin git en la raíz."
echo ""
echo "Para actualizar el toolkit más adelante:"
echo "  bash tools/dev-toolkit/setup/update.sh"
echo ""
echo "Siguiente paso — adentro de una sesión de Claude Code o Gemini CLI,"
echo "parado en esta raíz (nunca dentro de un repo hijo):"
echo ""
echo "  detectá el stack de este proyecto y completá PROJECT.md"
