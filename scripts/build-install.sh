#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_FILE="${ROOT_DIR}/upstream.toml"
PATCH_DIR="${ROOT_DIR}/patches"

repo_url="$(sed -nE 's/^repo = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"
upstream_ref="$(sed -nE 's/^ref = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"
expected_commit="$(sed -nE 's/^commit = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"
codex_rs_dir="$(sed -nE 's/^codex_rs_dir = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")"

cache_root="${XDG_CACHE_HOME:-${HOME}/.cache}/codex-cli-status-overlay"
worktree="${cache_root}/codex-${upstream_ref}"
install_dir="${HOME}/.local/bin"
run_tests=0
force_clean=0
install_binary=1

usage() {
  cat <<'USAGE'
Build and install a patched Codex CLI with status-line compaction count.

Usage:
  scripts/build-install.sh [options]

Options:
  --ref REF           Upstream Codex git ref/tag to checkout.
  --worktree DIR      Build worktree directory. Defaults to XDG cache.
  --install-dir DIR   Where to install the codex binary. Defaults to ~/.local/bin.
  --no-install        Build only; leave binary in the worktree target directory.
  --test              Run focused codex-tui tests after applying patches.
  --force-clean       Recreate the cached worktree before building.
  -h, --help          Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ref)
      upstream_ref="${2:?missing value for --ref}"
      worktree="${cache_root}/codex-${upstream_ref}"
      shift 2
      ;;
    --worktree)
      worktree="${2:?missing value for --worktree}"
      shift 2
      ;;
    --install-dir)
      install_dir="${2:?missing value for --install-dir}"
      shift 2
      ;;
    --no-install)
      install_binary=0
      shift
      ;;
    --test)
      run_tests=1
      shift
      ;;
    --force-clean)
      force_clean=1
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

if [[ -z "${repo_url}" || -z "${upstream_ref}" || -z "${codex_rs_dir}" ]]; then
  echo "Invalid upstream.toml: repo, ref, and codex_rs_dir are required." >&2
  exit 1
fi

if [[ "${force_clean}" == "1" ]]; then
  rm -rf "${worktree}"
fi

if [[ ! -d "${worktree}/.git" ]]; then
  mkdir -p "$(dirname "${worktree}")"
  git clone --branch "${upstream_ref}" --depth 1 "${repo_url}" "${worktree}"
else
  git -C "${worktree}" fetch --tags --force origin
  git -C "${worktree}" reset --hard "${upstream_ref}"
  git -C "${worktree}" clean -fd
fi

actual_commit="$(git -C "${worktree}" rev-parse HEAD)"
if [[ -n "${expected_commit}" && "${upstream_ref}" == "$(sed -nE 's/^ref = "([^"]+)"/\1/p' "${UPSTREAM_FILE}")" && "${actual_commit}" != "${expected_commit}" ]]; then
  echo "Warning: ${upstream_ref} resolved to ${actual_commit}, expected ${expected_commit}." >&2
fi

for patch in "${PATCH_DIR}"/*.patch; do
  echo "Applying $(basename "${patch}")"
  git -C "${worktree}" apply "${patch}"
done

if [[ "${run_tests}" == "1" ]]; then
  cargo test --manifest-path "${worktree}/${codex_rs_dir}/Cargo.toml" --locked -p codex-tui status_line_compact_count
fi

cargo build --manifest-path "${worktree}/${codex_rs_dir}/Cargo.toml" --locked --release -p codex-cli --bin codex

binary="${worktree}/${codex_rs_dir}/target/release/codex"
if [[ "${install_binary}" == "1" ]]; then
  mkdir -p "${install_dir}"
  destination="${install_dir}/codex"
  if [[ -e "${destination}" ]]; then
    backup="${destination}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "${destination}" "${backup}"
    echo "Existing codex backed up to ${backup}"
  fi
  install -m 0755 "${binary}" "${destination}"
  echo "Installed patched codex to ${destination}"
  if ! command -v codex >/dev/null 2>&1 || [[ "$(command -v codex)" != "${destination}" ]]; then
    echo "Note: your shell currently resolves codex to: $(command -v codex 2>/dev/null || echo '<not found>')"
    echo "Put ${install_dir} before other Codex install locations in PATH to use this binary by default."
  fi
else
  echo "Built patched codex at ${binary}"
fi

echo
echo "Recommended ~/.codex/config.toml status line:"
sed 's/^/  /' "${ROOT_DIR}/config/config.toml.snippet"

