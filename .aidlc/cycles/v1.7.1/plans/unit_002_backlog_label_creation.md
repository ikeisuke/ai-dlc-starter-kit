# Unit 002: backlogラベル自動作成 - 実行計画

## 概要

Issue駆動バックログ使用時に、必要なラベル（backlog, type:xxx, priority:xxx, cycle:vX.X.X）が存在しない場合に自動作成する機能を追加する。

## 対象ファイル

- `prompts/package/prompts/setup.md` - ラベル存在確認・自動作成ロジック追加
- `prompts/package/prompts/inception.md` - サイクルラベル付与ロジック追加

## Phase 1: 設計

### ステップ1: ドメインモデル設計

**責務定義**:

1. **ラベル種類**
   - `backlog`: バックログ項目識別用
   - `type:feature`, `type:bugfix`, `type:chore`, `type:refactor`, `type:docs`, `type:perf`, `type:security`: 種類分類
   - `priority:high`, `priority:medium`, `priority:low`: 優先度分類
   - `cycle:vX.X.X`: サイクル紐付け用

2. **ラベル作成タイミング**
   - setup.md: 基本ラベル（backlog, type:xxx, priority:xxx）の確認・作成
   - inception.md: サイクルラベル（cycle:vX.X.X）の確認・作成

3. **ラベル作成条件**
   - backlog.mode = "issue" の場合のみ実行
   - GitHub CLIが利用可能かつ認証済みの場合のみ実行

### ステップ2: 論理設計

**setup.md への追加位置**: ステップ0.7「バックログモード確認」の後に新ステップを追加

**ラベル定義**（カラーコードは`#`なしで指定）:

```text
backlog        : "FBCA04" (黄色) - バックログ項目
type:feature   : "1D76DB" (青)   - 新機能
type:bugfix    : "D93F0B" (赤)   - バグ修正
type:chore     : "0E8A16" (緑)   - 雑務・メンテナンス
type:refactor  : "5319E7" (紫)   - リファクタリング
type:docs      : "0075CA" (青)   - ドキュメント
type:perf      : "FBCA04" (黄)   - パフォーマンス
type:security  : "B60205" (暗赤) - セキュリティ
priority:high  : "D93F0B" (赤)   - 高優先度
priority:medium: "FBCA04" (黄)   - 中優先度
priority:low   : "0E8A16" (緑)   - 低優先度
```

**inception.md への追加位置**: 「## 完了時の必須作業【重要】」セクション内、「### 1. 履歴記録」の前

### ステップ3: 設計レビュー

上記設計の承認を得てからPhase 2に進む

## Phase 2: 実装

### ステップ4: コード生成

1. setup.md にステップ0.8「ラベル確認・作成」を追加
2. inception.md にサイクルラベル作成ロジックを追加

### ステップ5: テスト生成

- プロンプトのため、手動テストで確認
- ラベル作成コマンドの動作確認

### ステップ6: 統合とレビュー

- Markdownlint実行
- 実装記録作成

## 成果物

- `docs/cycles/v1.7.1/design-artifacts/domain-models/002_backlog_label_creation_domain_model.md`
- `docs/cycles/v1.7.1/design-artifacts/logical-designs/002_backlog_label_creation_logical_design.md`
- `prompts/package/prompts/setup.md` (更新)
- `prompts/package/prompts/inception.md` (更新)
- `docs/cycles/v1.7.1/construction/units/002_backlog_label_creation_implementation.md`

## 関連Issue

- #23
