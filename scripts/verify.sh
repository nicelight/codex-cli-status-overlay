#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_FILE="${ROOT_DIR}/upstream.toml"
PATCH_DIR="${ROOT_DIR}/patches"

repo_url="$(sed -nE 's/^repo = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"
upstream_ref="$(sed -nE 's/^ref = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"
codex_rs_dir="$(sed -nE 's/^codex_rs_dir = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"

run_tests=0
keep_worktree=0
worktree=""

usage() {
  cat <<'USAGE'
Verify that the overlay applies cleanly to official Codex sources.

Usage:
  scripts/verify.sh [options]

Options:
  --ref REF        Upstream Codex git ref/tag to verify against.
  --worktree DIR   Use this worktree instead of a temporary clone.
  --test           Run focused codex-tui tests after applying patches.
  --keep           Keep the temporary clone for inspection.
  -h, --help       Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      upstream_ref="${2:?missing value for --ref}"
      shift 2
      ;;
    --worktree)
      worktree="${2:?missing value for --worktree}"
      keep_worktree=1
      shift 2
      ;;
    --test)
      run_tests=1
      shift
      ;;
    --keep)
      keep_worktree=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "${worktree}" ]]; then
  worktree="$(mktemp -d)"
  trap 'if [[ "${keep_worktree}" != "1" ]]; then rm -rf "${worktree}"; fi' EXIT
  git clone --branch "${upstream_ref}" --depth 1 "${repo_url}" "${worktree}/codex"
  worktree="${worktree}/codex"
fi

for patch in "${PATCH_DIR}"/*.patch; do
  echo "Checking $(basename "${patch}")"
  git -C "${worktree}" apply --check "${patch}"
done

for patch in "${PATCH_DIR}"/*.patch; do
  echo "Applying $(basename "${patch}")"
  git -C "${worktree}" apply "${patch}"
done

if [[ "${run_tests}" == "1" ]]; then
  cargo test --manifest-path "${worktree}/${codex_rs_dir}/Cargo.toml" --locked -p codex-tui status_line_compact_count
fi

echo "Overlay verified against ${upstream_ref}."
echo "Worktree: ${worktree}"

