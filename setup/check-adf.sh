#!/usr/bin/env bash
# Lint del toolkit ADF: verifica skills, agentes, frontmatters, dist/ y el
# router de agent_orchestrator. Imprime OK / WARN / FAIL / SKIP por check y
# sale con código 1 si algún check falla (WARN no hace fallar).
#
# Uso:
#   bash setup/check-adf.sh [--fix] [--project <ruta>] [--deny-file <ruta>]
#
#   --fix              corrige lo corregible (bloque de Modo Consultivo, dist/)
#   --project <ruta>   revisa además skills locales, standards/ y .adf/ (fichas, findings, ESTADO.md)
#   --deny-file <ruta> términos prohibidos (uno por línea, # = comentario) que
#                      no pueden aparecer en lo versionado del toolkit. Nunca
#                      vive dentro del toolkit (ej. <proyecto>/local/adf-deny.txt)
#
# Compatible con bash 3.2 (macOS), Git Bash y Linux: sin arrays asociativos,
# sin sed -i, sin dependencias fuera de git/awk/sed/grep.

ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
FIX=0
PROJECT=""
DENY_FILE=""
PROVIDERS="claude gemini codex copilot opencode"
BLOCK="$ROOT/agents/shared/_blocks/modo-consultivo.md"
MARK_START="<!-- adf:modo-consultivo:start -->"
MARK_END="<!-- adf:modo-consultivo:end -->"

usage() {
  sed -n '5,13p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fix) FIX=1 ;;
    --project)
      [ -n "$2" ] || { echo "Error: --project requiere una ruta."; exit 2; }
      PROJECT="$2"; shift ;;
    --deny-file)
      [ -n "$2" ] || { echo "Error: --deny-file requiere una ruta."; exit 2; }
      DENY_FILE="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: argumento desconocido '$1'."; usage; exit 2 ;;
  esac
  shift
done

if [ -n "$PROJECT" ]; then
  [ -d "$PROJECT" ] || { echo "Error: no existe el proyecto '$PROJECT'."; exit 2; }
  PROJECT=$(cd "$PROJECT" && pwd -P)
fi

IS_GIT=0
git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 && IS_GIT=1

# Los loops recorren listas de rutas (una por línea): con IFS = salto de
# línea, las rutas con espacios no se parten.
NL='
'
IFS=$NL
PROVIDERS=$(echo "$PROVIDERS" | tr ' ' '\n')
TMPD=$(mktemp -d 2>/dev/null || mktemp -d -t adf-lint)
trap 'rm -rf "$TMPD"' EXIT

TOTAL_OK=0; TOTAL_WARN=0; TOTAL_FAIL=0; TOTAL_SKIP=0

