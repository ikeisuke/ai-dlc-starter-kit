# Unit 003 計画: バリデーションスクリプト統合

## 概要

`validate-uncommitted.sh`（45行）と`validate-remote-sync.sh`（96行）を`validate-git.sh`に統合し、サブコマンド方式（`uncommitted` / `remote-sync` / `all`）で一括実行も可能にする。

## 変更対象ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `prompts/package/bin/validate-git.sh` | 新規作成 | 統合スクリプト（サブコマンド方式） |
| `prompts/package/bin/validate-uncommitted.sh` | 編集 | 互換ラッパー化（非推奨警告 + validate-git.sh委譲） |
| `prompts/package/bin/validate-remote-sync.sh` | 編集 | 互換ラッパー化（非推奨警告 + validate-git.sh委譲） |
| `prompts/package/prompts/operations-release.md` | 編集 | 呼び出し箇所を`validate-git.sh`に更新 |

## 実装計画

### Phase 1: 設計

1. validate-git.shのサブコマンドインターフェース設計（pr-ops.shパターン準拠）
2. 出力形式の互換性確認
3. `all`サブコマンドの出力契約定義

### Phase 2: 実装

1. `validate-git.sh`を新規作成:
   - サブコマンド: `uncommitted`, `remote-sync`, `all`
   - `uncommitted`: validate-uncommitted.shのロジックを`run_uncommitted()`関数として移植
   - `remote-sync`: validate-remote-sync.shのロジックを`run_remote_sync()`関数として移植
   - `all`: uncommitted → remote-sync を順次実行。最初のエラー（exit 1）で停止
   - アーキテクチャ: サブコマンドディスパッチ層（`main`/`case文`）と検証ロジック関数群（`run_*`）を分離
   - 出力形式: 個別サブコマンドは既存と完全互換（`status:ok|warning|error`）
   - ヘルプ: `show_help()`関数（pr-ops.shパターン）
   - `set -euo pipefail`

2. 旧スクリプトを互換ラッパー化:
   - stderr に非推奨警告を出力（構造化形式: `deprecated:{スクリプト名}:use validate-git.sh {サブコマンド}`）
   - `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`で絶対パス化し、`exec "$SCRIPT_DIR/validate-git.sh" ...`で委譲（PATH/カレントディレクトリ非依存）
   - stdout出力・終了コードはそのまま伝播

3. operations-release.mdの呼び出し箇所を更新:
   - `validate-uncommitted.sh` → `validate-git.sh uncommitted`
   - `validate-remote-sync.sh` → `validate-git.sh remote-sync`

## `all`サブコマンドの出力契約

```text
--- uncommitted ---
status:{ok|warning|error}
[追加出力（warning/error時）]
--- remote-sync ---
status:{ok|warning|error}
[追加出力（warning/error時）]
--- summary ---
status:{ok|warning|error}
```

- 各チェックのセクションを`---`区切りで出力
- 末尾に`--- summary ---`セクションで総合結果（単一の`status:`行）を出力
- 総合結果: いずれかがerrorならerror、いずれかがwarningならwarning、全てokならok
- uncommittedがerror（exit 1）の場合、remote-syncはスキップ（`--- remote-sync ---`セクションなし。`--- summary ---`は`status:error`を出力）
- 終了コード: 総合結果がerrorなら1、それ以外は0

## 互換性

- **stdout**: 個別サブコマンド（`uncommitted` / `remote-sync`）の出力形式は既存と完全互換
- **stderr**: 互換ラッパーのみ非推奨警告を出力（構造化形式、stdout汚染なし）
- **終了コード**: ok/warning=0、error=1（完全互換）
- 旧スクリプトは互換ラッパーとして残存（即座削除しない）
- `docs/aidlc/`への同期はOperations Phase（rsync）で実施（本Unit内では正本のみ編集）

## 完了条件チェックリスト

- [x] validate-git.shが3サブコマンド（uncommitted, remote-sync, all）を実装
- [x] 検証ロジックが独立関数（`run_uncommitted` / `run_remote_sync`）として分離
- [x] 旧スクリプトが互換ラッパーとして機能（非推奨警告 + BASH_SOURCE絶対パス基準の委譲）
- [x] operations-release.mdの呼び出し箇所が更新済み
- [x] 出力形式が既存と完全互換（stdoutのみ、stderrは非推奨警告のみ）
- [x] Markdownlintエラーなし
