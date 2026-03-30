# 論理設計: シェルスクリプト移行

## 概要

全シェルスクリプトを `skills/aidlc/scripts/` に集約し、共通bootstrapライブラリによるパス解決メカニズムを導入する。設定パスを `.aidlc/config.toml` + `.aidlc/cycles/` に即時移行する。

## コンポーネント構成

### 1. bootstrap.sh（共通初期化ライブラリ）

**配置先**: `skills/aidlc/scripts/lib/bootstrap.sh`

```bash
#!/usr/bin/env bash
# bootstrap.sh - 共通初期化ライブラリ
# 全スクリプトの冒頭で source して使用する。
# 提供: パス解決、環境変数設定

# --- AIDLC_PROJECT_ROOT ---
# 外部指定（依存注入）があればそちらを使用、なければ自動解決
if [ -z "${AIDLC_PROJECT_ROOT:-}" ]; then
  AIDLC_PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "error:project-root-not-found" >&2; exit 1
  }
fi

# --- AIDLC_PLUGIN_ROOT ---
# 内部専用: bootstrap.sh自身の位置から skills/aidlc/ を算出
# BASH_SOURCE[0] = skills/aidlc/scripts/lib/bootstrap.sh
# → dirname → skills/aidlc/scripts/lib/
# → /.. → skills/aidlc/scripts/
# → /.. → skills/aidlc/
AIDLC_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# --- 派生パス ---
AIDLC_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
AIDLC_LOCAL_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.local.toml"
AIDLC_LOCAL_CONFIG_LEGACY="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml.local"
AIDLC_CYCLES="${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
AIDLC_DEFAULTS="${AIDLC_PLUGIN_ROOT}/config/defaults.toml"

export AIDLC_PROJECT_ROOT AIDLC_PLUGIN_ROOT
export AIDLC_CONFIG AIDLC_LOCAL_CONFIG AIDLC_LOCAL_CONFIG_LEGACY
export AIDLC_CYCLES AIDLC_DEFAULTS
```

**設計ポイント**:

- `AIDLC_PLUGIN_ROOT` は `BASH_SOURCE[0]` 基点で `../../` を辿る（bootstrap.sh は `lib/` 内のため2段上がると `skills/aidlc/`）
- `AIDLC_PROJECT_ROOT` のみ外部注入可能（テスト・CI用）。他は全て派生値
- Git管理外での実行は fail-fast（exit 1）。pwd等への暗黙フォールバックは行わない
- `AIDLC_LOCAL_CONFIG` と `AIDLC_LOCAL_CONFIG_LEGACY` は read-config.sh のレガシーフォールバック用
- **前提**: 呼び出し元のスクリプトが `set -euo pipefail` を設定していること。bootstrap.sh 自身はシェルオプションを変更しない（呼び出し元の設定に従う）

### 2. 各スクリプトでの使用方法

```bash
#!/usr/bin/env bash
set -euo pipefail

# bootstrap.sh の読み込み
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# 以降は AIDLC_PROJECT_ROOT, AIDLC_CONFIG 等の変数を使用
```

`lib/` 配下のスクリプト（validate.sh）からは:

```bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap.sh"
```

### 3. validate.sh の移動

**移動元**: `prompts/package/lib/validate.sh`
**移動先**: `skills/aidlc/scripts/lib/validate.sh`

内容変更なし。bootstrap.sh とは独立して source 可能な関数定義のみのライブラリ。

## スクリプト別パス置換マップ

### カテゴリA: config参照あり（docs/aidlc.toml → AIDLC_CONFIG）

| スクリプト | 置換対象 | 置換後 |
|-----------|---------|--------|
| read-config.sh | `PROJECT_CONFIG_FILE="docs/aidlc.toml"` | `PROJECT_CONFIG_FILE="${AIDLC_CONFIG}"` |
| read-config.sh | `LOCAL_CONFIG_FILE="docs/aidlc.local.toml"` | `LOCAL_CONFIG_FILE="${AIDLC_LOCAL_CONFIG}"` |
| read-config.sh | `LOCAL_CONFIG_FILE_LEGACY="docs/aidlc.toml.local"` | `LOCAL_CONFIG_FILE_LEGACY="${AIDLC_LOCAL_CONFIG_LEGACY}"` |
| read-config.sh | `DEFAULTS_CONFIG_FILE="${SCRIPT_DIR}/../config/defaults.toml"` | `DEFAULTS_CONFIG_FILE="${AIDLC_DEFAULTS}"` |
| run-markdownlint.sh | `docs/aidlc.toml` (dasel読み込み) | `"${AIDLC_CONFIG}"` |
| migrate-config.sh | `CONFIG="docs/aidlc.toml"` | `CONFIG="${AIDLC_CONFIG}"` |
| migrate-config.sh | `RULES="docs/cycles/rules.md"` | `RULES="${AIDLC_CYCLES}/rules.md"` |
| env-info.sh | `"docs/aidlc.toml"` (複数箇所) | `"${AIDLC_CONFIG}"` |
| resolve-backlog-mode.sh | `local config_file="docs/aidlc.toml"` | `local config_file="${AIDLC_CONFIG}"` |

