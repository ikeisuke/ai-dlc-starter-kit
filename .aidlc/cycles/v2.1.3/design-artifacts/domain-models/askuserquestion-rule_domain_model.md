# ドメインモデル: AskUserQuestion使用ルールの追加

## 概要

AIエージェントがユーザーとの対話で使用するインタラクション種別を3分類し、各分類に応じた適切なツール使用を定義するルール。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### InteractionType（インタラクション種別）

3種類のインタラクションを定義する列挙型。

| 種別 | 定義 | 判定基準 |
|------|------|---------|
| `gate_approval` | フェーズ/ステップの進行承認 | ワークフロー上の承認ポイントに対応する |
| `user_choice` | ユーザーの明示的な選択が必要な場面 | 複数の選択肢から1つを選ぶ必要がある |
| `information_gathering` | ユーザーからの情報入力が必要な場面 | 自由入力やコンテキスト提供が必要 |

### ActionPolicy（対応方針）

各インタラクション種別に紐づく対応方針。

| 種別 | `manual` モード | `semi_auto` モード |
|------|----------------|-------------------|
| `gate_approval` | ユーザーに承認を求める | セミオートゲート仕様に従い `auto_approved` / `fallback` |
| `user_choice` | AskUserQuestion必須 | AskUserQuestion必須（自動化対象外） |
| `information_gathering` | AskUserQuestion必須 | AskUserQuestion必須（自動化対象外） |

## 集約（Aggregate）

### AskUserQuestionRule（使用ルール集約）

- **集約ルート**: AskUserQuestionRule
- **含まれる要素**: InteractionType, ActionPolicy
- **境界**: `steps/common/rules.md` 内の1セクション
- **不変条件**:
  - `user_choice` と `information_gathering` は `automation_mode` に関わらず常にAskUserQuestionツールを使用する
  - `gate_approval` のみがセミオートゲート仕様の対象となる
  - 既存のセミオートゲート仕様（`automation_mode`, `reason_code`, `auto_approved`, `fallback`）との整合性を維持する

## ユビキタス言語

- **ゲート承認**: ワークフロー上の承認ポイントでの進行可否判断。セミオートモードで自動化可能
- **ユーザー選択**: 複数の選択肢からユーザーが1つを選ぶ場面。マージ方法、対応方針等
- **情報収集**: ユーザーからの自由入力やコンテキスト情報の提供を求める場面
- **AskUserQuestion**: Claude Code のツール。ユーザーに質問を提示し回答を待つ機能
