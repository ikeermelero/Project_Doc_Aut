GUIA DE INSTALACIÓN 

Esta guía te servirá para saber instalar esta automatización para tu documentación.
Para ello usamos la Ollama como generador de la documentación.
    

 #!/usr/bin/env bash
# ====================================================
#  AUTO-DOC v4 — Pro Edition
# ====================================================

# ==============================
# CONFIG
# ==============================

MODEL="${AUTODOC_MODEL:-mistral}"
OUTPUT="docs/DOCUMENTACION.html"
MAX_DIFF=150
MARKER="<!-- AUTODOC:ENTRIES -->"

MODE="${AUTODOC_MODE:-verbose}"   # verbose | silent
DEBUG="${AUTODOC_DEBUG:-false}"

# ==============================
# COLORS
# ==============================

RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

BLUE="\033[34m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"

# ==============================
# UTILS
# ==============================

log() {
  if [ "$MODE" != "silent" ]; then
    echo -e "${BLUE}[AUTO-DOC]${RESET} $1"
  fi
}

success() {
  if [ "$MODE" != "silent" ]; then
    echo -e "${GREEN}✔ $1${RESET}"
  fi
}

warn() {
  if [ "$MODE" != "silent" ]; then
    echo -e "${YELLOW}⚠ $1${RESET}"
  fi
}

error() {
  echo -e "${RED}✖ $1${RESET}"
}

debug() {
  if [ "$DEBUG" = "true" ]; then
    echo -e "${DIM}[DEBUG] $1${RESET}"
  fi
}

spinner() {
  local pid=$1
  local spin='-\|/'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${CYAN}Generando con IA... ${spin:$i:1}${RESET}"
    sleep 0.1
  done
  printf "\r"
}

# ==============================
# START TIMER
# ==============================

START_TIME=$(date +%s)

log "Iniciando AUTO-DOC..."

# ==============================
# VALIDATE REPO
# ==============================

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  error "No es un repositorio Git"
  exit 1
}

PROJECT=$(basename "$ROOT")
HTML_FILE="$ROOT/$OUTPUT"

mkdir -p "$ROOT/docs"

# ==============================
# EXTRACT COMMIT DATA
# ==============================

log "Extrayendo datos del commit..."

HASH=$(git rev-parse --short HEAD)
MSG=$(git log -1 --pretty=%B | head -3)
DATE=$(date '+%Y-%m-%d %H:%M')
BRANCH=$(git rev-parse --abbrev-ref HEAD)

if git rev-parse HEAD~1 &>/dev/null; then
  FILES=$(git diff HEAD~1 HEAD --name-only | head -10)
  DIFF=$(git diff HEAD~1 HEAD | head -n $MAX_DIFF)
else
  FILES=$(git show --name-only --pretty="" HEAD | head -10)
  DIFF=$(git show HEAD | head -n $MAX_DIFF)
fi

FILES_CSV=$(echo "$FILES" | tr '\n' ',' | sed 's/,$//')

DIFF_LINES=$(echo "$DIFF" | wc -l | tr -d ' ')
FILE_COUNT=$(echo "$FILES" | wc -l | tr -d ' ')

log "Archivos modificados: ${BOLD}$FILE_COUNT${RESET}"
log "Líneas procesadas del diff: ${BOLD}$DIFF_LINES${RESET}"

debug "Mensaje commit: $MSG"
debug "Branch: $BRANCH"

# ==============================
# PROMPT
# ==============================

PROMPT="Genera SOLO un bloque <article> HTML profesional en español.
Sin html, head ni estilos.

Estructura exacta:

<article class=\"entry\">
<div class=\"entry-header\">
<div class=\"entry-title\">TITULO</div>
<div class=\"entry-meta\">FECHA · #HASH · TIPO</div>
</div>
<div class=\"section\"><h3>Descripcion</h3><p>Texto</p></div>
<div class=\"section\"><h3>Impacto tecnico</h3><p>Texto</p></div>
</article>

Datos:
Commit: $MSG
Hash: $HASH
Fecha: $DATE
Rama: $BRANCH
Archivos: $FILES_CSV
Diff:
$DIFF
"

# ==============================
# CALL OLLAMA WITH SPINNER
# ==============================

log "Invocando modelo IA ($MODEL)..."

TMP_OUTPUT=$(mktemp)

(ollama run "$MODEL" "$PROMPT" > "$TMP_OUTPUT" 2>/dev/null) &
PID=$!

spinner $PID
wait $PID

ARTICLE=$(sed -n '/<article/,/<\/article>/p' "$TMP_OUTPUT")
rm "$TMP_OUTPUT"

if [ -z "$ARTICLE" ]; then
  warn "IA no respondió correctamente. Usando fallback."
  ARTICLE="<article class=\"entry\">
<div class=\"entry-header\">
<div class=\"entry-title\">$MSG</div>
<div class=\"entry-meta\">$DATE · #$HASH · update</div>
</div>
<div class=\"section\"><h3>Descripcion</h3><p>Actualización automática.</p></div>
<div class=\"section\"><h3>Impacto tecnico</h3><p>Ver cambios en Git.</p></div>
</article>"
fi

# ==============================
# CREATE BASE HTML IF NEEDED
# ==============================

if [ ! -f "$HTML_FILE" ]; then
  log "Creando archivo base de documentación..."
  cat << EOF > "$HTML_FILE"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>$PROJECT — Documentación Técnica</title>
<style>
body{font-family:Arial,sans-serif;padding:60px;color:#1e293b}
.entry{margin-bottom:40px}
.entry-title{font-weight:bold;font-size:18px}
.entry-meta{font-size:12px;color:#64748b;margin-bottom:10px}
.section{margin-top:10px}
.section h3{font-size:11px;text-transform:uppercase;color:#94a3b8}
</style>
</head>
<body>
<h1>$PROJECT — Project Documentation</h1>
$MARKER
</body>
</html>
EOF
fi

# ==============================
# INSERT ARTICLE
# ==============================

log "Insertando nueva entrada..."

tmpfile=$(mktemp)

awk -v marker="$MARKER" -v article="$ARTICLE" '
{
  print
  if ($0 ~ marker) {
    print article
  }
}' "$HTML_FILE" > "$tmpfile"

mv "$tmpfile" "$HTML_FILE"

# ==============================
# AMEND
# ==============================

log "Actualizando commit..."

git -C "$ROOT" add "$OUTPUT" >/dev/null 2>&1
git -C "$ROOT" commit --amend --no-edit --quiet >/dev/null 2>&1

# ==============================
# END TIMER
# ==============================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

success "Documentación actualizada correctamente."
log "Tiempo total: ${BOLD}${DURATION}s${RESET}"   