### カテゴリB: cycles参照あり（docs/cycles/ → AIDLC_CYCLES）

| スクリプト | 置換対象 | 置換後 |
|-----------|---------|--------|
| suggest-version.sh | `"docs/cycles/${cycle_name}"` | `"${AIDLC_CYCLES}/${cycle_name}"` |
| suggest-version.sh | `"docs/cycles"` | `"${AIDLC_CYCLES}"` |
| suggest-version.sh | `docs/cycles/*/` | `"${AIDLC_CYCLES}"/*/` |
| init-cycle-dir.sh | `"docs/cycles/${version}"` 等 | `"${AIDLC_CYCLES}/${version}"` 等 |
| init-cycle-dir.sh | `"docs/cycles/backlog"` 等 | `"${AIDLC_CYCLES}/backlog"` 等 |
| aidlc-cycle-info.sh | `docs/cycles/` (複数箇所) | `"${AIDLC_CYCLES}/"` |
| label-cycle-issues.sh | `"docs/cycles/${cycle}/story-artifacts/units"` | `"${AIDLC_CYCLES}/${cycle}/story-artifacts/units"` |
| pr-ops.sh | `"docs/cycles/${cycle}/story-artifacts/units"` | `"${AIDLC_CYCLES}/${cycle}/story-artifacts/units"` |
| write-history.sh | `"docs/cycles/${cycle}/history"` | `"${AIDLC_CYCLES}/${cycle}/history"` |
| setup-branch.sh | `docs/cycles/` 参照（要確認） | `"${AIDLC_CYCLES}/"` |
| migrate-backlog.sh | `OLD_BACKLOG="docs/cycles/backlog.md"` | `OLD_BACKLOG="${AIDLC_CYCLES}/backlog.md"` |
| migrate-backlog.sh | `NEW_BACKLOG_DIR="docs/cycles/backlog"` | `NEW_BACKLOG_DIR="${AIDLC_CYCLES}/backlog"` |
| run-markdownlint.sh | `"docs/cycles/${CYCLE}/**/*.md"` | `"${AIDLC_CYCLES}/${CYCLE}/**/*.md"` |

### カテゴリC: パス参照なし（bootstrap.sh source追加のみ）

squash-unit.sh, check-backlog-mode.sh, issue-ops.sh, check-gh-status.sh, check-issue-templates.sh, check-open-issues.sh, cycle-label.sh, get-default-branch.sh, validate-git.sh, post-merge-cleanup.sh, aidlc-env-check.sh, aidlc-git-info.sh, ios-build-check.sh

### カテゴリD: defaults.toml参照あり

| スクリプト | 置換対象 | 置換後 |
|-----------|---------|--------|
| read-config.sh | `"${SCRIPT_DIR}/../config/defaults.toml"` | `"${AIDLC_DEFAULTS}"` |

## ディレクトリ構造移行

### 設定ファイル移動

```text
docs/aidlc.toml          → .aidlc/config.toml         (git mv)
docs/aidlc.local.toml    → .aidlc/config.local.toml   (git mv、存在する場合)
```

### サイクルデータ移動

```text
docs/cycles/             → .aidlc/cycles/              (git mv)
```

### .gitignore更新

```diff
- docs/aidlc.local.toml
- docs/aidlc.toml.local
+ .aidlc/config.local.toml
+ .aidlc/config.toml.local
```

## スクリプト移動（git mv）

### メインスクリプト（25本）

```text
prompts/package/bin/<script>.sh → skills/aidlc/scripts/<script>.sh
```

