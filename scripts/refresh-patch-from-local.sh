#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_REPO="${1:-../codex}"
PATCH_FILE="${ROOT_DIR}/patches/0001-tui-add-compact-count-status-line-item.patch"

paths=(
  "codex-rs/tui/src/bottom_pane/status_line_setup.rs"
  "codex-rs/tui/src/bottom_pane/status_line_style.rs"
  "codex-rs/tui/src/bottom_pane/status_surface_preview.rs"
  "codex-rs/tui/src/chatwidget.rs"
  "codex-rs/tui/src/chatwidget/status_surfaces.rs"
  "codex-rs/tui/src/chatwidget/tests/helpers.rs"
  "codex-rs/tui/src/chatwidget/tests/status_and_layout.rs"
)

if [[ ! -d "${SOURCE_REPO}/.git" ]]; then
  echo "Source repo not found: ${SOURCE_REPO}" >&2
  exit 1
fi

tmp_patch="${PATCH_FILE}.tmp"
git -C "${SOURCE_REPO}" diff -- "${paths[@]}" > "${tmp_patch}"

if [[ ! -s "${tmp_patch}" ]]; then
  rm -f "${tmp_patch}"
  echo "No diff found in ${SOURCE_REPO} for overlay paths." >&2
  exit 1
fi

mv "${tmp_patch}" "${PATCH_FILE}"
echo "Refreshed ${PATCH_FILE}"
