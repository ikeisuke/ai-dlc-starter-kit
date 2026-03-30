# Unit 001: セミオートモード実装 - 計画

## 概要

AI-DLCのセミオートモードを実装する。`docs/aidlc.toml` の `rules.automation.mode` で制御し、`semi_auto` 設定時にAIレビュー合格（指摘0件）でユーザー承認を省略して自動的に次ステップ・次Unit・次フェーズへ遷移する。

## 変更対象ファイル

| # | ファイル | 変更内容 |
|---|---------|---------|
| 1 | `prompts/setup/templates/aidlc.toml.template` | `[rules.automation]` セクション追加 |
| 2 | `prompts/package/prompts/common/rules.md` | セミオートゲート共通仕様（判定ロジック・フォールバック・履歴記録）の集約定義 |
| 3 | `prompts/package/prompts/common/review-flow.md` | レビュー完了後のセミオートゲート呼び出し追加 |
| 4 | `prompts/package/prompts/construction.md` | 各承認ポイントに共通ゲート参照を追加 |
| 5 | `prompts/package/prompts/inception.md` | 各承認ポイントに共通ゲート参照を追加 |
| 6 | `prompts/package/prompts/operations.md` | 各承認ポイントに共通ゲート参照を追加 |
| 7 | `prompts/package/prompts/common/context-reset.md` | セミオート時のスキップロジック追加 |
| 8 | `docs/aidlc.toml`（プロジェクト設定） | `[rules.automation]` セクション追加 |

## 設計方針

### セミオートゲートの集約アーキテクチャ

セミオート判定ロジック・フォールバック判定・履歴記録を **`common/rules.md` に集約定義** し、各フェーズプロンプトは「共通ゲートを参照するだけ」の構造にする。これにより：

- 判定ルール変更時の修正箇所が1ヶ所に集約される
- フェーズ間で判定ロジックの不整合が発生しない
- 各フェーズは共通仕様を参照するだけなので変更量が最小化される

### 構造化シグナル

文字列マーカーではなく、**固定スキーマの構造化された判定結果**を共通仕様として定義する。

| キー | 型 | 説明 |
|------|---|------|
| `semi_auto_result` | `auto_approved` \| `fallback` | ゲート判定結果 |
| `reason_code` | `error` \| `review_issues` \| `incomplete_conditions` \| `decision_required` \| `none` | フォールバック理由コード（`auto_approved` 時は `none`） |
| `fallback_reason` | 文字列 | ユーザー向け表示用メッセージ（`fallback` 時のみ使用） |

各フェーズはこの3キーのみを参照する。

## 実装計画

### 内部フェーズ1: 設定・モード判定基盤

#### 1.1 `aidlc.toml.template` に設定セクション追加

```toml
[rules.automation]
# 自動化設定（v1.18.0で追加）
# mode: "manual" | "semi_auto"
# - manual: 従来どおりすべての承認ポイントでユーザー確認（デフォルト）
# - semi_auto: AIレビュー合格時にユーザー承認を省略し自動遷移
mode = "manual"
```

#### 1.2 `common/rules.md` にセミオートゲート共通仕様を集約定義

以下の内容を追加:

**セミオートゲート仕様**:

1. **設定読み取り**: `read-config.sh rules.automation.mode --default "manual"`
2. **ゲート判定ロジック**（全承認ポイント共通）:
   - `mode=manual` → 従来フロー（ユーザー承認を求める）
   - `mode=semi_auto` + 以下のフォールバック条件に該当 → 従来フロー
   - `mode=semi_auto` + フォールバック条件に該当しない → 自動承認

3. **フォールバック条件**（優先順位順、該当した時点で従来フローに戻す）:

   | 優先度 | reason_code | 条件 | ユーザーへのメッセージ方針 |
   |--------|-------------|------|------------------------|
   | 1 | `error` | ビルド/テスト失敗またはエラー発生 | エラー内容を提示し対応を求める |
   | 2 | `review_issues` | AIレビュー指摘が残っている | 指摘一覧を提示し判断を求める |
   | 3 | `incomplete_conditions` | 完了条件に未達成項目がある | 未達成項目を提示し判断を求める |
   | 4 | `decision_required` | 技術的判断・選択が必要 | 選択肢を提示し判断を求める |

4. **自動承認時の履歴記録**:

   ```text
   【セミオート自動承認】
   - 承認ポイント: {承認ポイントID}
   - 判定結果: auto_approved
   - AIレビュー結果: 指摘0件
   ```

