# ドメインモデル: 依存コマンド追加手順ドキュメント

## 概要

依存コマンド追加手順をドキュメント化するための概念モデル。

## エンティティ

### DependencyCommand（依存コマンド）

AI-DLCで使用する外部コマンド/ツール。

**属性**:

- name: コマンド名（例: gh, dasel, jj, git）
- authRequired: 認証確認が必要か（boolean）
- statusValues: 取りうる状態値のリスト

**状態値**:

- `available`: 利用可能
- `not-installed`: 未インストール
- `not-authenticated`: 未認証（認証が必要なコマンドのみ）

### AdditionProcedure（追加手順）

依存コマンドを追加するための手順。

**ステップ**:

1. env-info.shへの追加
2. setup.mdへの影響説明追加
3. 各プロンプトでの利用方法追加（必要に応じて）

## ユースケース

### UC1: 汎用ツールの追加

認証確認が不要なツール（例: dasel, jj）を追加する場合。

1. env-info.shの`main`関数に`check_tool`を使った出力を追加
2. setup.mdの「運用ルール」に影響説明を追加

### UC2: 認証が必要なツールの追加

認証確認が必要なツール（例: gh）を追加する場合。

1. env-info.shに専用のチェック関数を作成
2. env-info.shの`main`関数で専用関数を呼び出し
3. setup.mdの「運用ルール」に影響説明を追加

## 制約

- 追加手順はoperations.mdの「運用引き継ぎ情報の確認」セクション付近に配置
- 具体的なコード例を含めること
- 既存のenv-info.shの構造を踏襲すること
