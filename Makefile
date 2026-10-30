# Makefile for icon-theme-toolkit

PREFIX        ?= /usr
INSTALL_DIR   ?= /opt/icon-theme-toolkit
BINDIR        ?= $(PREFIX)/bin
DATADIR       ?= $(PREFIX)/share

# Исходные JS-файлы, которые нужно установить
JS_FILES = icon-theme-toolkit.js theme.js settings.js icon-compiler.js winico2linuxtheme.js

# Цель по умолчанию
all:
	@echo "Ничего собирать не нужно. Используйте 'make install'."

install:
	# Каталог для JS-файлов
	install -d "$(DESTDIR)$(INSTALL_DIR)"
	for f in $(JS_FILES); do \
		install -m 644 "$$f" "$(DESTDIR)$(INSTALL_DIR)/$$f"; \
	done
	# Скрипт-обёртка
	install -d "$(DESTDIR)$(BINDIR)"
	install -m 755 launcher.sh "$(DESTDIR)$(BINDIR)/icon-theme-toolkit"
	# .desktop-файл
	install -d "$(DESTDIR)$(DATADIR)/applications"
	install -m 644 icon-theme-toolkit.desktop "$(DESTDIR)$(DATADIR)/applications/icon-theme-toolkit.desktop"

uninstall:
	rm -rf "$(DESTDIR)$(INSTALL_DIR)"
	rm -f  "$(DESTDIR)$(BINDIR)/icon-theme-toolkit"
	rm -f  "$(DESTDIR)$(DATADIR)/applications/icon-theme-toolkit.desktop"

.PHONY: all install uninstall