対象: read-config.sh, run-markdownlint.sh, migrate-config.sh, env-info.sh, suggest-version.sh, init-cycle-dir.sh, aidlc-cycle-info.sh, label-cycle-issues.sh, pr-ops.sh, setup-branch.sh, write-history.sh, squash-unit.sh, check-backlog-mode.sh, resolve-backlog-mode.sh, issue-ops.sh, check-gh-status.sh, check-issue-templates.sh, check-open-issues.sh, cycle-label.sh, get-default-branch.sh, validate-git.sh, post-merge-cleanup.sh, migrate-backlog.sh, aidlc-env-check.sh, aidlc-git-info.sh

### 追加ファイル

```text
prompts/package/lib/validate.sh        → skills/aidlc/scripts/lib/validate.sh
prompts/package/config/defaults.toml   → skills/aidlc/config/defaults.toml
prompts/package/bin/tests/             → skills/aidlc/scripts/tests/
prompts/package/bin/ios-build-check.sh → skills/aidlc/scripts/ios-build-check.sh
```

### 削除対象（4本）

| スクリプト | 削除理由 |
|-----------|---------|
| prompts/package/bin/resolve-starter-kit-path.sh | AIDLC_PLUGIN_ROOTで代替 |
| prompts/package/bin/sync-package.sh | rsync同期はv2で不要 |
| prompts/package/bin/setup-ai-tools.sh | Unit 008 Setupスキルで代替 |
| skills/aidlc-setup/bin/aidlc-setup.sh | Unit 008 Setupスキルで代替 |

## SCRIPT_DIR → bootstrap.sh の書き換えパターン

### 現行パターン（ほぼ全スクリプト共通）

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/validate.sh"
```

### 移行後パターン

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"
source "${SCRIPT_DIR}/lib/validate.sh"
```

**変更ポイント**:
- `${SCRIPT_DIR}/../lib/validate.sh` → `${SCRIPT_DIR}/lib/validate.sh`（ディレクトリ構造変更に伴う）
- `source "${SCRIPT_DIR}/lib/bootstrap.sh"` を追加
- validate.sh を source するスクリプトのみ（validate.sh不要なスクリプトでは bootstrap.sh のみ source）

### env-info.sh の特殊ケース

env-info.sh は resolve-backlog-mode.sh を source している:

```bash
# 現行
_ENV_INFO_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${_ENV_INFO_SCRIPT_DIR}/resolve-backlog-mode.sh"
```

移行後も同ディレクトリにあるため変更不要。

## .claude/settings.json パーミッション更新

```diff
- "Bash(docs/aidlc/bin/:*)"
- "Bash(prompts/package/bin/*)"
+ "Bash(skills/aidlc/scripts/:*)"
+ "Bash(skills/aidlc/scripts/*)"
```

## プロンプト内のパス参照更新（最低限）

本Unitでは、Construction Phaseプロンプト自体が参照するスクリプトパスを更新する。プロンプトの全面的な書き換えはUnit 004以降。

### 更新対象

- `docs/aidlc/prompts/` 内のスクリプト呼び出しパス
  - `docs/aidlc/bin/xxx.sh` → `skills/aidlc/scripts/xxx.sh`
  - `prompts/package/bin/xxx.sh` → `skills/aidlc/scripts/xxx.sh`
- 設定ファイル参照
  - `docs/aidlc.toml` → `.aidlc/config.toml`
- サイクルデータ参照
  - `docs/cycles/` → `.aidlc/cycles/`

## 実装手順

1. `.aidlc/` ディレクトリ作成、設定ファイル・サイクルデータを git mv で移動
2. `.gitignore` 更新
3. スクリプトを `skills/aidlc/scripts/` に git mv で移動
4. lib/validate.sh、config/defaults.toml、tests/ を git mv で移動
5. `bootstrap.sh` を `skills/aidlc/scripts/lib/` に新規作成
6. 全スクリプトで bootstrap.sh を source、パス参照を変数に置換
7. 不要スクリプト4本を削除
8. `.claude/settings.json` パーミッション更新
9. プロンプト内のスクリプトパス参照を最低限更新
10. スクリプト動作確認（bash -n による構文チェック + 主要スクリプトの実行テスト）

## テスト戦略

### 構文チェック

全スクリプトに対して `bash -n` を実行し、構文エラーがないことを確認。

### 機能テスト

- `read-config.sh`: 設定値の読み込みが正常に動作すること
- `env-info.sh`: 依存ツールの状態が正しく出力されること
- `suggest-version.sh`: バージョン推測が正しく動作すること
- `init-cycle-dir.sh --dry-run`: ディレクトリ作成パスが `.aidlc/cycles/` を指すこと

### 既存テスト

`skills/aidlc/scripts/tests/` に移動したテストが正常に動作すること。
