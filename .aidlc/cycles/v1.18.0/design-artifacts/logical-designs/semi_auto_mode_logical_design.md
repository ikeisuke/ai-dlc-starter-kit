# 論理設計: セミオートモード実装

## 概要

セミオートモードの共通ゲート仕様を `common/rules.md` に集約定義し、各フェーズプロンプトから参照する構成を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**集約ゲートパターン**: 判定ロジックを共通モジュール（`common/rules.md`）に集約し、各フェーズプロンプトは共通ゲート仕様を参照する構造。依存方向は「各フェーズ → common」の一方向に統一。

## コンポーネント構成

### ファイル構成

```text
prompts/package/
├── prompts/
│   ├── common/
│   │   ├── rules.md            ← セミオートゲート共通仕様を追加
│   │   ├── review-flow.md      ← レビュー完了後のゲート呼び出しを追加
│   │   └── context-reset.md    ← セミオート時のスキップロジックを追加
│   ├── construction.md         ← 各承認ポイントに共通ゲート参照を追加
│   ├── inception.md            ← 各承認ポイントに共通ゲート参照を追加
│   └── operations.md           ← 各承認ポイントに共通ゲート参照を追加
└── setup/
    └── templates/
        └── aidlc.toml.template ← [rules.automation] セクション追加
```

### コンポーネント詳細

#### common/rules.md（セミオートゲート共通仕様）

- **責務**: セミオートモードの判定ロジック、フォールバック条件、構造化シグナル、履歴記録フォーマットを一元的に定義
- **依存**: なし（最下位レイヤー）
- **追加セクション**: 「## セミオートゲート仕様【重要】」
- **公開インターフェース**:
  - ゲート判定ロジック（全承認ポイントから参照される）
  - フォールバック条件テーブル（優先順位付き）
  - 構造化シグナルスキーマ
  - 自動承認時の履歴記録フォーマット
  - フォールバック時の履歴記録フォーマット

#### common/review-flow.md（レビューフロー）

- **責務**: AIレビュー完了後にセミオートゲートを呼び出し、結果に応じてユーザー承認をスキップまたは従来フローを実行
- **依存**: common/rules.md（セミオートゲート仕様を参照）
- **変更箇所**:
  1. ステップ4（AIレビューツール利用可能時の選択）: `review_mode=recommend`（`rules.reviewing.mode`）時、`automation_mode=semi_auto` ならユーザー確認をスキップし自動実行
  2. ステップ5（AIレビューフロー）完了後: ゲート判定を追加
  3. ステップ5.5（セルフレビューフロー）完了後: 同上
  4. ステップ7（ユーザーレビューフロー）: セミオート時もユーザーフィードバックがあれば従来フロー

#### common/context-reset.md（コンテキストリセット）

- **責務**: セミオートモード時のコンテキストリセット提示スキップロジック
- **依存**: common/rules.md（セミオートゲート仕様を参照）
- **変更箇所**: 冒頭にセミオートゲート判定を追加。`automation_mode=semi_auto` 時はリセット提示をスキップ

#### common/compaction.md（コンパクション対応）

- **責務**: コンパクション（自動要約）発生時のセミオートモード復帰ロジック
- **依存**: common/rules.md（セミオートゲート仕様・グローバルフォールバック条件を参照）
- **変更箇所**: セミオートモード時のコンパクション対応セクションを追加。`automation_mode=semi_auto` 時はユーザー確認なしで作業を自動継続

#### construction.md（Construction Phase）

- **責務**: 各承認ポイントで共通ゲート参照を通じてセミオート判定を実施
- **依存**: common/rules.md, common/review-flow.md, common/context-reset.md
- **変更箇所**: 8つの承認ポイントに共通ゲート参照ブロックを追加

#### inception.md（Inception Phase）

- **責務**: 各承認ポイントで共通ゲート参照を通じてセミオート判定を実施
- **依存**: common/rules.md, common/review-flow.md
- **変更箇所**: 4つの承認ポイントに共通ゲート参照ブロックを追加

#### operations.md（Operations Phase）

