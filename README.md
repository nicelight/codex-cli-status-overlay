# Codex CLI Status Overlay

Мини-репозиторий для воспроизводимой сборки Codex CLI с расширенной строкой статуса.

## ✨ Что добавляет

- `context-window-size` — размер контекстного окна модели.
- `compact-count` — сколько раз сессия была `Compacted`.

`context-window-size` уже есть в upstream `rust-v0.130.0`; этот overlay добавляет `compact-count` и готовый конфиг для вывода обоих значений.

## 🚀 Установка

```bash
git clone https://github.com/nicelight/codex-cli-status-overlay.git
cd codex-cli-status-overlay
scripts/build-install.sh --test
```

Скрипт:

- клонирует официальный `openai/codex`;
- применяет patch из `patches/`;
- собирает `codex`;
- устанавливает бинарник в `~/.local/bin/codex`.

Проверь, что запускается patched-версия:

```bash
which codex
codex --version
```

Если `codex` берется не из `~/.local/bin`, добавь в shell profile:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## ⚙️ Конфиг Codex

Добавь в `~/.codex/config.toml`:

```toml
[tui]
status_line = [
  "model-with-reasoning",
  "current-dir",
  "context-window-size",
  "compact-count",
]
```

Готовый snippet лежит в `config/config.toml.snippet`.

## 🧪 Проверка

```bash
make verify   # patch применим к upstream
make test     # patch + focused tests
make install  # сборка и установка
```

Без `make`:

```bash
scripts/verify.sh
scripts/verify.sh --test
scripts/build-install.sh --test
```

## 📦 Состав

- `upstream.toml` — pinned upstream Codex: `rust-v0.130.0`.
- `patches/` — функциональный patch.
- `scripts/` — проверка, сборка, установка.
- `HANDOFF.md` — техническая передача для сопровождения.

## 🔁 Обновление patch

После правок в локальном checkout Codex:

```bash
scripts/refresh-patch-from-local.sh /path/to/codex
scripts/verify.sh --test
```

Если upstream изменился и patch не применяется, нужно вручную перенести маленькую доработку на новый тег Codex и обновить `upstream.toml`.
