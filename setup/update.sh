#!/usr/bin/env bash
# Actualiza el dev-toolkit dentro de un proyecto que lo tiene clonado
# (no-submodule) en tools/dev-toolkit. Correr desde la raíz del proyecto.

set -e

if [ ! -d "tools/dev-toolkit" ]; then
  echo "Error: no se encontró tools/dev-toolkit. Corré esto desde la raíz del proyecto."
  exit 1
fi

cd tools/dev-toolkit
git pull origin main
cd - > /dev/null

bash tools/dev-toolkit/setup/link.sh

bash tools/dev-toolkit/setup/check-global-tools.sh

echo ""
echo "✅ dev-toolkit actualizado."