- **責務**: 各承認ポイントで共通ゲート参照を通じてセミオート判定を実施
- **依存**: common/rules.md, common/review-flow.md
- **変更箇所**: 2つの承認ポイントに共通ゲート参照ブロックを追加

#### aidlc.toml.template（設定テンプレート）

- **責務**: 新規プロジェクトの設定テンプレートに `[rules.automation]` セクションを提供
- **依存**: なし
- **変更箇所**: `[rules.automation]` セクション追加

## インターフェース設計

### 共通ゲート参照ブロック（各フェーズ承認ポイントに挿入するテンプレート）

各フェーズの承認ポイントに挿入する統一的な参照ブロック:

```text
**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）:
- `automation_mode=semi_auto` かつフォールバック条件に該当しない場合: 自動承認し次ステップへ進む
- 上記以外: 従来どおりユーザーに承認を求める
```

### 構造化シグナル入出力表

| semi_auto_result | reason_code | fallback_reason | 条件 |
|------------------|-------------|-----------------|------|
| `auto_approved` | `none`（必須） | 空文字（使用しない） | フォールバック条件に該当しない |
| `fallback` | `error`（必須） | エラー内容の説明（必須） | ビルド/テスト失敗、設定読取失敗、実行エラー |
| `fallback` | `review_issues`（必須） | 残存指摘の要約（必須） | AIレビュー指摘が残っている |
| `fallback` | `incomplete_conditions`（必須） | 未達成項目の説明（必須） | 完了条件に未達成項目がある |
| `fallback` | `decision_required`（必須） | 判断が必要な内容（必須） | 技術的判断・選択が必要 |

**バリデーション規則**:
- `semi_auto_result=auto_approved` の場合: `reason_code` は必ず `none`、`fallback_reason` は空文字
- `semi_auto_result=fallback` の場合: `reason_code` は `none` 以外の有効値、`fallback_reason` は空でない文字列
- `automation_mode=manual` の場合: GateResult を生成しない（シグナル対象外）

### 承認ポイント別の挿入位置と追加パラメータ

#### Construction Phase

| 承認ポイントID | 挿入位置 | フォールバック条件の追加パラメータ |
|---------------|---------|-------------------------------|
| `construction.plan.approval` | ステップ5 計画承認の直前 | AIレビュー結果を参照 |
| `construction.design.review` | Phase 1 ステップ3 設計レビュー承認の直前 | AIレビュー結果を参照 |
| `construction.code.review` | Phase 2 ステップ4 コード生成後の承認の直前 | AIレビュー結果を参照 |
| `construction.integration.review` | Phase 2 ステップ6 統合レビュー承認の直前 | AIレビュー結果 + ビルド/テスト結果を参照 |
| `construction.completion.check` | Unit完了時 ステップ0 完了条件確認後 | 完了条件の達成状況を参照 |
| `construction.unit.selection` | ステップ4 Unit選択 | 実行可能Unit数を参照 |
| `construction.context.reset` | ステップ6 コンテキストリセット提示 | グローバルフォールバック（error）のみ適用 |
| `construction.unit_pr.merge` | Unit完了時 ステップ5 Unit PRマージ | グローバルフォールバック（error）のみ適用 |

#### Inception Phase

| 承認ポイントID | 挿入位置 | フォールバック条件の追加パラメータ |
|---------------|---------|-------------------------------|
| `inception.intent.approval` | Intent承認の直前 | AIレビュー結果を参照 |
| `inception.stories.approval` | ユーザーストーリー承認の直前 | AIレビュー結果を参照 |
| `inception.units.approval` | Unit定義承認の直前 | AIレビュー結果を参照 |
| `inception.phase.transition` | Phase遷移ゲート | 全承認完了状態を参照 |

#### Operations Phase

| 承認ポイントID | 挿入位置 | フォールバック条件の追加パラメータ |
|---------------|---------|-------------------------------|
| `operations.plan.approval` | 計画承認の直前 | AIレビュー結果を参照 |
| `operations.step.selection` | ステップ0 変更確認 | グローバルフォールバック（error）のみ適用 |

