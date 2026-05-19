.PHONY: help verify test build install refresh

SOURCE_REPO ?= ../codex

help:
	@printf '%s\n' \
		'Targets:' \
		'  make verify   Check that patches apply to pinned upstream' \
		'  make test     Check patches and run focused codex-tui tests' \
		'  make build    Build patched codex without installing' \
		'  make install  Build and install patched codex to ~/.local/bin' \
		'  make refresh  Refresh patch from SOURCE_REPO=/path/to/codex'

verify:
	scripts/verify.sh

test:
	scripts/verify.sh --test

build:
	scripts/build-install.sh --no-install

install:
	scripts/build-install.sh --test

refresh:
	scripts/refresh-patch-from-local.sh "$(SOURCE_REPO)"
