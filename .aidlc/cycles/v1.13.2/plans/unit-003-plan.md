# Unit 003: operations.md行数削減 - 実装計画

## 概要

operations.mdを1,109行から1,000行以下に削減する（109行以上の削減が必要）

## 現状分析

- 現在の行数: 1,109行
- 目標: 1,000行以下
- 必要削減量: 109行以上

## 変更対象ファイル

- `prompts/package/prompts/operations.md`（正本・編集対象）
- `prompts/package/bin/pr-ops.sh`（新規作成）

**注**: `docs/aidlc/prompts/operations.md` は `prompts/package/` のrsyncコピーであり直接編集禁止（`docs/cycles/rules.md` 参照）。Operations Phase完了時のアップグレード処理で自動同期される。

## 削減戦略

### 1. バックログ記録サンプルの削除（約20行削減）

**対象**: 980-997行のバックログ記録サンプル

**理由**: テンプレートファイル（`docs/aidlc/templates/backlog_item_template.md`）が既に存在し、サンプルは冗長

**変更内容**: インラインサンプルを削除し、テンプレート参照のみに

### 2. Keep a Changelog形式サンプルの短縮（約5行削減）

**対象**: 644-656行のChangelogサンプル

**変更内容**: 最小限の骨子例（見出し構造のみ）を残しつつ、詳細サンプルを削減

**残すべき必須情報**:
- `## [X.Y.Z] - YYYY-MM-DD` 形式のヘッダー例
- `### Added`, `### Changed`, `### Fixed` の見出し（内容は削除）
- 外部リンク参照は補助として維持

### 3. PR作成ボディサンプルの短縮（約5行削減）

**対象**: 776-791行のPR作成サンプル

**残すべき必須セクション**:
- `## Summary` - 必須
- `## Test plan` - 必須
- `## Closes` - 必須（Issue連携）
- `Generated with [Claude Code]` 行（現行フォーマット）

**変更内容**: プレースホルダーコメントを削減し、構造のみ維持

### 4. 冗長な説明文の削減（約20行削減）

**対象箇所**:
- 各セクションで繰り返される「ステップ2.5で確認した gh ステータスを参照」→ 初出箇所で説明し、以降は簡略化

**残すべき必須情報**:
- 初出時の完全な説明
- 以降は「（ステップ2.5参照）」のみ

### 5. コマンド例の統合・短縮（約15行削減）

**対象箇所**:
- バージョン確認コマンド例（454-463行）: 3例→2例に削減
- git/ghコマンドの冗長なコメント

**残すべき必須情報**:
- 最低1つの代表的なコマンド例
- 必須オプションの説明

### 6. iOSビルド番号確認セクションの簡略化（約10行削減）

**対象**: 403-438行

**残すべき必須情報（削除禁止）**:
- **前提条件**: `project.type = "ios"` の場合のみ実行（それ以外はスキップ）
- 判定表（status/comparisonの組み合わせと対応）
- status=multiple時の再実行コマンド
- comparison=same時の警告文

**削減対象**:
- 冗長な説明文
- 重複するスキップ条件の記述（前提条件の1回目の記述は維持）

### 7. PRマージセクションの簡略化（約15行削減）

**対象**: 867-908行

**残すべき必須情報（削除禁止）**:
- **前提条件**: `gh:available` 以外の場合はスキップ（手動でマージ）
- マージ方法の3種類（通常/squash/rebase）
- 各マージコマンド（1行ずつ）
- レビュー承認状況確認

**削減対象**:
- マージ方法の詳細説明
- 出力例の冗長な部分

### 8. PR操作のスクリプト化（約30行削減）

**新規スクリプト**: `prompts/package/bin/pr-ops.sh`
- 正本: `prompts/package/bin/pr-ops.sh`
- 呼び出しパス: `docs/aidlc/bin/pr-ops.sh`（rsyncで自動コピー）

**同期タイミングの注意**:
- 新規スクリプト作成後、Operations Phase完了時のアップグレード処理で `docs/aidlc/bin/` にコピーされる
- このサイクル内でスクリプトを使用する場合は、作成後に手動で `rsync` または `cp` でコピーするか、正本パス（`prompts/package/bin/pr-ops.sh`）を直接使用する
- 次サイクル以降は `docs/aidlc/bin/pr-ops.sh` が自動的に存在する

**スクリプト化するコードブロック**:
1. ドラフトPR検索（721-723行）
2. PR Ready化（741-742行）
3. 関連Issue番号取得（706-707行）
4. PRマージ操作（883-895行）

**スクリプトのサブコマンド**:
- `pr-ops.sh find-draft` - 現在のブランチからのドラフトPRを検索
- `pr-ops.sh ready <PR番号>` - ドラフトPRをReady化
- `pr-ops.sh get-related-issues <CYCLE>` - Unit定義から関連Issue番号を取得
- `pr-ops.sh merge <PR番号> [--squash|--rebase]` - PRをマージ

**残すべき必須情報（削除禁止）**:
- **前提条件**: `gh:available` の場合のみ実行（ステップ2.5参照）
- **失敗時フォールバック**: GitHub CLI利用不可時は手動手順を案内
- スクリプト内で `gh` 利用可否をチェックし、利用不可時はメッセージを出力

**operations.mdでの置き換え例**:
```bash
# 変更前（複数行のコードブロック）
CURRENT_BRANCH=$(git branch --show-current)
gh pr list --head "${CURRENT_BRANCH}" --state open --json number,url,isDraft

# 変更後（1行のスクリプト呼び出し）
docs/aidlc/bin/pr-ops.sh find-draft
```

### 9. その他の軽微な削減（約10行削減）

**対象**:
- 空行の最適化
- 重複する注意書き

## 実装計画

1. Phase 1（設計）: 削減対象の詳細特定 ← 現在
2. Phase 2（実装）: operations.mdの編集
3. 行数確認: 1,000行以下になったことを検証

## 完了条件チェックリスト

- [x] `prompts/package/prompts/operations.md` を1,000行以下に削減（998行達成）
- [x] AIレビューフローを `common/review-flow.md` への参照に変更（確認）
- [x] 冗長な記述の削減
- [x] `prompts/package/bin/pr-ops.sh` を作成し、PR操作をスクリプト化

## リスク管理

### 対策済みリスク

1. **正本の扱い**: `prompts/package/prompts/operations.md` のみ編集。`docs/aidlc/` はrsyncで自動同期
2. **自己完結性**: 最小限の例は維持し、外部参照は補助として使用
3. **判断ロジックの欠落**: 各セクションで「残すべき必須情報」を明文化

### 残存リスク

- 削減しすぎると必要な情報が失われる可能性
- 対策: 各変更で「残すべき必須情報」を明確にし、それ以外のみを削減