## 処理フロー概要

### グローバルフォールバック仕様

すべての承認ポイント（「自動実行」ポイント含む）に適用されるグローバルフォールバック条件:

- **設定読取失敗**: `read-config.sh` がエラー（終了コード2）を返した場合 → `fallback(error)`
- **実行エラー**: 前提となる処理（ビルド、テスト、コミット等）がエラーで終了した場合 → `fallback(error)`
- **前提不成立**: ゲート判定に必要なコンテキスト情報が欠落している場合 → `fallback(error)`

グローバルフォールバックは承認ポイント固有のフォールバック条件より先に評価される。

### 承認ポイントでのセミオートゲート判定フロー

**ステップ**:

1. `read-config.sh rules.automation.mode --default "manual"` で `automation_mode` を取得
2. `automation_mode=manual` → ゲート判定スキップ、従来フロー（ユーザー承認を求める）。終了。GateResult は生成しない
3. `automation_mode=semi_auto` → グローバルフォールバック条件（error）を先に評価
4. グローバルフォールバックに該当 → `fallback(error)` シグナルを生成し従来フローへ。履歴記録
5. 承認ポイント固有のフォールバック条件を優先順位順に評価
6. フォールバック条件に該当 → `fallback` シグナルを生成し従来フローへ。履歴記録
7. フォールバック条件に該当しない → `auto_approved` シグナルを生成し次ステップへ自動遷移。履歴記録

**関与するコンポーネント**: common/rules.md, 各フェーズプロンプト

### review-flow.md でのセミオート統合フロー

**ステップ**:

1. AIレビュー完了（指摘0件）
2. セミオートゲート判定（common/rules.md 参照）
3. `auto_approved` → ユーザー承認をスキップ、レビュー後コミットのみ実行
4. `fallback` → 従来どおり成果物をユーザーに提示し承認を求める

**関与するコンポーネント**: common/review-flow.md, common/rules.md

### recommend モードでのセミオート統合フロー

**ステップ**:

1. `automation_mode=semi_auto` を確認
2. review-flow.md ステップ4: ユーザーへの「レビュー実施しますか？」確認をスキップ
3. 自動的にAIレビューを実行
4. 以降は通常のレビューフロー + セミオートゲート判定

**関与するコンポーネント**: common/review-flow.md, common/rules.md

### Unit選択の自動判定フロー

**ステップ**:

1. `automation_mode=semi_auto` を確認
2. 実行可能Unit一覧を取得（番号順ソート済み）
3. 0個 → 全Unit完了
4. 1個以上 → 番号順で最初のUnitを自動選択（ユーザーへの選択肢提示をスキップ）

**関与するコンポーネント**: construction.md

### コンテキストリセットのスキップフロー

**ステップ**:

1. Unit完了時、`automation_mode=semi_auto` を確認
2. `semi_auto` → コンテキストリセット提示をスキップし、次のUnit（または次Phase）を自動開始
3. `manual` → 従来どおりリセット提示

**関与するコンポーネント**: construction.md, common/context-reset.md

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 設定読み取りによる遅延は無視できるレベル
- **対応策**: `read-config.sh` は既存の仕組みを利用。追加のI/Oなし

### 可用性

- **要件**: `automation_mode=manual` 時は現行フローと完全互換
- **対応策**: すべての分岐で `automation_mode=manual` が先に評価され、即座に従来フローへ。セミオート関連のロジックは一切実行されない

## 技術選定

- **言語**: Markdown（プロンプト指示文）、TOML（設定ファイル）
- **ツール**: read-config.sh（既存）、write-history.sh（既存）

## 実装上の注意事項

- **メタ開発**: すべての変更は `prompts/package/` を編集すること（`docs/aidlc/` は rsync コピーのため直接編集禁止）
- **後方互換性**: `automation_mode=manual`（デフォルト）時に従来フローと完全に同じ動作になることを各変更箇所で確認
- **共通ゲート参照の一貫性**: 各フェーズの承認ポイントに挿入する参照ブロックのフォーマットを統一。判定ロジック自体はフェーズ側に記述しない
