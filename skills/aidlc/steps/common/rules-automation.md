# 自動化ルール

## セミオートゲート仕様【重要】

`automation_mode=semi_auto` の場合、承認ポイントでフォールバック条件に該当しなければ自動承認する。

### 判定ロジック

1. `manual` → 従来フロー（全承認ポイントでユーザー確認）
2. `semi_auto` → グローバルフォールバック評価 → 固有フォールバック評価 → 該当なしなら `auto_approved`

### グローバルフォールバック条件

設定読取失敗（exit code 2）、実行エラー、前提情報の欠落

### フォールバック条件テーブル

| 優先度 | reason_code | 条件 |
|--------|-------------|------|
| 0 | `review_not_executed` | AIレビュー未実施 |
| 1 | `error` | ビルド/テスト失敗 |
| 2 | `review_issues` | `unresolved_count > 0` |
| 3 | `incomplete_conditions` | 完了条件に未達成項目 |
| 4 | `decision_required` | 技術的判断が必要 |

`auto_approved` の条件: `unresolved_count == 0`（全件が修正済みまたは判断フロー完了）

### レビュー結果シグナル

review-flow.md が生成し、ゲート判定で参照する。承認ポイント内でのみ有効。

| シグナル | 型 | 説明 |
|---------|-----|------|
| `review_detected` | boolean | 1件以上の指摘が検出されたか |
| `deferred_count` | integer | OUT_OF_SCOPE + TECHNICAL_BLOCKER 件数 |
| `resolved_count` | integer | 修正済み件数 |
| `unresolved_count` | integer | 未対応件数 |

### 構造化シグナル

| 結果 | reason_code | 条件 |
|------|-------------|------|
| `auto_approved` | `none` | フォールバック条件に該当しない |
| `fallback` | 上記テーブルの値 | フォールバック条件に該当 |

### 承認ポイントID

`{phase}.{context}.{step}` 形式（例: `construction.plan.approval`）

## エクスプレスモード仕様

`/aidlc express` で有効化。Inception→Construction→Operationsを自動遷移する。

### 適用条件（すべて満たす場合に有効）

1. `express_enabled=true`
2. 全Unitの複雑度判定が `eligible`
3. Unit数が1以上

### 複雑度判定

| 評価項目 | eligible | ineligible |
|----------|----------|------------|
| 受け入れ基準 | 具体的で検証可能 | 曖昧・未定義 |
| 依存関係 | 線形 | 循環・多段分岐 |
| 技術的リスク | 既知技術 | 未使用技術・アーキ変更 |
| 変更影響範囲 | 限定的 | 不明確・横断的 |

### 有効時の動作

- Inception完了後のコンテキストリセットをスキップし、Constructionに自動遷移
- `depth_level=minimal`: Phase 1（設計）をスキップ
- `depth_level=standard/comprehensive`: Phase 1から通常実行
- 適用条件を満たさない場合は通常フローにフォールバック
