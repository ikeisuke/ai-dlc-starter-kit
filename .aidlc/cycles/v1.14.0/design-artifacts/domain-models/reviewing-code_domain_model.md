# ドメインモデル: reviewing-code スキル作成

## 概要

コード品質に特化したレビュースキル `reviewing-code` の構造と責務を定義する。agentskills.io仕様とベストプラクティスに準拠したSKILL.mdファイルおよびreferences/ファイルの構成を設計する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ

### SKILL.md ファイル

reviewing-codeスキルの本体ファイル。agentskills.io仕様に準拠する。

- **Frontmatter（YAML）**:
  - `name`: "reviewing-code"（ディレクトリ名と一致、小文字英数字+ハイフンのみ、64文字以内）
  - `description`: 三人称で記述。コード品質レビューの目的・対象・観点を含むキーワードリッチな文
  - `argument-hint`: "[レビュー対象ファイルまたはディレクトリ]"
  - `compatibility`: "Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode."
  - `allowed-tools`: "Bash(codex:*) Bash(claude:*) Bash(gemini:*)"

- **Body（Markdown）**: 以下のセクション構成
  1. **コード品質レビュー概要**: スキルの使い方を簡潔に説明
  2. **レビュー観点チェックリスト**: 4観点のチェック項目
     - 可読性（命名規則、関数長、コメント品質）
     - 保守性（モジュール化、DRY原則、結合度）
     - パフォーマンス（計算量、メモリ使用、I/O効率）
     - テスト品質（カバレッジ、境界値テスト、テスト可読性）
  3. **ツール別実行コマンド**: Codex / Claude / Gemini それぞれの基本コマンド
  4. **セッション継続（概要）**: 各ツール1行程度のresume/continue方法
  5. **参照リンク**: references/session-management.mdへの誘導

### references/session-management.md ファイル

各ツールのセッション管理の詳細手順を記載する参照ファイル。

- **構成**:
  1. **反復レビュー時の共通ルール**: セッション継続を使うべき場面の判定表
  2. **Codex セッション管理**: `codex exec resume`の詳細、反復レビューの流れ、パラメータ説明
  3. **Claude セッション管理**: `claude --session-id`の詳細、反復レビューの流れ、パラメータ説明、既知の制限事項
  4. **Gemini セッション管理**: `gemini --resume`の詳細、反復レビューの流れ、パラメータ説明

## 値オブジェクト

### レビュー観点チェックリスト

4つの観点それぞれに3-5個の具体的チェック項目を持つ。

- **可読性**: 命名規則遵守、関数/メソッド長、ネストの深さ、コメント品質、コードの意図の明確さ
- **保守性**: 単一責任原則、DRY原則遵守、疎結合・高凝集、拡張性、依存関係の明確さ
- **パフォーマンス**: アルゴリズム計算量、不要な再計算、メモリリーク可能性、I/O効率、N+1問題
- **テスト品質**: テストカバレッジ、境界値テスト、テスト名の記述性、テストの独立性、アサーション品質

### ツール実行コマンド

各ツールの実行コマンド形式（値オブジェクトとして不変）。

- **Codex**: `codex exec -s read-only -C <dir> "<指示>"`
- **Claude**: `claude -p --output-format stream-json "<指示>"`
- **Gemini**: `gemini -p "<指示>" --sandbox`

## ユビキタス言語

- **コードレビュー**: ソースコードの品質を体系的にチェックするプロセス
- **レビュー観点**: コードを評価する際の具体的な着眼点カテゴリ
- **Progressive Disclosure**: 必要な時に必要な情報だけを読み込む情報設計パターン
- **セッション管理**: AIツールの反復レビュー時に前回のコンテキストを継続する仕組み
- **frontmatter**: SKILL.mdファイル冒頭のYAMLメタデータ部分

## 不明点と質問（設計中に記録）

特になし。既存3スキル（codex-review, claude-review, gemini-review）のツール呼び出し情報が確認済みのため、統合方針は明確。
