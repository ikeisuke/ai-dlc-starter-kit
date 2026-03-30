# Unit 003: シェルスクリプト移行 - 計画

## 概要

全シェルスクリプトを `skills/aidlc/scripts/` に移動し、パス解決メカニズム（AIDLC_PROJECT_ROOT / AIDLC_PLUGIN_ROOT）を導入。設定パスを `.aidlc/config.toml` + `.aidlc/cycles/` に即時移行する。

## 方針決定

- **設定パス**: v2のみ（即時移行）。`docs/aidlc.toml` → `.aidlc/config.toml`、`docs/cycles/` → `.aidlc/cycles/`
- スターターキット自体も `.aidlc/` に移行する

## スクリプト分類

### 移動対象（prompts/package/bin/ → skills/aidlc/scripts/）: 25スクリプト

| スクリプト | docs/aidlc.toml参照 | docs/cycles/参照 | defaults.toml参照 |
|-----------|-------------------|----------------|-----------------|
| read-config.sh | Y | N | Y |
| run-markdownlint.sh | Y | N | N |
| migrate-config.sh | Y | N | N |
| env-info.sh | Y | N | N |
| suggest-version.sh | N | Y | N |
| init-cycle-dir.sh | N | Y | N |
| aidlc-cycle-info.sh | N | Y | N |
| label-cycle-issues.sh | N | Y | N |
| pr-ops.sh | N | Y | N |
| setup-branch.sh | N | Y | N |
| write-history.sh | N | Y | N |
| squash-unit.sh | N | N | N |
| check-backlog-mode.sh | N | N | N |
| resolve-backlog-mode.sh | Y | N | N |
| issue-ops.sh | N | N | N |
| check-gh-status.sh | N | N | N |
| check-issue-templates.sh | N | N | N |
| check-open-issues.sh | N | N | N |
| cycle-label.sh | N | N | N |
| get-default-branch.sh | N | N | N |
| validate-git.sh | N | N | N |
| post-merge-cleanup.sh | N | N | N |
| migrate-backlog.sh | N | N | N |
| aidlc-env-check.sh | N | N | N |
| aidlc-git-info.sh | N | N | N |

### 移動対象（追加）

| 対象 | 移動元 | 移動先 |
|------|-------|-------|
| validate.sh | prompts/package/lib/ | skills/aidlc/scripts/lib/ |
| defaults.toml | docs/aidlc/config/ (prompts/package/config/) | skills/aidlc/config/ |
| tests/ | prompts/package/bin/tests/ | skills/aidlc/scripts/tests/ |
| ios-build-check.sh | prompts/package/bin/ | skills/aidlc/scripts/ |

### 削除対象: 4スクリプト

| スクリプト | 削除理由 |
|-----------|---------|
| resolve-starter-kit-path.sh | AIDLC_PLUGIN_ROOTで代替 |
| sync-package.sh (prompts/package/bin/) | rsync同期はv2で不要 |
| setup-ai-tools.sh | Unit 008 Setupスキルで代替 |
| skills/aidlc-setup/bin/aidlc-setup.sh | Unit 008 Setupスキルで代替 |

**注意**: `prompts/bin/sync-package.sh`（メインのsync-package.sh）は本Unit外。`bin/` 配下のスクリプトも本Unit外。

## ディレクトリ構造移行

### 設定ファイル

- `docs/aidlc.toml` → `.aidlc/config.toml` (git mv)
- `docs/aidlc.local.toml` → `.aidlc/config.local.toml` (git mv、存在する場合)

### サイクルデータ

- `docs/cycles/` → `.aidlc/cycles/` (git mv)

### .gitignore更新

- `.aidlc/config.local.toml` を追加
- 旧 `docs/aidlc.local.toml` を削除

## パス解決メカニズム

### 共通bootstrapライブラリ（`skills/aidlc/scripts/lib/bootstrap.sh`）

パス解決・設定ロード・エラー処理を1か所に集約する。各スクリプトはこのファイルをsourceする。

### 環境変数の契約

| 変数 | 種別 | 外部指定 | 未指定時の挙動 |
|------|------|---------|-------------|
| `AIDLC_PROJECT_ROOT` | 外部入力（依存注入） | 可 | `git rev-parse --show-toplevel` で自動解決。失敗時はfail-fast（exit 1） |
| `AIDLC_PLUGIN_ROOT` | 内部専用 | 不可（上書き禁止） | `dirname "${BASH_SOURCE[0]}"/../../` で自動計算（bootstrap.sh → lib/ → scripts/ → aidlc/） |
| `AIDLC_CONFIG` | 派生値 | 不可 | `$AIDLC_PROJECT_ROOT/.aidlc/config.toml` |
| `AIDLC_CYCLES` | 派生値 | 不可 | `$AIDLC_PROJECT_ROOT/.aidlc/cycles` |
| `AIDLC_DEFAULTS` | 派生値 | 不可 | `$AIDLC_PLUGIN_ROOT/config/defaults.toml` |

