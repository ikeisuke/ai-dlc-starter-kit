# ドメインモデル: SKILL.md パス解決 + 追加コンテキスト対応

## 概要

`/aidlc` オーケストレーターのARGUMENTSパーシングを拡張し、追加コンテキストの受け渡しを可能にする。またステップファイルのパス解決ルールを明示化する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## スコープ

### In Scope（Unit 002）

- ARGUMENTSパーシング仕様の追加（action + additional_context分離）
- パス解決ルールの明示化
- CLAUDE.md / AGENTS.md への追加コンテキスト対応記述
- ミラー同期（正本 → 配布パッケージ → 配布物）

### Out of Scope

- v1残存コードの削除 → Unit 003
- ステップファイルの内容変更（パス参照確認のみ）

## 値オブジェクト（Value Object）

### SkillArguments

SKILL.mdが受け取る引数文字列を構造化した値オブジェクト。

- **属性**:
  - raw: String - ARGUMENTS の生文字列
  - action: ActionType - パース済みのアクション種別
  - additional_context: String - action 以降の残りテキスト（空可）
- **不変性**: パース結果は引数文字列から一意に決定される
- **等価性**: raw 文字列の一致で判定

### ActionType

有効なアクションの列挙型。

- **有効値**: `inception` | `construction` | `operations` | `setup` | `express` | `feedback` | `migrate`
- **特殊値**: `auto`（引数なし時。ブランチ名から判定）
- **不正値**: 上記以外の文字列はエラー

### StepPath

ステップファイルへの相対パスを表す値オブジェクト。

- **属性**:
  - relative_path: String - ベースディレクトリからの相対パス（例: `steps/common/rules.md`）
- **解決ルール**: スキルの base directory（`skills/aidlc/`）からの相対パスとして解決

## ドメインサービス

### ArgumentParser

ARGUMENTS文字列をSkillArgumentsに変換するサービス。

- **責務**: 引数文字列のパースとバリデーション
- **操作**:
  - parse(raw) → SkillArguments: 先頭トークンをaction、残りをadditional_contextに分離。additional_contextは先頭の区切り空白（1つ）のみ除去し、残りの空白は保持
  - validate(action) → ActionType | Error: actionが有効値か検証。不正値はエラー

### ActionResolver

引数なし時のデフォルトaction決定を担うサービス。

- **責務**: ブランチ名からactionを判定する（引数なし時のフォールバック）
- **操作**:
  - resolve() → ActionType: ブランチ名が `cycle/*` なら `construction`、それ以外は `inception` を返す
- **呼び出し条件**: ARGUMENTSが空または未指定の場合のみ

### ContextProvider

パース済みのコンテキスト変数をフロー全体に提供するサービス。

- **責務**: additional_contextを引数ルーティング直後（共通初期化フローの前）に設定
- **操作**:
  - setContext(additional_context): コンテキスト変数として設定
  - getContext() → String: ステップファイルから参照

## ユビキタス言語

- **action**: `/aidlc` の第1引数。フェーズを決定するキーワード
- **additional_context**: action以降のユーザー提供テキスト。フェーズ実行中に参照可能
- **ベースディレクトリ**: スキルのSKILL.mdが配置されているディレクトリ（`skills/aidlc/`）
- **ステップパス**: ベースディレクトリからの相対パスで記述されるファイル参照
