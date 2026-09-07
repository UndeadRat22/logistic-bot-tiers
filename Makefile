.PHONY: test-e2e lint package install

# Path to the Factorio binary (auto-detected from Steam install on macOS)
FACTORIO_BIN ?= $(HOME)/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio

VERSION := $(shell sed -n 's/.*"version": "\([^"]*\)".*/\1/p' info.json)
MOD_NAME := logistic-bot-tiers
PACKAGE_DIR := $(MOD_NAME)_$(VERSION)
RELEASES_DIR := releases
PACKAGE_ZIP := $(RELEASES_DIR)/$(PACKAGE_DIR).zip

# Default Factorio mods dir per OS for `make install`
UNAME_S := $(shell uname -s 2>/dev/null)
ifeq ($(UNAME_S),Darwin)
	FACTORIO_MODS_DIR ?= $(HOME)/Library/Application Support/factorio/mods
else ifneq ($(filter MINGW% MSYS% CYGWIN%,$(UNAME_S)),)
	FACTORIO_MODS_DIR ?= $(APPDATA)/Factorio/mods
else
	FACTORIO_MODS_DIR ?= $(HOME)/.factorio/mods
endif

test-e2e:
	FACTORIO_BIN="$(FACTORIO_BIN)" sh tests/run-e2e.sh

test-e2e-k2:
	FACTORIO_BIN="$(FACTORIO_BIN)" sh tests/run-e2e-k2.sh

test-e2e-k2-nosa:
	FACTORIO_BIN="$(FACTORIO_BIN)" sh tests/run-e2e-k2-nosa.sh

test-e2e-k2so:
	FACTORIO_BIN="$(FACTORIO_BIN)" sh tests/run-e2e-k2so.sh

test-e2e-all: test-e2e test-e2e-k2 test-e2e-k2-nosa test-e2e-k2so

lint:
	luacheck data-final-fixes.lua settings.lua --no-config || true

package:
	@echo "Packaging $(MOD_NAME) $(VERSION)..."
	@rm -rf $(PACKAGE_DIR) $(RELEASES_DIR)
	@mkdir -p $(RELEASES_DIR)
	@mkdir -p $(PACKAGE_DIR)
	@cp -r changelog.txt data-final-fixes.lua info.json locale README.md settings.lua thumbnail.png $(PACKAGE_DIR)/
	@zip -r $(PACKAGE_DIR).zip $(PACKAGE_DIR) >/dev/null
	@mv $(PACKAGE_DIR).zip $(RELEASES_DIR)/
	@rm -rf $(PACKAGE_DIR)
	@echo "Created $(PACKAGE_ZIP)"

install: package
	@mkdir -p "$(FACTORIO_MODS_DIR)"
	@cp "$(PACKAGE_ZIP)" "$(FACTORIO_MODS_DIR)/"
	@echo "Installed $(PACKAGE_DIR).zip to $(FACTORIO_MODS_DIR)"
