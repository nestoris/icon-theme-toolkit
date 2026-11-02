#!/usr/bin/env bash
set -euo pipefail

for cmd in curl jq sha256sum makepkg git; do
    command -v "$cmd" >/dev/null || { echo "Not found: $cmd"; exit 1; }
done

# ======== НАСТРОЙКИ ========
REPO="nestoris/icon-theme-toolkit"      # GitHub-репозиторий
AUR_PKG="icon-theme-toolkit"            # имя пакета в AUR
PKGBUILD="PKGBUILD"
# ============================

# Проверка зависимостей
for cmd in curl jq sha256sum makepkg git; do
    command -v "$cmd" >/dev/null || { echo "Не найдено: $cmd"; exit 1; }
done

# 1. Последний релизный тег (исключаем pre-release)
LATEST=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | jq -r .tag_name)
if [[ -z "$LATEST" || "$LATEST" == "null" ]]; then
    echo "Не удалось получить последний релиз."
    exit 1
fi

NEW_VER="$LATEST"

# 2. Текущая версия из PKGBUILD
OLD_VER=$(grep -m1 '^pkgver=' "$PKGBUILD" | cut -d= -f2)

if [[ "$NEW_VER" == "$OLD_VER" ]]; then
    echo "Версия не изменилась ($OLD_VER). Выход."
    exit 0
fi

echo "Обновление: $OLD_VER -> $NEW_VER"

# 3. Скачиваем архив и считаем sha256
TARBALL_URL="https://github.com/$REPO/archive/refs/tags/$NEW_VER.tar.gz"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
if ! curl -fL --retry 3 -sS -o "$TMP" "$TARBALL_URL"; then
    echo "Ошибка: не удалось скачать $TARBALL_URL" >&2
    exit 1
fi
if [[ ! -s "$TMP" ]]; then
    echo "Ошибка: скачанный файл пуст ($TARBALL_URL)" >&2
    exit 1
fi
NEW_SHA=$(sha256sum "$TMP" | awk '{print $1}')
echo "sha256: $NEW_SHA"
rm -f "$TMP"

# 4. Обновляем PKGBUILD (sed)
sed -i "s/^pkgver=.*/pkgver=$NEW_VER/" "$PKGBUILD"
sed -i "s/^pkgrel=.*/pkgrel=1/" "$PKGBUILD"
sed -i "s/^sha256sums=.*/sha256sums=('$NEW_SHA')/" "$PKGBUILD"

# 5. Генерируем .SRCINFO
makepkg --printsrcinfo > .SRCINFO

# 6. (Опционально) коммит и пуш в AUR
# Раскомментируйте, если хотите автоматический пуш
# git add PKGBUILD .SRCINFO
# git commit -m "Update to $NEW_VER"
# git push

# 5. Генерируем .SRCINFO (даже если версия не менялась)
makepkg --printsrcinfo > .SRCINFO

echo "Готово. Проверьте PKGBUILD и .SRCINFO."