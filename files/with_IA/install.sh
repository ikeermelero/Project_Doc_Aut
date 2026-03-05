#!/bin/bash

# ============================================================
#  install.sh — Instalador de git-ollama-docs
# ============================================================

RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"

echo ""
echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}${BOLD}║     🛠  Instalador git-ollama-docs        ║${RESET}"
echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""

# ── Verificar que estamos en un repo git ────────────────────
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}  ✗ Este directorio no es un repositorio Git.${RESET}"
    echo -e "${DIM}  Ejecuta primero: git init${RESET}"
    exit 1
fi

GIT_DIR=$(git rev-parse --git-dir)
HOOKS_DIR="${GIT_DIR}/hooks"
HOOK_FILE="${HOOKS_DIR}/post-commit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_HOOK="${SCRIPT_DIR}/hooks/post-commit"

echo -e "${CYAN}▶ Repositorio detectado:${RESET} $(git rev-parse --show-toplevel)"
echo -e "${CYAN}▶ Directorio de hooks:${RESET} ${HOOKS_DIR}"
echo ""

# ── Verificar dependencias ───────────────────────────────────
echo -e "${CYAN}▶ Verificando dependencias...${RESET}"

check_dep() {
    if command -v "$1" > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ $1${RESET}"
        return 0
    else
        echo -e "${RED}  ✗ $1 — no encontrado${RESET}"
        return 1
    fi
}

MISSING=0
check_dep "curl"    || MISSING=1
check_dep "python3" || MISSING=1
check_dep "git"     || MISSING=1

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${RED}  Faltan dependencias. Instálalas antes de continuar.${RESET}"
    exit 1
fi

# Verificar Ollama
echo -ne "  Comprobando Ollama... "
if curl -s --max-time 3 "http://localhost:11434/api/generate" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ activo${RESET}"
else
    echo -e "${YELLOW}⚠ no disponible (asegúrate de ejecutar 'ollama serve' antes de hacer commits)${RESET}"
fi

# Verificar phi3
echo -ne "  Comprobando modelo phi3... "
if ollama list 2>/dev/null | grep -q "phi3"; then
    echo -e "${GREEN}✓ disponible${RESET}"
else
    echo -e "${YELLOW}⚠ no encontrado — descárgalo con: ollama pull phi3${RESET}"
fi

echo ""

# ── Instalar hook ────────────────────────────────────────────
echo -e "${CYAN}▶ Instalando hook post-commit...${RESET}"

if [ -f "${HOOK_FILE}" ]; then
    echo -e "${YELLOW}  ⚠ Ya existe un hook post-commit. ¿Sobreescribir? [s/N]${RESET}"
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[sS]$ ]]; then
        echo -e "${DIM}  Instalación cancelada.${RESET}"
        exit 0
    fi
    cp "${HOOK_FILE}" "${HOOK_FILE}.bak"
    echo -e "${DIM}  Backup guardado en: ${HOOK_FILE}.bak${RESET}"
fi

cp "${SOURCE_HOOK}" "${HOOK_FILE}"
chmod +x "${HOOK_FILE}"

echo -e "${GREEN}  ✓ Hook instalado en: ${HOOK_FILE}${RESET}"
echo ""

# ── Resumen ──────────────────────────────────────────────────
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║      ✅  Instalación completada!          ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Ahora cada vez que hagas ${BOLD}git commit -m \"...\"${RESET}"
echo -e "  se te preguntará si quieres documentarlo en:"
echo -e "  ${BOLD}docs/DOCUMENTACION.html${RESET}"
echo ""
echo -e "${DIM}  Para desinstalar: rm ${HOOK_FILE}${RESET}"
echo ""
