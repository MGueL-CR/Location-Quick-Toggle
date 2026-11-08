#!/usr/bin/env bash
#
# Crea el paquete ZIP que se sube a extensions.gnome.org (EGO).
# El script vive en src/scripts, por lo que primero sube al directorio
# raíz de la extensión antes de leer y empaquetar sus archivos.

set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_DIR="$(dirname -- "$SCRIPT_DIR")"
PO_FILES_DIR="src/po/lang/"
PROJECT_DIR="$(cd -- "$SRC_DIR/.." && pwd -P)"
METADATA_FILE="$PROJECT_DIR/metadata.json"
DIST_DIR="$PROJECT_DIR/dist"

compile_translations() {
    local po_file language catalog_dir catalog_file
    local found=false

    echo -n "[3/7] Compilando catálogos de traducción...            "

    for po_file in "$PROJECT_DIR/$PO_FILES_DIR"*.po; do
        [[ -f "$po_file" ]] || continue

        if [[ "$found" == false ]]; then 
            echo -e "${GREEN}OK${NC}" 
        fi

        found=true
        language="$(basename "$po_file" .po)"
        catalog_dir="$PROJECT_DIR/locale/$language/LC_MESSAGES"
        catalog_file="$catalog_dir/$GETTEXT_DOMAIN.mo"

        echo -e "${BLUE}INFO:${NC} - Compilando idioma: $language"
        mkdir -p "$catalog_dir"
        msgfmt --check --output-file "$catalog_file" "$po_file"
    done

    if [[ "$found" == false ]]; then
        echo -e "\n${YELLOW}WARNING:${NC} No se encontraron archivos PO para compilar."
        echo ""
    fi
}

echo -e "\n"
echo "=== Creación del paquete para EGO ==="
echo -n "[1/7] Localizando archivos de la extensión...          "

if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo -e "\n${RED}ERROR:${NC} Se requiere el comando gnome-extensions." >&2
    exit 1
fi

if ! command -v msgfmt >/dev/null 2>&1; then
    echo -e "\n${RED}ERROR:${NC} Se requiere el comando msgfmt para compilar traducciones." >&2
    exit 1
fi

echo -e "${GREEN}OK${NC}"
echo -n "[2/7] Validando metadatos y archivos fuente...         "

if [[ ! -f "$METADATA_FILE" || ! -f "$PROJECT_DIR/extension.js" ]]; then
    echo -e "\n${RED}ERROR:${NC} No se encontraron metadata.json y extension.js en $PROJECT_DIR." >&2
    exit 1
fi

UUID="$(sed -nE 's/^[[:space:]]*"uuid"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$METADATA_FILE" | head -n 1)"
GETTEXT_DOMAIN="$(sed -nE 's/^[[:space:]]*"gettext-domain"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$METADATA_FILE" | head -n 1)"

if [[ -z "$UUID" || -z "$GETTEXT_DOMAIN" ]]; then
    echo -e "\n${RED}ERROR:${NC} El metadata.json debe incluir uuid y gettext-domain." >&2
    exit 1
fi

if [[ ! -d "$SRC_DIR/po" ]]; then
    echo -e "\n${RED}ERROR:${NC} No se encontró el directorio de traducciones po/." >&2
    exit 1
fi

echo -e "${GREEN}OK${NC}"

mkdir -p "$DIST_DIR"
compile_translations

echo -n "[4/7] Creando el archivo ZIP para EGO...               "
cd -- "$PROJECT_DIR"

gnome-extensions pack \
    --force \
    --out-dir "$DIST_DIR" \
    --podir "$PO_FILES_DIR" \
    --gettext-domain "$GETTEXT_DOMAIN" \
    --extra-source="LICENSE" \
    "$PROJECT_DIR"

PACKAGE_PATH="$DIST_DIR/$UUID.shell-extension.zip"
if [[ ! -f "$PACKAGE_PATH" ]]; then
    echo -e "\n${RED}ERROR:${NC} No se creó el paquete esperado: $PACKAGE_PATH" >&2
    exit 1
fi

echo -e "${GREEN}OK${NC}"
echo -n "[5/7] Verificando el paquete generado...               "
if command -v unzip >/dev/null 2>&1; then
    unzip -t "$PACKAGE_PATH" >/dev/null

    if ! unzip -l "$PACKAGE_PATH" |
        grep -Eq "locale/.+/LC_MESSAGES/$GETTEXT_DOMAIN\\.mo"; then
        echo -e "\n${YELLOW}WARNING:${NC} El paquete no contiene catálogos de traducción compilados." >&2
        exit 1
    fi
fi
echo -e "${GREEN}OK${NC}"
echo -n "[6/7] Eliminando catálogos de traducción temporales... "
rm -rf $PROJECT_DIR/locale

echo -e "${GREEN}OK${NC}"
echo -n "[7/7] Paquete para EGO creado:                         "
echo -e "${GREEN}OK${NC}"
echo -e "${BLUE}INFO:${NC} $PACKAGE_PATH"

echo -e "\n"