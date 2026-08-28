#!/usr/bin/env bash
# Arma un proyecto nuevo de punta a punta: clona el dev-toolkit (sin
# submodule, sin necesitar que la carpeta padre sea un repo git) y corre
# link.sh (que se encarga de symlinks, PROJECT.md/CLAUDE.md/GEMINI.md/AGENTS.md,
# verificación, y chequeo de herramientas globales).
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
  echo "Si es de un intento anterior, borralo primero: rm -rf tools/dev-toolkit"
  exit 1
fi

case "$(basename "$(pwd)")" in
  dev-toolkit|dev-workspace)
    echo "Error: estás parado dentro de una carpeta llamada '$(basename "$(pwd)")'."
    echo "Este script debe correr desde la raíz del proyecto NUEVO."
    exit 1
    ;;
esac

# ---- Clonar el toolkit (repo propio, NO submodule) ----
mkdir -p tools
git clone "$TOOLKIT_URL" tools/dev-toolkit

if [ ! -d "tools/dev-toolkit/agents" ]; then
  echo "Aviso: no se encontró tools/dev-toolkit/agents — algo no bajó bien."
  exit 1
fi

bash tools/dev-toolkit/setup/link.sh

echo ""
echo "✅ Proyecto '$PROJECT_DIR' listo — 100% local, sin git en la raíz."
echo ""
echo "Para actualizar el toolkit más adelante:"
echo "  bash tools/dev-toolkit/setup/update.sh"