# ---------- helpers de reporte ----------
# Cada check llama a begin_check, después fail/warn/note por hallazgo, y
# end_check imprime el estado y el detalle acumulado.
begin_check() {
  CHECK_NAME="$1"; C_FAIL=0; C_WARN=0; C_SKIP=0; DETAIL=""
}
add_line() { DETAIL="$DETAIL
      $1"; }
fail() { C_FAIL=$((C_FAIL + 1)); add_line "FAIL  $1"; }
warn() { C_WARN=$((C_WARN + 1)); add_line "WARN  $1"; }
note() { add_line "$1"; }
skip() { C_SKIP=1; add_line "$1"; }
end_check() {
  if [ "$C_FAIL" -gt 0 ]; then status="FAIL"; TOTAL_FAIL=$((TOTAL_FAIL + 1))
  elif [ "$C_SKIP" -gt 0 ]; then status="SKIP"; TOTAL_SKIP=$((TOTAL_SKIP + 1))
  elif [ "$C_WARN" -gt 0 ]; then status="WARN"; TOTAL_WARN=$((TOTAL_WARN + 1))
  else status="OK"; TOTAL_OK=$((TOTAL_OK + 1))
  fi
  printf '  %-4s  %s' "$status" "$CHECK_NAME"
  [ -n "$DETAIL" ] && printf '%s' "$DETAIL"
  printf '\n'
}

rel() {
  case "$1" in
    "$ROOT"/*) echo "${1#$ROOT/}" ;;
    "$PROJECT"/*) [ -n "$PROJECT" ] && echo "proyecto:${1#$PROJECT/}" || echo "$1" ;;
    *) echo "$1" ;;
  esac
}

# Ruta real de un directorio, resolviendo symlinks (bash 3.2: sin realpath).
real_dir() { (cd -P "$1" 2>/dev/null && pwd); }

# Primer valor de un campo del frontmatter YAML (soporta `>` / `|` multilínea).
fm_field() {
  awk -v key="$2" -v q="'" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    /^---$/ { exit }
    ml && /^[ \t]+/ { s = $0; sub(/^[ \t]+/, "", s); v = (v == "" ? s : v " " s); next }
    ml { ml = 0; print v; done = 1 }
    !done && index($0, key ":") == 1 {
      v = substr($0, length(key) + 2); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      if (v ~ /^[>|][-+]?$/) { ml = 1; v = ""; next }
      gsub("^[\"" q "]|[\"" q "]$", "", v); print v; done = 1
    }
    END { if (ml) print v }
  ' "$1"
}

# fm_field sin el comentario final (`valor   # comentario`).
fm_value() { fm_field "$1" "$2" | sed 's/[[:space:]]#.*$//; s/[[:space:]]*$//'; }

# 0 si el frontmatter abre en la línea 1 y cierra con otro `---`.
has_frontmatter() {
  awk '{ sub(/\r$/, "") } NR == 1 && $0 != "---" { exit 1 } NR > 1 && $0 == "---" { ok = 1; exit } END { exit !ok }' "$1"
}

# 0 si el frontmatter tiene la clave (aunque su valor esté vacío).
fm_has() {
  awk -v key="$2" '{ sub(/\r$/, "") } NR == 1 { next } /^---$/ { exit } index($0, key ":") == 1 { f = 1; exit } END { exit !f }' "$1"
}

# Ítems de una lista del frontmatter, uno por línea: `key:` + `  - item`
# o `key: [a, b]`.
fm_list() {
  awk -v key="$2" -v q="'" '
    function clean(s) { sub(/[ \t]+#.*$/, "", s); gsub("^[ \t\"" q "]+|[ \t\"" q "]+$", "", s); return s }
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; next }
    /^---$/ { exit }
    inl && /^[ \t]*- / { s = $0; sub(/^[ \t]*- /, "", s); s = clean(s); if (s != "") print s; next }
    inl && /^[^ \t]/ { inl = 0 }
    index($0, key ":") == 1 {
      v = clean(substr($0, length(key) + 2))
      if (v == "") { inl = 1; next }
      if (v ~ /^\[/) {
        gsub(/[][]/, "", v); n = split(v, a, ",")
        for (i = 1; i <= n; i++) { x = clean(a[i]); if (x != "") print x }
      }
    }
  ' "$1"
}

# 0 si la ruta (relativa a $1; puede tener comodines) existe.
path_exists() {
  case "$2" in
    *'*'*|*'?'*) for m in "$1"/$2; do [ -e "$m" ] && return 0; done; return 1 ;;
    *) [ -e "$1/$2" ] ;;
  esac
}

# Carpetas .adf/ del proyecto: la de la raíz y la de cada repo hijo de primer
# nivel (topología B). Imprime "<raíz del repo>" por línea.
adf_repos() {
  [ -d "$PROJECT/.adf" ] && echo "$PROJECT"
  for d in "$PROJECT"/*/; do
    [ -e "$d.git" ] && [ -d "$d.adf" ] && echo "${d%/}"
  done
}

# Líneas del cuerpo (después del frontmatter; si no hay frontmatter, todo).
body_lines() {
  awk '
    { sub(/\r$/, "") }
    NR == 1 && $0 == "---" { fm = 1; next }
    fm == 1 && $0 == "---" { fm = 2; next }
    fm != 1 { n++ }
    END { print n + 0 }
  ' "$1"
}

LOCAL_CLI_DIRS=".claude
.gemini
.codex
.github
.opencode"

# Directorios candidatos a skill: los del toolkit y, con --project, los
# locales (skills/local/ y cada .<cli>/skills/local/).
skill_dirs() {
  for d in "$ROOT"/skills/*/; do echo "$d"; done
  if [ -n "$PROJECT" ]; then
    for d in "$PROJECT"/skills/local/*/; do echo "$d"; done
    for c in $LOCAL_CLI_DIRS; do
      for d in "$PROJECT/$c"/skills/local/*/; do echo "$d"; done
    done
  fi
}

# SKILL.md a revisar, una sola vez por skill: se resuelve la ruta real
# (symlinks incluidos) y se descartan las repetidas.
skill_files() {
  seen=$NL
  for d in $(skill_dirs); do
    [ -d "$d" ] || continue
    r=$(real_dir "$d") || continue
    case "$seen" in *"$NL$r$NL"*) continue ;; esac
    seen="$seen$r$NL"
    [ -f "$r/SKILL.md" ] && echo "$r/SKILL.md"
  done
}

roles() {
  for f in "$ROOT"/agents/shared/*.md; do [ -f "$f" ] && basename "$f" .md; done
}

echo ""
echo "ADF lint — toolkit: $ROOT"
[ -n "$PROJECT" ] && echo "            proyecto: $PROJECT"
[ "$FIX" -eq 1 ] && echo "            modo: --fix"
echo ""

# ---------- 1. Frontmatter de skills ----------
begin_check "1. Frontmatter de skills (name = carpeta, description ≤ 1024)"
for f in $(skill_files); do
  dir=$(basename "$(dirname "$f")")
  where=$(rel "$f")
  if [ "$(head -n 1 "$f" | tr -d '\r')" != "---" ]; then
    fail "$where: no empieza con '---' (sin frontmatter)"
    continue
  fi
  name=$(fm_field "$f" name)
  desc=$(fm_field "$f" description)
  [ "$name" = "$dir" ] || fail "$where: name '$name' distinto de la carpeta '$dir'"
  if [ -z "$desc" ]; then
    fail "$where: description vacía o ausente"
  else
    # wc -m cuenta caracteres solo con un locale UTF-8; sin él (ej. Git Bash
    # con LANG vacío) cuenta bytes y cada acento suma 2. El error es siempre
    # hacia el lado seguro: puede dar un FAIL de más cerca del límite, nunca
    # dejar pasar una description demasiado larga.
    len=$(printf '%s' "$desc" | wc -m | tr -d ' ')
    [ "$len" -le 1024 ] || fail "$where: description de $len caracteres (máx. 1024)"
  fi
done
# Enlaces de skills locales por CLI: cada entrada de .<cli>/skills/local/
# debería ser un symlink a la fuente. Carpetas vacías o inexistentes se ignoran.
if [ -n "$PROJECT" ]; then
  for c in $LOCAL_CLI_DIRS; do
    ldir="$PROJECT/$c/skills/local"
    [ -d "$ldir" ] || continue
    for e in "$ldir"/*; do
      [ -e "$e" ] || [ -L "$e" ] || continue
      where=$(rel "$e")
      if [ -L "$e" ]; then
        if [ ! -e "$e" ]; then
          fail "$where: symlink roto"
        elif [ ! -f "$e/SKILL.md" ]; then
          fail "$where: el symlink resuelve a $(rel "$(real_dir "$e")"), que no tiene SKILL.md"
        fi
      elif [ -d "$e" ]; then
        warn "$where: skill copiada en vez de enlazada, revisar MSYS/Modo Desarrollador y re-ejecutar link.sh"
      fi
    done
  done
fi
end_check

# ---------- 2. Tamaño ----------
begin_check "2. Tamaño (SKILL.md ≤ 200 recomendado / ≤ 500 máx.; agentes ≤ 200)"
for f in $(skill_files); do
  n=$(body_lines "$f")
  if [ "$n" -gt 500 ]; then fail "$(rel "$f"): cuerpo de $n líneas (máx. 500)"
  elif [ "$n" -gt 200 ]; then warn "$(rel "$f"): cuerpo de $n líneas (recomendado ≤ 200)"
  fi
done
for role in $(roles); do
  f="$ROOT/agents/shared/$role.md"
  n=$(wc -l < "$f" | tr -d ' ')
  [ "$n" -le 200 ] || warn "$(rel "$f"): $n líneas (recomendado ≤ 200)"
done
end_check

# ---------- 3. Bloque canónico de Modo Consultivo ----------
begin_check "3. Bloque canónico de Modo Consultivo (_blocks/modo-consultivo.md)"
if [ ! -f "$BLOCK" ]; then
  fail "$(rel "$BLOCK"): no existe la fuente del bloque"
else
  for role in $(roles); do
    f="$ROOT/agents/shared/$role.md"
    where=$(rel "$f")
    starts=$(grep -cF "$MARK_START" "$f")
    ends=$(grep -cF "$MARK_END" "$f")
    if [ "$starts" -eq 0 ] && [ "$ends" -eq 0 ]; then
      if grep -q '^## Modo Consultivo' "$f"; then
        # Hay un bloque sin marcadores: reinsertar duplicaría el texto.
        fail "$where: bloque sin marcadores — agregar los marcadores a mano"
      elif [ "$FIX" -eq 1 ]; then
        { echo "$MARK_START"; cat "$BLOCK"; echo "$MARK_END"; echo ""; cat "$f"; } > "$f.tmp" \
          && mv "$f.tmp" "$f"
        note "fix   $where: bloque insertado al inicio"
      else
        fail "$where: falta el bloque (corregible con --fix)"
      fi
      continue
    fi
    if [ "$starts" -ne 1 ] || [ "$ends" -ne 1 ]; then
      fail "$where: marcadores mal formados ($starts start / $ends end)"
      continue
    fi
    awk -v s="$MARK_START" -v e="$MARK_END" \
      '{ sub(/\r$/, "") } $0 == e { p = 0 } p { print } $0 == s { p = 1 }' "$f" > "$TMPD/blk"
    if cmp -s "$TMPD/blk" "$BLOCK"; then
      :
    elif [ "$FIX" -eq 1 ]; then
      awk -v s="$MARK_START" -v e="$MARK_END" -v blk="$BLOCK" '
        $0 == s { print; while ((getline l < blk) > 0) print l; skip = 1; next }
        $0 == e { skip = 0 }
        !skip { print }
      ' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
      note "fix   $where: bloque resincronizado"
    else
      fail "$where: el bloque difiere del canónico (corregible con --fix)"
    fi
  done
fi
end_check

# ---------- 4. Frontmatter por proveedor ----------
begin_check "4. Frontmatter por proveedor ($(echo "$PROVIDERS" | tr '\n' ' ' | sed 's/ $//'))"
for p in $PROVIDERS; do
  for role in $(roles); do
    [ -f "$ROOT/agents/frontmatter/$p/$role.md" ] \
      || fail "agents/frontmatter/$p/$role.md: falta (rol en agents/shared/)"
  done
  for f in "$ROOT"/agents/frontmatter/"$p"/*.md; do
    [ -f "$f" ] || continue
    role=$(basename "$f" .md)
    [ -f "$ROOT/agents/shared/$role.md" ] \
      || fail "$(rel "$f"): huérfano (no existe agents/shared/$role.md)"
  done
done
end_check

# ---------- 5. dist/ al día ----------
begin_check "5. agents/dist al día con shared/ + frontmatter/"
# Se regenera en una copia temporal de agents/ y se compara: sin --fix el
# árbol del toolkit no se toca.
cp -R "$ROOT/agents" "$TMPD/agents"
if ! out=$(bash "$TMPD/agents/build.sh" 2>&1); then
  fail "agents/build.sh falló: $out"
else
  changed=$(diff -rq "$ROOT/agents/dist" "$TMPD/agents/dist" 2>&1 \
    | sed -e "s|$TMPD/agents/|<build>/|g" -e "s|$ROOT/||g")
  if [ -z "$changed" ]; then
    :
  elif [ "$FIX" -eq 1 ]; then
    if out=$(bash "$ROOT/agents/build.sh" 2>&1); then
      note "fix   agents/dist regenerado (falta commitear junto con shared/frontmatter)"
    else
      fail "agents/build.sh falló: $out"
    fi
  else
    fail "agents/dist no coincide con lo que genera build.sh (corregible con --fix):"
    DETAIL="$DETAIL
$(echo "$changed" | head -n 20 | sed 's/^/            /')"
  fi
fi
end_check

# ---------- 6. Router completo ----------
begin_check "6. Router: agent_orchestrator menciona cada rol y skill"
ORCH="$ROOT/skills/agent_orchestrator/SKILL.md"
if [ ! -f "$ORCH" ]; then
  fail "$(rel "$ORCH"): no existe"
else
  for name in $(roles) $(for d in "$ROOT"/skills/*/; do basename "$d"; done); do
    [ "$name" = "agent_orchestrator" ] && continue
    grep -qF "\`$name\`" "$ORCH" || fail "falta \`$name\` en skills/agent_orchestrator/SKILL.md"
  done
fi
end_check

# ---------- 7. Standards del proyecto ----------
begin_check "7. Standards del proyecto (secciones de standards/_TEMPLATE.md)"
TEMPLATE="$ROOT/standards/_TEMPLATE.md"
if [ -z "$PROJECT" ]; then
  skip "solo con --project"
elif [ ! -d "$PROJECT/standards" ]; then
  note "el proyecto no tiene standards/ (nada que revisar)"
else
  found=0
  for f in "$PROJECT"/standards/*.md; do
    [ -f "$f" ] || continue
    [ "$(basename "$f")" = "_TEMPLATE.md" ] && continue
    found=1
    tr -d '\r' < "$f" > "$TMPD/std"
    missing=$(grep '^## ' "$TEMPLATE" | tr -d '\r' | while IFS= read -r h; do
      grep -qxF "$h" "$TMPD/std" || echo "$h"
    done | tr '\n' ',' | sed 's/,$//; s/,/, /g')
    [ -z "$missing" ] || fail "standards/$(basename "$f"): faltan secciones: $missing"
  done
  [ "$found" -eq 1 ] || note "standards/ está vacío (nada que revisar)"
fi
end_check

# ---------- 8. Sin datos de negocio ----------
begin_check "8. Sin datos de negocio (términos de --deny-file)"
if [ -z "$DENY_FILE" ]; then
  skip "sin --deny-file: no se buscan términos de negocio (ver README)"
elif [ ! -f "$DENY_FILE" ]; then
  fail "no existe el archivo de términos '$DENY_FILE'"
elif [ "$IS_GIT" -eq 0 ]; then
  skip "el toolkit no es un repo git — no hay lista de archivos versionados"
else
  deny_abs="$(cd "$(dirname "$DENY_FILE")" && pwd -P)/$(basename "$DENY_FILE")"
  case "$deny_abs" in
    "$ROOT"/*) fail "el archivo de términos está dentro del toolkit ($(rel "$deny_abs")) — debe vivir en el proyecto" ;;
    *)
      set --
      while IFS= read -r t || [ -n "$t" ]; do
        t=$(printf '%s' "$t" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        case "$t" in ''|'#'*) continue ;; esac
        set -- "$@" -e "$t"
      done < "$DENY_FILE"
      if [ $# -eq 0 ]; then
        warn "el archivo de términos no tiene términos"
      else
        hits=$(git -C "$ROOT" grep -n -i -I -F "$@" 2>/dev/null)
        if [ -n "$hits" ]; then
          total=$(echo "$hits" | wc -l | tr -d ' ')
          C_FAIL=$((C_FAIL + 1))
          note "FAIL  $total coincidencias en archivos versionados (archivo:línea):"
          DETAIL="$DETAIL
$(echo "$hits" | head -n 40 | cut -c1-160 | sed 's/^/            /')"
          [ "$total" -le 40 ] || note "      … y $((total - 40)) más (ver todas con: git grep -n -i -F -e <término>)"
        else
          note "$(($# / 2)) términos buscados, sin coincidencias"
        fi
      fi
      ;;
  esac
fi
end_check

# ---------- 9. Topología B con raíz versionada ----------
begin_check "9. Raíz versionada: repos hijos ignorados por el .gitignore de la raíz"
if [ -z "$PROJECT" ]; then
  skip "solo con --project"
elif [ ! -e "$PROJECT/.git" ]; then
  note "la raíz no es un repo git (nada que revisar)"
else
  children=0
  for d in "$PROJECT"/*/; do
    [ -e "$d.git" ] || continue
    children=$((children + 1))
    child=$(basename "$d")
    git -C "$PROJECT" check-ignore -q "$child" \
      || warn "$child/: repo hijo no ignorado por el .gitignore de la raíz (ver templates/root-tracking.gitignore.template)"
  done
  [ "$children" -gt 0 ] || note "sin repos hijos en el primer nivel (topología A/C, nada que revisar)"
fi
end_check

# ---------- 10. Fichas de módulo ----------
begin_check "10. Fichas de módulo (.adf/modules/*.md: frontmatter, estado, rutas)"
if [ -z "$PROJECT" ]; then
  skip "solo con --project"
else
  found=0
  if [ ! -e "$PROJECT/.git" ] && [ -d "$PROJECT/.adf/modules" ]; then
    warn ".adf/modules/ en la raíz sin git: en topología B las fichas van en <repo-hijo>/.adf/modules/"
  fi
  for repo in $(adf_repos); do
    for f in "$repo"/.adf/modules/*.md; do
      [ -f "$f" ] || continue
      found=1
      where=$(rel "$f")
      if ! has_frontmatter "$f"; then
        fail "$where: sin frontmatter válido (--- ... ---)"
        continue
      fi
      for k in id estado rutas actualizada; do
        fm_has "$f" "$k" || fail "$where: falta '$k' en el frontmatter"
      done
      estado=$(fm_value "$f" estado)
      case "$estado" in
        borrador|aprobada) ;;
        *) fail "$where: estado '$estado' inválido (borrador | aprobada)" ;;
      esac
      id=$(fm_value "$f" id)
      [ -z "$id" ] || [ "$id" = "$(basename "$f" .md)" ] \
        || warn "$where: id '$id' distinto del nombre del archivo"
      rutas=$(fm_list "$f" rutas)
      [ -n "$rutas" ] || fail "$where: 'rutas' sin ninguna ruta"
      for r in $rutas; do
        path_exists "$repo" "$r" || warn "$where: la ruta '$r' no existe (ficha desfasada)"
      done
    done
  done
  [ "$found" -eq 1 ] || note "sin fichas de módulo (nada que revisar)"
fi
end_check

# ---------- 11. Findings ----------
begin_check "11. Findings (.adf/findings/*.md: campos obligatorios, prueba de regresión)"
if [ -z "$PROJECT" ]; then
  skip "solo con --project"
else
  found=0
  if [ ! -e "$PROJECT/.git" ] && [ -d "$PROJECT/.adf/findings" ]; then
    warn ".adf/findings/ en la raíz sin git: en topología B los findings van en <repo-hijo>/.adf/findings/"
  fi
  for repo in $(adf_repos); do
    for f in "$repo"/.adf/findings/*.md; do
      [ -f "$f" ] || continue
      found=1
      where=$(rel "$f")
      if ! has_frontmatter "$f"; then
        fail "$where: sin frontmatter válido (--- ... ---)"
        continue
      fi
      for k in id task_id prueba_regresion candidato_standard; do
        [ -n "$(fm_value "$f" "$k")" ] || fail "$where: falta '$k' en el frontmatter"
      done
      id=$(fm_value "$f" id)
      if [ -n "$id" ] && ! printf '%s' "$id" | grep -qx 'F-[0-9]\{8\}-[0-9]\{6\}'; then
        fail "$where: id '$id' no sigue el formato F-AAAAMMDD-HHMMSS"
      fi
      cand=$(fm_value "$f" candidato_standard)
      case "$cand" in si|no|'') ;; *) fail "$where: candidato_standard '$cand' inválido (si | no)" ;; esac
      tr -d '\r' < "$f" > "$TMPD/fnd"
      for h in "## Síntoma" "## Causa raíz" "## Corrección"; do
        grep -qxF "$h" "$TMPD/fnd" || fail "$where: falta la sección '$h'"
      done
      test_path=$(fm_value "$f" prueba_regresion)
      if [ -n "$test_path" ] && [ ! -e "$repo/$test_path" ]; then
        fail "$where: la prueba de regresión '$test_path' no existe"
      fi
    done
  done
  [ "$found" -eq 1 ] || note "sin findings (nada que revisar)"
fi
end_check

# ---------- 12. ESTADO.md ----------
begin_check "12. ESTADO.md (existe; ✅ solo con task_id de evidencia)"
if [ -z "$PROJECT" ]; then
  skip "solo con --project"
else
  estado_md=""
  for c in "$PROJECT/.adf/ESTADO.md" "$PROJECT/ESTADO.md"; do
    [ -f "$c" ] && { estado_md="$c"; break; }
  done
  if [ -z "$estado_md" ]; then
    warn "no existe .adf/ESTADO.md (se crea con link.sh desde templates/ESTADO.md.template)"
  else
    # Filas de tabla con ✅ cuya última celda (Evidencia) está vacía o en "—"/"-".
    sin_id=$(awk '
      { sub(/\r$/, "") }
      /^\|/ && index($0, "✅") {
        line = $0; sub(/^\|/, "", line); sub(/\|[ \t]*$/, "", line)
        n = split(line, c, "|"); ev = c[n]; gsub(/^[ \t]+|[ \t]+$/, "", ev)
        if (ev == "" || ev == "—" || ev == "-") print NR ": " $0
      }
    ' "$estado_md")
    for l in $sin_id; do
      warn "$(rel "$estado_md"):$(printf '%s' "$l" | cut -c1-120) — ✅ sin task_id"
    done
  fi
fi
end_check

echo ""
echo "Resumen: $TOTAL_OK OK, $TOTAL_WARN WARN, $TOTAL_FAIL FAIL, $TOTAL_SKIP SKIP"
[ "$TOTAL_FAIL" -eq 0 ]
