#!/bin/sh
# /usr/bin/icon-theme-toolkit

INSTALL_DIR="/opt/icon-theme-toolkit"
MAIN_JS="$INSTALL_DIR/icon-theme-toolkit.js"

# Определяем, является ли текущее окружение Cinnamon
is_cinnamon() {
    # XDG_CURRENT_DESKTOP может быть "X-Cinnamon", "Cinnamon", "cinnamon" и т.п.
    case "${XDG_CURRENT_DESKTOP:-}" in
        *[Cc]innamon*) return 0 ;;
    esac
    # Дополнительная проверка: если запущен cinnamon-session
    if pgrep -x cinnamon-session >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# Если это Cinnamon и cjs доступен — используем cjs
if is_cinnamon && command -v cjs >/dev/null 2>&1; then
    exec cjs "$MAIN_JS" "$@"
fi

# Иначе — gjs (по умолчанию)
if command -v gjs >/dev/null 2>&1; then
    exec gjs "$MAIN_JS" "$@"
fi

# Если ни gjs, ни cjs не найдены — выводим ошибку
echo "Ошибка: не найден ни gjs, ни cjs. Установите gjs (или cjs для Cinnamon)." >&2
exit 1