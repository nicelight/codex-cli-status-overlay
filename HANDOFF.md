# Handoff

## Purpose

This repository reproduces a local Codex CLI TUI modification without carrying a full fork of `openai/codex`.

The intended handoff contract is:

1. Clone official Codex at the pinned upstream ref.
2. Apply every patch in `patches/`.
3. Build `codex-cli` from `codex-rs`.
4. Put the resulting `codex` binary earlier in `PATH` than the official npm, Homebrew, or release binary.
5. Enable status-line items in `~/.codex/config.toml`.

## Pinned Upstream

- Repo: `https://github.com/openai/codex.git`
- Ref: `rust-v0.130.0`
- Commit: `58573da43ab697e8b79f152c53df4b42230395a8`
- Rust workspace: `codex-rs`

The source of truth is `upstream.toml`.

## Functional Change

Patch: `patches/0001-tui-add-compact-count-status-line-item.patch`

The patch adds one selectable TUI status-line item:

- ID: `compact-count`
- Display: `N compacted`
- State: `ChatWidget::compact_count`
- Trigger: increments on `ThreadItem::ContextCompaction`
- Replay behavior: replayed context compaction items also increment the count

The pinned upstream already has:

- ID: `context-window-size`
- Display: compact token count such as `950K window`

## Touched Upstream Files

- `codex-rs/tui/src/bottom_pane/status_line_setup.rs`
- `codex-rs/tui/src/bottom_pane/status_line_style.rs`
- `codex-rs/tui/src/bottom_pane/status_surface_preview.rs`
- `codex-rs/tui/src/chatwidget.rs`
- `codex-rs/tui/src/chatwidget/status_surfaces.rs`
- `codex-rs/tui/src/chatwidget/tests/helpers.rs`
- `codex-rs/tui/src/chatwidget/tests/status_and_layout.rs`

## Validation

Fast patch validation:

```bash
scripts/verify.sh
```

Focused behavioral validation:

```bash
scripts/verify.sh --test
```

The focused test selector is:

```bash
cargo test --manifest-path <codex>/codex-rs/Cargo.toml --locked -p codex-tui status_line_compact_count
```

## Rebase Procedure

1. Update `upstream.toml` to the new official Codex tag and commit.
2. Run `scripts/verify.sh --ref <new-ref>`.
3. If the patch fails, clone or reuse a Codex checkout and port the small change manually.
4. Run the focused tests in that checkout.
5. Refresh the overlay patch:

```bash
scripts/refresh-patch-from-local.sh /path/to/codex
```

6. Run `scripts/verify.sh --test`.

## User Config

Recommended `~/.codex/config.toml` snippet:

```toml
[tui]
status_line = [
  "model-with-reasoning",
  "current-dir",
  "context-window-size",
  "compact-count",
]
```

## Operational Notes

- The overlay does not patch installed binaries.
- The overlay does not modify `~/.codex/config.toml` automatically.
- `scripts/build-install.sh` backs up an existing destination binary before replacing it.
- The default install destination is `~/.local/bin/codex`.
- If `~/.local/bin` is not first in `PATH`, the official Codex binary may still be used.

