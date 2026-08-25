#!/usr/bin/env bash
# Genera los agentes finales combinando cuerpo (shared/, provider-agnostic)
# + frontmatter (frontmatter/<provider>/, específico de cada CLI).
# Correr desde la raíz del repo dev-toolkit cada vez que edites shared/ o
# frontmatter/, y commitear el resultado en dist/.

set -e
cd "$(dirname "$0")"

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

echo "Generado: agents/dist/claude/*.md y agents/dist/gemini/*.md"
