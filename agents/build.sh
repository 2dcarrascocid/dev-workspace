#!/usr/bin/env bash
# Genera los agentes/skills finales combinando cuerpo (shared/, provider-agnostic)
# + frontmatter (frontmatter/<provider>/, específico de cada CLI).
# Correr desde la raíz del repo dev-toolkit cada vez que edites shared/ o
# frontmatter/, y commitear el resultado en dist/.

set -e
cd "$(dirname "$0")"

# Claude y Gemini: subagentes, un archivo .md por rol
for provider in claude gemini; do
  mkdir -p "dist/$provider"
  for body in shared/*.md; do
    name=$(basename "$body")
    fm="frontmatter/$provider/$name"
    if [ ! -f "$fm" ]; then
      echo "Aviso: falta frontmatter/$provider/$name, se omite."
      continue
    fi
    cat "$fm" "$body" > "dist/$provider/$name"
  done
done

# Codex: skills (SKILL.md), un directorio por rol (requisito del formato)
mkdir -p dist/codex
for body in shared/*.md; do
  name=$(basename "$body" .md)
  fm="frontmatter/codex/$name.md"
  if [ ! -f "$fm" ]; then
    echo "Aviso: falta frontmatter/codex/$name.md, se omite."
    continue
  fi
  mkdir -p "dist/codex/$name"
  cat "$fm" "shared/$name.md" > "dist/codex/$name/SKILL.md"
done

echo "Generado: agents/dist/claude/*.md, agents/dist/gemini/*.md, agents/dist/codex/*/SKILL.md"
