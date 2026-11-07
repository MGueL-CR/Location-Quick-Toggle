#!/usr/bin/env bash
#
# Instala la extensión para el usuario actual.
# El script vive en src/scripts, por lo que primero sube para copiar los archivos
# desde la raíz de la extensión al directorio de extensiones de GNOME.

set -euo pipefail

BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

usage() {
    cat <<'EOF'
Uso: ./install-manual.sh [--force] [--enable]

  --force      Actualiza una instalación existente de esta extensión.
  --no-enable  Copia los archivos, pero no intenta activar la extensión.
EOF
}

FORCE=false
ENABLE=false

for argument in "$@"; do
    case "$argument" in
        --force)
            FORCE=true
            ;;
        --enable)
            ENABLE=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}ERROR${NC}:" "opción desconocida: $argument" >&2
            usage >&2
            exit 2
            ;;
    esac
done

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SRC_DIR="$(dirname -- "$SCRIPT_DIR")"
PO_FILES_DIR="src/po/lang/"
PROJECT_DIR="$(cd -- "$SRC_DIR/.." && pwd -P)"
METADATA_FILE="$PROJECT_DIR/metadata.json"

compile_translations() {
    local po_file language catalog_dir catalog_file
    local found=false

    echo -n "[2/7] Compilando catálogos de traducción...            "

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

copy_translations() {
    local locale_dir language
    local found=false
    echo -n "[4/7] Copiando catálogos de traducción...              "

    for locale_dir in "$PROJECT_DIR"/locale/*; do
        [[ -d "$locale_dir" ]] || continue

        if [[ "$found" == false ]]; then 
            echo -e "${GREEN}OK${NC}" 
        fi

        found=true
        language="$(basename "$locale_dir")"

        echo -e "${BLUE}INFO:${NC} - Copiando idioma: $language"
        mkdir -p "$TARGET_DIR/locale/$language"
        cp -a "$locale_dir/." "$TARGET_DIR/locale/$language/"
    done

    if [[ "$found" == false ]]; then
        echo -e "\n${YELLOW}WARNING:${NC} No hay catálogos compilados para copiar."
        echo ""
    fi
}

echo -e "\n"
echo "=== Instalación manual de la extensión ==="
echo ""
echo -n "[1/7] Validando archivos fuente y metadatos...         "

if [[ ! -f "$METADATA_FILE" || ! -f "$PROJECT_DIR/extension.js" ]]; then
    echo -e "\n${RED}ERROR:${NC} No se encontraron metadata.json y extension.js en $PROJECT_DIR." >&2
    exit 1
fi

if ! command -v msgfmt >/dev/null 2>&1; then
    echo -e "\n${RED}ERROR:${NC} Se requiere el comando msgfmt para compilar traducciones." >&2
    echo ""
    exit 1
fi

UUID="$(sed -nE 's/^[[:space:]]*"uuid"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$METADATA_FILE" | head -n 1)"
GETTEXT_DOMAIN="$(sed -nE 's/^[[:space:]]*"gettext-domain"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' "$METADATA_FILE" | head -n 1)"
if [[ -z "$UUID" || -z "$GETTEXT_DOMAIN" ]]; then
    echo -e "\n${RED}ERROR:${NC} No se pudieron leer uuid y gettext-domain desde metadata.json." >&2
    echo ""
    exit 1
fi

DATA_HOME="${XDG_DATA_HOME:-"$HOME/.local/share"}"
TARGET_DIR="$DATA_HOME/gnome-shell/extensions/$UUID"

if [[ -e "$TARGET_DIR" && "$FORCE" != true ]]; then
    echo -e "\n${RED}ERROR:${NC} Ya existe una instalación en $TARGET_DIR." >&2
    echo -e "${BLUE}INFO: ${NC} Ejecute de nuevo con --force para actualizarla." >&2
    echo ""
    exit 1
fi

echo -e "${GREEN}OK${NC}"

compile_translations

echo -n "[3/7] Copiando los archivos principales de la extensión... "
mkdir -p "$TARGET_DIR"
install -m 0644 "$PROJECT_DIR/extension.js" "$PROJECT_DIR/metadata.json" "$PROJECT_DIR/LICENSE" "$TARGET_DIR/"

echo -e "${GREEN}   OK${NC}"

copy_translations

echo -n "[5/7] Extensión instalada...                           "
rm -rf $PROJECT_DIR/locale
echo -e "${GREEN}OK${NC}"
echo -e "${BLUE}INFO:${NC} $TARGET_DIR"

echo -n "[6/7] Eliminando catálogos de traducción temporales...         "
rm -rf $PROJECT_DIR/locale
echo -e "${GREEN}OK${NC}"

echo -n "[7/7] Activando la extensión...                        "

if [[ "$ENABLE" == true ]]; then
    
    if command gnome-extensions enable "$UUID"; then
        echo -e "${GREEN}OK${NC}"
        echo -e "${BLUE}INFO:${NC} Extensión activada: $UUID"
    else
        echo -e "\n${RED}ERROR:${NC} No se pudo activar automáticamente." >&2
        echo  -e "${BLUE}INFO:${NC} Actívela desde Extensiones o con:" >&2
        printf '    gnome-extensions enable %s\n' "$UUID" >&2
        echo ""
    fi
else
    echo -e "${GREEN}OK${NC}"
    echo -e "${BLUE}INFO:${NC} Activación omitida por ausencia del comando --enable."
    echo -e "${BLUE}INFO:${NC} Habilite la extensión usando 'GNOME Tweak Tool'."
fi

echo -e "\n"