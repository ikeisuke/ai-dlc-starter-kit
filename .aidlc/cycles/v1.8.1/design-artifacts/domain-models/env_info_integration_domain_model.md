# ドメインモデル: env-info-integration

## 概要

setup.mdの依存ツール確認フローにおいて、env-info.shを活用した環境情報取得と状態判定の概念モデルを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 概念モデル（プロンプト修正のため、DDDパターンを概念レベルで適用）

本Unitはプロンプト（Markdown）の修正であり、実行コードではないため、DDDの概念を文書構造に適用する。

### 環境情報（EnvironmentInfo）

依存ツールの状態を一元管理する概念。

- **属性**:
  - gh_status: ToolStatus - GitHub CLIの状態
  - dasel_status: ToolStatus - daselの状態
  - jj_status: ToolStatus - jjの状態（現在未使用）
  - git_status: ToolStatus - gitの状態（現在未使用）
- **取得方法**: env-info.shスクリプトの実行結果を解析

### ツール状態（ToolStatus）値オブジェクト

個々のツールの状態を表す不変の値。

**Raw値（env-info.shの出力、英語）**:
- `available`: 利用可能（インストール済み、認証済み）
- `not-installed`: 未インストール
- `not-authenticated`: インストール済みだが未認証（ghのみ）
- `unknown`: 不明（出力欠落やパース失敗時のフォールバック）

**表示値（日本語、ユーザー向け）**:
- `available` → "利用可能"
- `not-installed` → "未インストール"
- `not-authenticated` → "未認証"
- `unknown` → "不明"

**警告判定の基準**: Raw値で判定する。`available` 以外はすべて警告対象とする。

### 状態判定サービス（StatusEvaluator）

環境情報から警告表示の要否を判定する概念。

- **責務**: ToolStatusのRaw値を評価し、警告表示条件を判定
- **判定ロジック**（Raw値で判定）:
  - gh_status が `available` 以外 → 警告対象
  - dasel_status が `available` 以外 → 警告対象
  - `unknown` も警告対象として扱う

## プロセスフロー

```text
1. env-info.sh 実行
   ↓
2. 出力解析（行ごとに tool:status 形式をパース）
   ↓
3. 必要なツール（gh, dasel）の状態を抽出
   ↓
4. 状態値を日本語に変換
   ↓
5. 結果表示（テーブル形式）
   ↓
6. 警告条件判定・警告表示
```

## 境界

### スコープ内

- setup.mdの「依存コマンド確認」セクションでのenv-info.sh呼び出し
- 出力解析と状態判定ロジックの記載
- 結果表示フォーマット
- エラー発生時のフォールバック処理（`unknown`状態への変換）

### スコープ外

- env-info.sh自体の修正
- 新しい依存ツールの追加

### jj/gitの状態について

env-info.shは4ツール（gh, dasel, jj, git）の状態を出力するが、本Unitでは以下の扱いとする：
- **取得**: env-info.shの出力に含まれるため取得される
- **表示**: setup.mdの現行仕様に合わせ、gh/daselのみ表示（jj/gitは表示しない）
- **警告判定**: gh/daselのみ対象（jj/gitは判定しない）

将来的にjj/gitの表示・警告が必要になった場合は、別Unitで対応する。

## ユビキタス言語

このドメインで使用する共通用語：

- **依存ツール**: AI-DLCの動作に必要な外部コマンド（gh, dasel等）
- **環境情報**: 依存ツールのインストール状態・認証状態の総称
- **状態判定**: 環境情報を評価し、利用可否を決定するプロセス
- **警告表示**: 一部機能が制限される旨をユーザーに通知すること

## 不明点と質問（設計中に記録）

設計中に不明点が発生した場合、ここに記録する。

（現時点で不明点なし）
