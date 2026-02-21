# Unit 001 計画: operations.md定型処理スクリプト化

## 概要

operations.mdの定型処理（リモート同期確認 6.6.6、コミット漏れ確認 6.6.5）をシェルスクリプトに切り出し、プロンプトファイルを1000行以内に削減する。

## 変更対象ファイル

### 新規作成

| ファイル | 説明 |
|---------|------|
| `prompts/package/bin/validate-uncommitted.sh` | コミット漏れ確認スクリプト |
| `prompts/package/bin/validate-remote-sync.sh` | リモート同期確認スクリプト |

### 修正

| ファイル | 説明 |
|---------|------|
| `prompts/package/prompts/operations.md` | 6.6.5・6.6.6セクションをスクリプト呼び出しに置換 |

### パス整合ルール

- **編集対象**: `prompts/package/bin/` および `prompts/package/prompts/`
- **operations.md内の実行コマンド**: `docs/aidlc/bin/` パスで記述（rsync反映後のパス）
- Operations PhaseのrsyncでOK: `prompts/package/bin/` → `docs/aidlc/bin/`

## 責務境界

- **スクリプト**: 機械可読な事実のみを返す（key:value形式のステータスとデータ）
- **operations.md**: スクリプト出力を解釈し、ユーザー向けの復旧ガイダンス・警告文を提示する責務を持つ

## 命名規則

新規スクリプトは `validate-*` を使用する。既存の `check-*` は「状態の確認」（gh利用可否等）に対し、`validate-*` は「PRマージ前の検証」という異なる目的を持つため区別する。ユーザーストーリーの受け入れ基準で `validate-*` が明示指定されている。ヘッダコメント・使用方法・出力仕様の記載スタイルは既存 `check-*` と統一する。

## 出力契約

### validate-uncommitted.sh

| キー | 必須/任意 | 値形式 | 説明 |
|------|----------|--------|------|
| `status` | 必須 | `ok` / `warning` | 判定結果 |
| `files_count` | 任意（warning時） | 数値 | 変更ファイル件数 |
| `file` | 任意（warning時） | 単一パス（1行に1つ、複数行可） | 変更ファイルパス |

- exit 0: 正常終了（ok/warning共に）
- 出力例（warning時）: `status:warning` → `files_count:3` → `file:docs/x.md` → `file:src/y.ts` → `file:test/z.ts`

### validate-remote-sync.sh

| キー | 必須/任意 | 値形式 | 説明 |
|------|----------|--------|------|
| `status` | 必須 | `ok` / `warning` / `error` | 判定結果 |
| `remote` | 必須（warning/error時） | 単一値 | リモート名（例: origin。取得不可時: unknown） |
| `branch` | 必須（warning/error時） | 単一値 | ブランチ名（取得不可時: unknown） |
| `unpushed_commits` | 任意（warning時） | 数値 | 未pushコミット件数 |
| `error` | 必須（error時） | `fetch-failed` / `no-upstream` / `log-failed` / `branch-unresolved` | エラー種別 |

- exit 0: 正常終了（ok/warning）
- exit 1: 異常終了（error）、エラーメッセージをstderrに出力

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 各スクリプトの入出力仕様、エラーハンドリング、既存スクリプトとの整合性を定義
2. **論理設計**: スクリプトの処理フロー、operations.mdの置換内容を設計
3. **設計レビュー**

### Phase 2: 実装

4. **スクリプト実装**
   - `validate-uncommitted.sh`: `git status --porcelain` を実行し、出力契約に従って結果を出力
   - `validate-remote-sync.sh`: Step 0（リモート名解決）→ A（fetch）→ B（追跡ブランチ解決）→ C（未pushコミット検出）
5. **operations.md修正**: 6.6.5（33行）・6.6.6（97行）をスクリプト呼び出し + ステータス別AI判定指示に置換。ユーザー向け復旧ガイダンスはoperations.mdに残す
6. **回帰確認**: ユーザーストーリー3の受け入れ基準に定義された全ケースを実行

### 行数削減見込み

- 現在: 1033行
- 削除: 約130行（6.6.5: 33行、6.6.6: 97行）
- 追加: 約30行（スクリプト呼び出し + 結果判定の記述）
- 見込み: 約933行（1000行以内の目標達成）

## 完了条件チェックリスト

- [x] `validate-remote-sync.sh` が実装されている（リモート同期確認ロジック）
- [x] `validate-uncommitted.sh` が実装されている（コミット漏れ確認ロジック）
- [x] operations.mdの該当セクションがスクリプト呼び出しに置き換えられている
- [x] operations.mdの行数が1000行以内になっている（`wc -l` で確認）→ 996行
- [x] 各スクリプトが出力契約に従った `status:ok` / `status:warning` / `status:error` 形式で結果を出力する
- [x] スクリプト異常終了時に exit code 1 を返し、エラーメッセージを stderr に出力する
- [x] リモート疎通不可、未追跡ブランチ等の異常系で適切なエラーメッセージを出力する
- [x] 回帰確認（ユーザーストーリー3の全ケース）が完了している → 9/9 PASS
- [x] rsync同期が正常に動作する（`prompts/package/bin/` → `docs/aidlc/bin/`）
- [x] operations.md内の実行コマンドパスが `docs/aidlc/bin/` になっていること
- [x] 既存スクリプトに変更がないこと
