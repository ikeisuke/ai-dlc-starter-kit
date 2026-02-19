# Unit 004 計画: コード品質向上

## 概要

`aidlc-git-info.sh` と `env-info.sh` のコード品質を向上させるリファクタリング。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/bin/aidlc-git-info.sh` | strict mode 設定前に IFS 初期化を追加 |
| `prompts/package/bin/env-info.sh` | `cat \| dasel` パターンを stdin リダイレクト（`< file`）に変更 |

## 実装計画

### 1. `aidlc-git-info.sh` の IFS 初期化追加

**現状** (L18):

```bash
set -uo pipefail
```

**変更後**:

```bash
IFS=$' \t\n'
set -uo pipefail
```

**理由**: 環境依存排除のための明示初期化。親プロセスから非標準の IFS が継承された場合、`for` ループや `read` 等のワード分割動作が予期しない結果を返す可能性がある。スクリプト冒頭でデフォルト値（スペース・タブ・改行）に明示設定することで、実行環境に依存しない決定的な動作を保証する。

### 2. `env-info.sh` の `cat | dasel` パターン除去

現在のバージョンの dasel（v2系）は `-f` オプションをサポートしていない（`dasel: error: unknown flag -f`）。代替として stdin リダイレクト（`< file`）を使用する。

**変更箇所（3箇所）**:

#### 2a. L103 `get_project_name` 関数

```bash
# Before:
result=$(cat docs/aidlc.toml | dasel -i toml 'project.name' 2>/dev/null) || { echo ""; return; }

# After:
result=$(dasel -i toml 'project.name' < docs/aidlc.toml 2>/dev/null) || { echo ""; return; }
```

#### 2b. L120 `get_backlog_mode` 関数

```bash
# Before:
result=$(cat docs/aidlc.toml | dasel -i toml 'backlog.mode' 2>/dev/null) || { echo ""; return; }

# After:
result=$(dasel -i toml 'backlog.mode' < docs/aidlc.toml 2>/dev/null) || { echo ""; return; }
```

#### 2c. L205 `get_starter_kit_version` 関数

```bash
# Before:
version=$(cat "$toml_file" | dasel -i toml 'starter_kit_version' 2>/dev/null) || version=""

# After:
version=$(dasel -i toml 'starter_kit_version' < "$toml_file" 2>/dev/null) || version=""
```

## 検証計画

- 各スクリプトの既存動作が変わらないことを確認
  - `aidlc-git-info.sh` の出力が修正前と同一であること
  - `env-info.sh` の出力が修正前と同一であること
  - `env-info.sh --setup` の出力が修正前と同一であること

## 完了条件チェックリスト

- [ ] `aidlc-git-info.sh` の strict mode 設定前に IFS 初期化を追加
- [ ] `env-info.sh` の `cat | dasel` パターンを stdin リダイレクト利用に変更（全3箇所）
- [ ] 既存の出力・動作が完全に維持されていること

## 備考

- Unit定義では「`dasel -f` オプション利用に変更」と記載されているが、現環境の dasel v2 では `-f` オプションが存在しない（`unknown flag -f` エラー）。技術的考慮事項に「`dasel -f` オプションが使用中のバージョンでサポートされていることを確認」とあるため、互換性のある stdin リダイレクト方式を採用する。