### fail-fast方針

`AIDLC_PROJECT_ROOT` が解決できない場合（Git管理外等）:

```text
error:project-root-not-found
```

終了コード1で即座に終了。暗黙フォールバック（pwd等）は行わない。

### bootstrap.shの内容（設計時に詳細化）

```bash
# 外部指定があればそちらを使用、なければ自動解決
if [ -z "${AIDLC_PROJECT_ROOT:-}" ]; then
  AIDLC_PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
    echo "error:project-root-not-found" >&2; exit 1
  }
fi
AIDLC_PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AIDLC_CONFIG="${AIDLC_PROJECT_ROOT}/.aidlc/config.toml"
AIDLC_CYCLES="${AIDLC_PROJECT_ROOT}/.aidlc/cycles"
AIDLC_DEFAULTS="${AIDLC_PLUGIN_ROOT}/config/defaults.toml"
export AIDLC_PROJECT_ROOT AIDLC_PLUGIN_ROOT AIDLC_CONFIG AIDLC_CYCLES AIDLC_DEFAULTS
```

### 各スクリプトでの使用方法

```bash
source "$(dirname "$0")/lib/bootstrap.sh"
```

## プロンプト・ガイド内のパス参照更新

プロンプト内の `docs/aidlc/bin/` → `skills/aidlc/scripts/`、`docs/aidlc.toml` → `.aidlc/config.toml` 等のパス参照更新は、本Unitで**Construction Phaseプロンプト自体が参照するスクリプトパス**を最低限更新する。プロンプトの全面的な書き換えはUnit 004以降で実施。

**本Unitで更新するプロンプト内パス参照**:
- `docs/aidlc/prompts/` 内のスクリプト呼び出しパス（`docs/aidlc/bin/xxx.sh` → `skills/aidlc/scripts/xxx.sh`）
- `docs/aidlc.toml` → `.aidlc/config.toml` への参照（プロンプト内）
- `docs/cycles/` → `.aidlc/cycles/` への参照（プロンプト内）

## 変更対象ファイル

### 新規
- `.aidlc/config.toml` (git mvで移動)
- `.aidlc/cycles/` (git mvで移動)
- `skills/aidlc/scripts/` 配下の全スクリプト (git mvで移動)
- `skills/aidlc/config/defaults.toml` (git mvで移動)

### 更新
- `skills/aidlc/scripts/lib/bootstrap.sh` 新規作成
- 全スクリプトでbootstrap.shをsource
- パス参照を変数に置換
- `.gitignore`
- `.claude/settings.json` のパーミッション

### 削除
- `prompts/package/bin/resolve-starter-kit-path.sh`
- `prompts/package/bin/sync-package.sh`
- `prompts/package/bin/setup-ai-tools.sh`
- `skills/aidlc-setup/bin/aidlc-setup.sh`

## 実装計画

1. `.aidlc/` ディレクトリ作成、設定ファイル・サイクルデータ移動
2. スクリプトを `skills/aidlc/scripts/` に移動（git mv）
3. defaults.toml、lib/、tests/ を移動
4. `bootstrap.sh` を `skills/aidlc/scripts/lib/` に作成
5. 全スクリプトでbootstrap.shをsource、パス参照を変数に置換
6. 不要スクリプト削除
7. `.gitignore`、`.claude/settings.json` 更新
8. プロンプト内のスクリプトパス参照を最低限更新
9. スクリプト動作確認

## 完了条件チェックリスト

- [ ] 全スクリプトが `skills/aidlc/scripts/` に移動されている
- [ ] `bootstrap.sh` が作成され、全スクリプトからsourceされている
- [ ] AIDLC_PROJECT_ROOT はfail-fast（Git管理外で即座にexit 1）
- [ ] 設定パス変更: `.aidlc/config.toml` を参照している
- [ ] サイクルパス変更: `.aidlc/cycles/` を参照している
- [ ] デフォルト設定パス変更: `skills/aidlc/config/defaults.toml` を参照している
- [ ] 不要スクリプト（resolve-starter-kit-path.sh, sync-package.sh, setup-ai-tools.sh, aidlc-setup.sh）が削除されている
