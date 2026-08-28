#!/usr/bin/env bash
# Verifica si las herramientas globales de CATALOG.md (Tipo B: instalador
# propio) están instaladas en esta máquina. No instala nada automáticamente
# — solo reporta qué falta y el comando exacto para instalarlo.
#
# Busca en $HOME (Mac/Linux nativo, o Windows si corrés desde PowerShell/Git
# Bash con el mismo usuario) y, si detecta que está corriendo dentro de WSL,
# también busca en /mnt/c/Users/*/ — porque el usuario de Linux dentro de WSL
# suele ser distinto al usuario de Windows, y ahí es donde instalan los CLIs
# nativos de Windows (PowerShell) sus skills.

echo ""
echo "🔍 Verificando herramientas globales (Tipo B, según CATALOG.md)..."
echo ""

is_wsl() {
  grep -qi microsoft /proc/version 2>/dev/null
}

check_tool() {
  local name="$1"
  local skill_dir="$2"
  local install_cmd="$3"
  local found=""

  for base in "$HOME/.claude/skills" "$HOME/.gemini/skills" "$HOME/.agents/skills"; do
    [ -d "$base/$skill_dir" ] && found="$base/$skill_dir"
  done

  if [ -z "$found" ] && is_wsl; then
    for match in /mnt/c/Users/*/.claude/skills/"$skill_dir" \
                 /mnt/c/Users/*/.gemini/skills/"$skill_dir" \
                 /mnt/c/Users/*/.agents/skills/"$skill_dir"; do
      [ -d "$match" ] && found="$match" && break
    done
  fi

  if [ -n "$found" ]; then
    echo "  ✅ $name — instalado ($found)"
  else
    echo "  ⚠️  $name — no encontrado"
    echo "      Instalar con: $install_cmd"
  fi
}

check_tool "graphify" "graphify" "uv tool install graphifyy && graphify install && graphify gemini install && graphify codex install"
check_tool "ui-ux-pro-max" "ui-ux-pro-max" "npm install -g ui-ux-pro-max-cli && uipro init --ai claude --global && uipro init --ai gemini --global"

echo ""
echo "Si falta alguna y la usás seguido, instalala una sola vez por máquina"
echo "(quedan disponibles en todos los proyectos, no son parte del toolkit)."
echo "Ver skills/CATALOG.md para agregar herramientas nuevas a este chequeo."
