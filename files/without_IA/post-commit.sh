#!/bin/bash

# ============================================================
#  git-smart-docs — documentación manual inteligente
#  Sin IA: preguntas clave al desarrollador
# ============================================================

RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"

DOCS_PATH="docs/Documentation.html"

echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║        🧠 git-smart-docs             ║${RESET}"
echo -e "${CYAN}${BOLD}║   Documentación inteligente manual   ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════╝${RESET}"
echo ""

# ── 1. Información del commit ─────────────────────────────

COMMIT_HASH=$(git rev-parse --short HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B | head -1)
COMMIT_AUTHOR=$(git log -1 --pretty="%an")
COMMIT_DATE=$(git log -1 --pretty="%ad" --date=format:"%d/%m/%Y %H:%M")
COMMIT_FILES=$(git diff-tree --no-commit-id --name-only -r HEAD | tr '\n' ', ' | sed 's/,$//')
COMMIT_STATS=$(git diff-tree --no-commit-id -r --stat HEAD | tail -1)

echo -e "${BLUE}Commit detectado:${RESET}"
echo "Hash: $COMMIT_HASH"
echo "Mensaje: $COMMIT_MSG"
echo "Archivos: $COMMIT_FILES"
echo ""

# ── 2. Confirmar documentación ─────────────────────────────

echo -e "${YELLOW}¿Quieres documentar este commit? (s/n)${RESET}"
read -r RESP </dev/tty

if [[ ! "$RESP" =~ ^[sS]$ ]]; then
    echo "Saltando documentación."
    exit 0
fi

echo ""

# ── 3. Preguntas clave ─────────────────────────────────────

echo -e "${CYAN}${BOLD}Pregunta 1:${RESET}"
echo "¿Por qué hiciste este cambio?"
read -r CHANGE_REASON </dev/tty

echo ""

echo -e "${CYAN}${BOLD}Pregunta 2:${RESET}"
echo "¿Qué impacto tiene este cambio en el proyecto?"
read -r CHANGE_IMPACT </dev/tty

echo ""

# ── 4. Crear docs si no existe ─────────────────────────────

if [ ! -f "$DOCS_PATH" ]; then

mkdir -p docs

cat > "$DOCS_PATH" << 'HTML'
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Documentación del Proyecto</title>
<style>

body{
font-family: system-ui;
background:#0f172a;
color:#e2e8f0;
padding:40px;
}

.entry{
background:#1e293b;
padding:20px;
border-radius:10px;
margin-bottom:20px;
}

.hash{
font-family:monospace;
color:#38bdf8;
}

.meta{
font-size:14px;
opacity:0.7;
margin-bottom:10px;
}

.files{
font-family:monospace;
font-size:13px;
margin-top:10px;
}

</style>
</head>
<body>

<h1>📚 Documentación del Proyecto</h1>

<div id="log-container">

</div>

</body>
</html>
HTML

echo -e "${GREEN}Archivo de documentación creado.${RESET}"

fi

# ── 5. Construir entrada HTML ─────────────────────────────

NEW_ENTRY="
<div class=\"entry\">

<div class=\"meta\">
<span class=\"hash\">$COMMIT_HASH</span> • $COMMIT_DATE • $COMMIT_AUTHOR
</div>

<h3>$COMMIT_MSG</h3>

<p><strong>Motivo del cambio:</strong><br>
$CHANGE_REASON
</p>

<p><strong>Impacto en el proyecto:</strong><br>
$CHANGE_IMPACT
</p>

<div class=\"files\">
Archivos modificados: $COMMIT_FILES
</div>

<div class=\"files\">
$COMMIT_STATS
</div>

</div>
"

# ── 6. Insertar en HTML ───────────────────────────────────

python3 <<EOF
import re

path="$DOCS_PATH"

with open(path,"r",encoding="utf-8") as f:
    content=f.read()

entry="""$NEW_ENTRY"""

content=content.replace(
'<div id="log-container">',
'<div id="log-container">\n'+entry
)

with open(path,"w",encoding="utf-8") as f:
    f.write(content)
EOF

echo -e "${GREEN}✓ Documentación añadida correctamente${RESET}"
echo ""