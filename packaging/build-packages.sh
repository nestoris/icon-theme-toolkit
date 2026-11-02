#!/usr/bin/env bash
# build-packages.sh — собирает .deb и .rpm из PKGBUILD через nFPM.
# Требуется: nfpm (один бинарник, см. README), make.

set -euo pipefail

makepkg

PKGBUILD="${1:-PKGBUILD}"
if [[ ! -f "$PKGBUILD" ]]; then
    echo "Ошибка: не найден $PKGBUILD" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$PKGBUILD"

: "${pkgname:?pkgname не задан}"
: "${pkgver:?pkgver не задан}"
: "${pkgrel:?pkgrel не задан}"

# ---------- 1. Поиск корня проекта (где лежит Makefile) ----------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT=""
for candidate in "$SCRIPT_DIR" "$SCRIPT_DIR/.." "$SCRIPT_DIR/../.." ; do
    if [[ -f "$candidate/Makefile" ]]; then
        PROJECT_ROOT="$(cd "$candidate" && pwd)"
        break
    fi
done
if [[ -z "$PROJECT_ROOT" ]]; then
    echo "Ошибка: Makefile не найден ни в $SCRIPT_DIR, ни в родительских каталогах." >&2
    exit 1
fi
echo "==> Корень проекта: $PROJECT_ROOT"

# ---------- 2. Установка во временный корень ----------
BUILD_ROOT="$(mktemp -d)"
trap 'rm -rf "$BUILD_ROOT"' EXIT

echo "==> make -C $PROJECT_ROOT install DESTDIR=$BUILD_ROOT"
make -C "$PROJECT_ROOT" install DESTDIR="$BUILD_ROOT"

# ---------- 3. Метаданные ----------
DEB_DEPENDS=("gjs" "libgtk-3-0" "libgdk-pixbuf-2.0-0")
RPM_DEPENDS=("gjs" "gtk3" "gdk-pixbuf2")

# ---------- 4. Генерация nfpm.yaml ----------
NFPM_YAML="$BUILD_ROOT/nfpm.yaml"
{
    cat <<EOF
name: "$pkgname"
arch: "amd64"
platform: "linux"
version: "${pkgver}-${pkgrel}"
section: "utils"
priority: "optional"
maintainer: "Joker <joker@example.com>"
description: |
  ${pkgdesc:-Toolkit for creating and editing Linux icon themes}
vendor: "Joker"
homepage: "${url:-https://github.com/nestoris/icon-theme-toolkit}"
license: "${license[*]:-MIT}"
contents:
  - src: "$BUILD_ROOT/opt"
    dst: "/opt"
    type: tree
  - src: "$BUILD_ROOT/usr"
    dst: "/usr"
    type: tree
overrides:
  deb:
    depends:
EOF
    for dep in "${DEB_DEPENDS[@]}"; do
        echo "      - $dep"
    done
    cat <<EOF
  rpm:
    depends:
EOF
    for dep in "${RPM_DEPENDS[@]}"; do
        echo "      - $dep"
    done
} > "$NFPM_YAML"

echo "==> Сгенерированный nfpm.yaml:"
cat "$NFPM_YAML"

# ---------- 5. Сборка ----------
echo "==> Сборка .deb"
nfpm pkg --config "$NFPM_YAML" --packager deb --target ./

echo "==> Сборка .rpm"
nfpm pkg --config "$NFPM_YAML" --packager rpm --target ./

echo "==> Готово:"
ls -1 ./*.deb ./*.rpm 2>/dev/null || true