# 論理設計: AskUserQuestion使用ルールの追加

## 概要

`steps/common/rules.md` に追加するAskUserQuestion使用ルールセクションの構造・配置・内容を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存の `rules.md` の構造に準拠し、独立セクションとして追加する。既存セクション（セミオートゲート仕様、ユーザーの承認プロセス、質問と回答の記録）との参照関係を明示する。

## コンポーネント構成

### 配置位置

`steps/common/rules.md` 内、「ユーザーの承認プロセス【重要】」セクション（L40）の直後、「質問と回答の記録【重要】」セクション（L49）の前に配置する。

```text
steps/common/rules.md
├── ## 設定読み込み【重要】
├── ## ユーザーの承認プロセス【重要】
├── ## AskUserQuestion使用ルール【重要】  ← 新規追加
├── ## 質問と回答の記録【重要】
├── ## Overconfidence Prevention原則【重要】
├── ...
└── ## コード品質基準
```

### セクション内部構造

```text
## AskUserQuestion使用ルール【重要】
├── 導入文（目的・背景）
├── ### インタラクション種別と対応方法
│   └── 3種類の分類表（種別・説明・対応方法・automation_modeでの扱い・具体例）
├── ### セミオートゲート仕様との関係
│   └── 既存語彙とのマッピング
└── ### 判定フロー
    └── ユーザー対話が必要な場面での判定手順
```

## インターフェース設計

### 分類表の列定義

| 列名 | 説明 |
|------|------|
| 種類 | `gate_approval` / `user_choice` / `information_gathering` |
| 説明 | 種別の定義 |
| 対応方法 | テキスト出力 or AskUserQuestion |
| `automation_mode` での扱い | `manual`: 全てユーザー確認 / `semi_auto`: gate_approvalのみ自動化可 |
| 具体例 | 代表的なユースケース |

### 具体例の設計

| 種別 | 具体例 |
|------|--------|
| `gate_approval` | 「この設計で進めてよろしいですか？」「計画を承認しますか？」 |
| `user_choice` | 「マージ方法を選んでください（squash/merge/rebase）」「どのUnitから着手しますか？」「force pushしてよろしいですか？（破壊的操作の確認）」 |
| `information_gathering` | 「今回取り組みたい内容は何ですか？」「追加コンテキストを教えてください」 |

### 各種別の入出力契約

| 種別 | 入力 | 出力 | ツール |
|------|------|------|--------|
| `gate_approval` | 承認ポイントID、成果物 | `auto_approved` / `fallback` (セミオートゲート結果) | セミオートゲート仕様に委譲 |
| `user_choice` | 選択肢リスト、コンテキスト | ユーザーの選択結果 | AskUserQuestion（選択肢提示） |
| `information_gathering` | 質問文、コンテキスト | ユーザーの自由入力 | AskUserQuestion（自由入力） |

**責務の委譲**: 本セクションはセミオートゲートの**対象範囲**（どの種類のインタラクションが自動化対象か）を定義する。判定ロジック自体（`automation_mode`, `reason_code`, `auto_approved`, `fallback` の処理フロー）は既存のセミオートゲート仕様に委譲する。

### セミオートゲート仕様との接続

| インタラクション種別 | セミオートゲートの対象か | 根拠 |
|---------------------|----------------------|------|
| `gate_approval` | 対象 | 承認ポイントとしてゲート判定ロジックが適用される |
| `user_choice` | 対象外 | ユーザーの意思決定が必要であり、AIが代替不可 |
| `information_gathering` | 対象外 | ユーザーのみが持つ情報の入力が必要 |

## 処理フロー概要

### ユーザー対話が必要な場面での判定フロー

1. ユーザーへの問いかけが必要な場面を検出
2. インタラクション種別を判定（gate_approval / user_choice / information_gathering）
3. 種別に応じた対応:
   - `gate_approval`: セミオートゲート仕様に従う（`automation_mode` に基づく判定）
   - `user_choice` / `information_gathering`: AskUserQuestionツールを使用（`automation_mode` に関わらず）

## 既存セクションとの関係

| 関連セクション | 関係性 |
|---------------|--------|
| ユーザーの承認プロセス | gate_approval の手順を定義。本セクションはその分類基準を補完 |
| セミオートゲート仕様 | gate_approval の自動化ロジック。本セクションは自動化の対象範囲を明確化 |
| 質問と回答の記録 | information_gathering で得た情報の記録ルール |
| Overconfidence Prevention原則 | 曖昧な場面での質問を促す。本セクションはツール選択の基準を提供 |

## 実装上の注意事項

- セクション追加のみであり、既存セクションの修正は行わない
- Unit定義の「境界」に従い、既存ステップファイル内のAskUserQuestion呼び出し箇所の修正は行わない
- CLAUDE.mdのAskUserQuestion記述は維持（重複は許容）
