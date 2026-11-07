#!/usr/bin/env bash
# Pruebas de los checks 7 (standards) y 11 (findings) de setup/check-adf.sh.
# Cada caso arma un toolkit y/o un proyecto mínimo en un directorio temporal
# y compara el estado del check (OK / WARN / FAIL / SKIP) con el esperado.
#
# Uso: bash tests/check-adf/test-standards-findings.sh   (sale 1 si algún caso falla)
# Compatible con bash 3.2, Git Bash y Linux.

ROOT=$(cd "$(dirname "$0")/../.." && pwd -P)
WORK=$(mktemp -d 2>/dev/null || mktemp -d -t adf-test)
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAILS=0

# Copia del toolkit sin .git (el check 13 depende del entorno, no se evalúa acá).
TK="$WORK/toolkit"
mkdir -p "$TK"
(cd "$ROOT" && tar -cf - --exclude=.git --exclude=tmp .) | (cd "$TK" && tar -xf -)

# Estado del check N en la salida: "  <ESTADO>  N. ...".
status_of() { printf '%s\n' "$1" | sed -n "s/^  \([A-Z]*\) *$2\. .*/\1/p" | head -n 1; }

expect() { # $1 descripción, $2 check, $3 esperado, $4 salida
  got=$(status_of "$4" "$2")
  if [ "$got" = "$3" ]; then
    PASS=$((PASS + 1)); echo "ok    $1 (check $2 = $got)"
  else
    FAILS=$((FAILS + 1)); echo "FALLA $1 (check $2: esperado $3, salió ${got:-nada})"
    printf '%s\n' "$4" | sed -n "/^  [A-Z]* *$2\. /,/^  [A-Z]* *$(($2 + 1))\. /p" | sed 's/^/        /'
  fi
}

new_project() { # $1 nombre → imprime la ruta
  p="$WORK/$1"; mkdir -p "$p/standards" "$p/.adf/findings" "$p/test"
  git -C "$p" init -q 2>/dev/null || mkdir -p "$p/.git"
  touch "$p/test/regresion.test.js"
  echo "$p"
}

run() { bash "$TK/setup/check-adf.sh" "$@" 2>&1; }

STD_SECTIONS=$(grep '^## ' "$ROOT/standards/_TEMPLATE.md" | tr -d '\r')

# ---------- check 7 ----------
P_SIN=$(new_project p-sin-secciones)
printf '# Standard sin secciones\n' > "$P_SIN/standards/x.md"
expect "standard sin secciones obligatorias" 7 FAIL "$(run --project "$P_SIN")"

P=$(new_project p-sin-escenarios)
printf '%s\n' "$STD_SECTIONS" | grep -vxF '## Escenarios' > "$P/standards/x.md"
expect "standard completo sin ## Escenarios" 7 WARN "$(run --project "$P")"

P=$(new_project p-completo)
printf '%s\n' "$STD_SECTIONS" > "$P/standards/x.md"
expect "standard con todas las secciones" 7 OK "$(run --project "$P")"

# Standards genéricos del toolkit: Escenarios, prefijo y al menos un ID.
expect "standards genéricos reales del toolkit" 7 OK "$(run)"

printf '%s\n' "$STD_SECTIONS" | grep -vxF '## Escenarios' > "$TK/standards/zz-generico.md"
expect "standard genérico sin ## Escenarios" 7 FAIL "$(run)"

printf '%s\n' "$STD_SECTIONS" > "$TK/standards/zz-generico.md"
expect "standard genérico con Escenarios sin prefijo ni IDs" 7 FAIL "$(run)"

{ printf '%s\n' "$STD_SECTIONS" | sed 's/^## Escenarios$/## Escenarios\
- Prefijo: ZZ\
- **ZZ-01** — dado …, cuando …, entonces …/'; } > "$TK/standards/zz-generico.md"
expect "standard genérico completo con prefijo e IDs" 7 OK "$(run)"
rm -f "$TK/standards/zz-generico.md"

mv "$TK/standards/_TEMPLATE.md" "$WORK/_TEMPLATE.md.bak"
expect "falta la plantilla, sin --project" 7 FAIL "$(run)"
# El caso de la Fase 0 (H1): sin plantilla, un standard sin secciones salía OK.
expect "falta la plantilla con un standard sin secciones (antes salía OK)" 7 FAIL "$(run --project "$P_SIN")"
mv "$WORK/_TEMPLATE.md.bak" "$TK/standards/_TEMPLATE.md"

# ---------- check 11 ----------
finding() { # $1 proyecto, $2 archivo, $3 frontmatter extra
  {
    echo "---"; printf '%s\n' "$3"
    echo "task_id: T-1"; echo "prueba_regresion: test/regresion.test.js"; echo "candidato_standard: no"
    echo "---"; echo "# Bug"; echo "## Síntoma"; echo "## Causa raíz"; echo "## Corrección"
  } > "$1/.adf/findings/$2"
}
FND_BASE='descripcion: algo falla
severidad: medium'

P=$(new_project p-fnd-ok)
finding "$P" FND-001.md "id: FND-001
$FND_BASE
status: resolved
test_result: \"npm test — falla antes: sí, pasa después: sí\"
motivo: null"
expect "FND resolved con test_result" 11 OK "$(run --project "$P")"

P=$(new_project p-fnd-sin-test)
finding "$P" FND-001.md "id: FND-001
$FND_BASE
status: resolved
test_result: null"
expect "FND resolved sin test_result" 11 FAIL "$(run --project "$P")"

P=$(new_project p-fnd-wontfix)
finding "$P" FND-002.md "id: FND-002
$FND_BASE
status: wontfix
motivo: null"
expect "FND wontfix sin motivo" 11 FAIL "$(run --project "$P")"

P=$(new_project p-fnd-sin-status)
finding "$P" FND-003.md "id: FND-003
$FND_BASE"
expect "FND sin status" 11 FAIL "$(run --project "$P")"

P=$(new_project p-legado)
finding "$P" F-20260101-120000.md "id: F-20260101-120000"
expect "finding legado F- sin campos nuevos" 11 OK "$(run --project "$P")"

P=$(new_project p-id-invalido)
finding "$P" X-1.md "id: X-1
$FND_BASE
status: open"
expect "id con formato inválido" 11 FAIL "$(run --project "$P")"

echo ""
echo "Resultado: $PASS ok, $FAILS con falla"
[ "$FAILS" -eq 0 ]
