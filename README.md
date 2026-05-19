# Codex CLI Status Overlay

Small reproducible overlay for building Codex CLI with a richer TUI status line.

It takes the official OpenAI Codex source release, applies one focused patch, builds the Rust CLI, and installs the resulting `codex` binary locally. The official install method stays understandable: upstream source + patch + build script.

## What This Adds

- `context-window-size` shows the model context window size in the Codex TUI status line.
- `compact-count` shows how many context compactions the current TUI session has observed.
- `compact-count` updates live when a `ContextCompaction` thread item arrives.
- Replayed thread snapshots are counted, so reopened sessions show the historical compaction count.

Note: `context-window-size` already exists in the pinned upstream `rust-v0.130.0`. This overlay adds `compact-count` and provides a ready-to-use config that displays both items together.

## Quick Start

```bash
git clone https://github.com/nicelight/codex-cli-status-overlay.git
cd codex-cli-status-overlay
scripts/build-install.sh --test
```

By default this:

- clones `https://github.com/openai/codex.git` at `rust-v0.130.0`;
- applies `patches/0001-tui-add-compact-count-status-line-item.patch`;
- runs the focused `codex-tui` tests when `--test` is passed;
- builds `codex` in release mode;
- installs it to `~/.local/bin/codex`.

## Requirements

- `git`
- Rust toolchain through `rustup`
- standard native build tools for Rust crates on your OS
- network access to clone `https://github.com/openai/codex.git`

The upstream Codex checkout contains its own `rust-toolchain.toml`; Cargo and rustup use that to select the expected compiler.

Make sure `~/.local/bin` wins over other Codex install locations:

```bash
which codex
codex --version
```

If `which codex` points somewhere else, put this near the end of your shell profile:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Enable The Status Line

Add this to `~/.codex/config.toml`:

```toml
[tui]
status_line = [
  "model-with-reasoning",
  "current-dir",
  "context-window-size",
  "compact-count",
]
```

The same snippet is stored in `config/config.toml.snippet`.

## Common Commands

Using Make:

```bash
make verify
make test
make install
```

Verify that the patch applies to the pinned upstream without building:

```bash
scripts/verify.sh
```

Verify and run the focused tests:

```bash
scripts/verify.sh --test
```

Build without installing:

```bash
scripts/build-install.sh --no-install
```

Install somewhere else:

```bash
scripts/build-install.sh --install-dir "$HOME/.cargo/bin"
```

Try the overlay against another Codex ref:

```bash
scripts/verify.sh --ref rust-v0.131.0
scripts/build-install.sh --ref rust-v0.131.0 --no-install
```

## Repository Layout

```text
.
├── upstream.toml
├── Makefile
├── patches/
│   └── 0001-tui-add-compact-count-status-line-item.patch
├── scripts/
│   ├── build-install.sh
│   ├── verify.sh
│   └── refresh-patch-from-local.sh
├── config/
│   └── config.toml.snippet
└── HANDOFF.md
```

`upstream.toml` pins the official Codex source ref and commit used to produce this overlay. `patches/` contains the whole functional change. `scripts/` contains the reproducible build, verification, and patch-refresh workflow.

## Updating The Patch

If you make changes in a local Codex checkout, refresh the overlay patch from that checkout:

```bash
scripts/refresh-patch-from-local.sh /path/to/codex
scripts/verify.sh
```

Then update `upstream.toml` only when intentionally moving to another official Codex tag.

## Troubleshooting

`git apply --check` fails:

The upstream TUI code moved. Rebase the patch manually in a Codex checkout, run the focused tests, then refresh the patch with `scripts/refresh-patch-from-local.sh`.

`codex` still launches the official binary:

Your shell is resolving another install first. Run `which codex` and either adjust `PATH` or install the patched binary into the directory that currently wins.

Build fails due to Rust version:

Use the toolchain requested by the upstream Codex repository. The build script invokes Cargo through the checked-out workspace, so `rust-toolchain.toml` should drive `rustup` automatically when Rust is installed.

## Why This Shape

This repository deliberately avoids vendoring or forking the full Codex tree. A small overlay is easier to audit, easier to rebase, and makes the handoff explicit: official source, pinned version, one patch, repeatable commands.
