#!/usr/bin/env bash
# Verifica si las herramientas globales de CATALOG.md (Tipo B: instalador
# propio) están instaladas en esta máquina. No instala nada automáticamente
# — solo reporta qué falta y el comando exacto para instalarlo.

echo ""
echo "🔍 Verificando herramientas globales (Tipo B, según CATALOG.md)..."
echo ""

check_tool() {
  local name="$1"
  local claude_path="$HOME/.claude/skills/$2"
  local gemini_path="$HOME/.gemini/skills/$2"
  local install_cmd="$3"

  if [ -d "$claude_path" ] || [ -d "$gemini_path" ]; then
    echo "  ✅ $name — instalado"
  else
    echo "  ⚠️  $name — no encontrado"
    echo "      Instalar con: $install_cmd"
  fi
}

check_tool "graphify" "graphify" "uv tool install graphifyy && graphify install && graphify gemini install"
check_tool "ui-ux-pro-max" "ui-ux-pro-max" "npm install -g ui-ux-pro-max-cli && uipro init --ai claude --global && uipro init --ai gemini --global"

echo ""
echo "Si falta alguna y la usás seguido, instalala una sola vez por máquina"
echo "(quedan disponibles en todos los proyectos, no son parte del toolkit)."
echo "Ver skills/CATALOG.md para agregar herramientas nuevas a este chequeo."