5. **フォールバック時の履歴記録**:

   ```text
   【セミオートフォールバック】
   - 承認ポイント: {承認ポイントID}
   - 判定結果: fallback
   - reason_code: {reason_code}
   - 詳細: {具体的な理由}
   ```

6. **承認ポイントID命名規則**: `{phase}.{context}.{step}`
   - 例: `construction.plan.approval`, `construction.design.review`, `inception.intent.approval`

#### 1.3 プロジェクト設定 `docs/aidlc.toml` に追加

既存プロジェクトにも `[rules.automation]` セクションを追加。

### 内部フェーズ2: 承認・遷移の自動化

#### 2.1 `review-flow.md` の変更

- **recommend モード時の自動実施**: セミオート有効時、AIレビュー実施確認（ステップ4）をスキップし自動的にレビュー実行
- **レビュー完了後の共通ゲート呼び出し**: AIレビュー完了（指摘0件）後、`common/rules.md` のセミオートゲート仕様に従い判定を実施。結果に応じて自動承認または従来フローに分岐

#### 2.2 `construction.md` の承認ポイント変更

各承認ポイントに共通ゲートへの参照を追加（判定ロジック自体は記述しない）:

| 承認ポイントID | 承認ポイント | セミオート時の動作 |
|---------------|-------------|-----------------|
| `construction.plan.approval` | ステップ5: 計画承認 | AIレビュー合格後、自動承認 |
| `construction.design.review` | Phase 1 ステップ3: 設計レビュー | AIレビュー合格後、自動承認→Phase 2へ |
| `construction.code.review` | Phase 2 ステップ4: コード生成後 | AIレビュー合格後、自動承認 |
| `construction.integration.review` | Phase 2 ステップ6: 統合とレビュー | AIレビュー合格後、自動承認 |
| `construction.completion.check` | ステップ0: 完了条件確認 | 全条件達成時、自動承認 |
| `construction.unit.selection` | ステップ4: Unit選択 | 番号順に自動選択 |
| `construction.context.reset` | ステップ6: コンテキストリセット | スキップし自動で次Unitへ |
| `construction.unit_pr.merge` | Unit完了時: Unit PRマージ | 自動でPR準備・マージ |

#### 2.3 `inception.md` の承認ポイント変更

| 承認ポイントID | 承認ポイント | セミオート時の動作 |
|---------------|-------------|-----------------|
| `inception.intent.approval` | Intent承認 | AIレビュー合格後、自動承認 |
| `inception.stories.approval` | ユーザーストーリー承認 | AIレビュー合格後、自動承認 |
| `inception.units.approval` | Unit定義承認 | AIレビュー合格後、自動承認 |
| `inception.phase.transition` | Phase遷移ゲート | 全承認完了時、自動遷移 |

#### 2.4 `operations.md` の承認ポイント変更

| 承認ポイントID | 承認ポイント | セミオート時の動作 |
|---------------|-------------|-----------------|
| `operations.plan.approval` | 計画承認 | AIレビュー合格後、自動承認 |
| `operations.step.selection` | ステップ選択・スキップ判断 | デフォルト選択で自動進行 |

#### 2.5 `context-reset.md` の変更

セミオート有効時、Unit完了後のコンテキストリセット提示をスキップし、次のUnitを自動開始する条件を追加。

### 内部フェーズ3: フォールバック・検証

#### 3.1 フォールバック条件の整合性確認

`common/rules.md` に集約定義したフォールバック条件が、各承認ポイントで正しく参照・適用されていることを確認。

#### 3.2 `mode=manual` 時の完全互換検証

すべての変更箇所で `mode=manual`（デフォルト）時に従来フローと完全に同じ動作になることを確認。条件分岐の追加部分が既存フローに影響を与えていないことをレビュー。

## 完了条件チェックリスト

- [x] `aidlc.toml` テンプレートへの `[rules.automation]` セクション追加
- [x] `read-config.sh` による `rules.automation.mode` 取得の検証
- [x] 共通セミオートゲート仕様の定義（判定ロジック・フォールバック条件・構造化シグナル・履歴記録・承認ポイントID命名規則）
- [x] 各フェーズプロンプト（inception.md, construction.md, operations.md）の承認ポイントに共通ゲート参照を追加
- [x] `review-flow.md` のレビュー完了後フローに共通ゲート呼び出しを追加
- [x] フェーズ完了時のコンテキストリセット提示をセミオート時スキップ
- [x] Unit選択の自動判定ロジック（番号順）
- [x] フォールバック条件の統一的定義（優先順位・reason_code・メッセージ方針）
- [x] `mode=manual`（デフォルト）時の完全互換検証
