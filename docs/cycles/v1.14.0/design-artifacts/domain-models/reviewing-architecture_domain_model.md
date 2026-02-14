# ドメインモデル: reviewing-architecture スキル作成

## 概要

アーキテクチャレビューに特化したスキルファイル（SKILL.md）の構造と各セクションの責務を定義する。Unit 001（reviewing-code）と同一構造を踏襲し、レビュー観点をアーキテクチャ固有のものに差し替える。

## エンティティ（Entity）

### SKILL.md

スキルの本体ファイル。agentskills.io frontmatter仕様に準拠する。

- **構成要素**:
  - frontmatter（メタデータ）
  - 本文（レビュー観点、実行コマンド、セッション継続）
- **責務**:
  - スキルの識別情報を提供する（frontmatter）
  - アーキテクチャレビューの観点チェックリストを提供する
  - Codex/Claude/Geminiの実行コマンドを提供する
  - 反復レビュー時のセッション継続方法を案内する

### Frontmatter

SKILL.mdのメタデータセクション。agentskills.io仕様に準拠。

- **属性**:
  - name: String - スキル識別名（`reviewing-architecture`）
  - description: String - スキルの説明（三人称、英語）
  - argument-hint: String - 引数のヒント
  - compatibility: String - 動作要件
  - allowed-tools: String - 許可するツール
- **不変条件**:
  - nameはスキルディレクトリ名と一致すること
  - descriptionは三人称で記述すること
  - compatibility、allowed-toolsは必ず記載すること
  - allowed-toolsはUnit 001と同一値（`Bash(codex:*) Bash(claude:*) Bash(gemini:*)`）

### レビュー観点カテゴリ

アーキテクチャレビューの4つの観点カテゴリ。各カテゴリに具体的なチェック項目を持つ。

- **構造（Structure）**: レイヤー分離、モジュール構成、責務の配置
- **パターン（Patterns）**: デザインパターン適用、アンチパターン検出
- **API設計（API Design）**: エンドポイント設計、インターフェース一貫性
- **依存関係（Dependencies）**: 依存方向、循環依存、パッケージ構造

### セッション管理ガイド

反復レビュー時のセッション継続方法を詳細に記載するリファレンスファイル。

- **責務**: Codex/Claude/Geminiそれぞれのセッション継続コマンドと使い分けを説明する
- **配置**: `references/session-management.md`
- **不変条件**: Unit 001の同名ファイルと同一内容を踏襲する

## 値オブジェクト（Value Object）

### チェック項目

各観点カテゴリに属する個別のチェック項目。

- **属性**: question: String - 確認すべき観点を疑問形で記述
- **不変性**: 各カテゴリに最低3つ以上のチェック項目が必要
- **等価性**: 質問文の内容で判定

## ユビキタス言語

- **スキル（Skill）**: AIツールが実行可能な特定の能力・手順を定義したファイル群
- **観点カテゴリ（Perspective Category）**: レビューの大分類（構造、パターン、API設計、依存関係）
- **チェック項目（Check Item）**: 観点カテゴリ内の具体的な確認事項
- **セッション継続（Session Resume）**: 反復レビュー時に前回のコンテキストを引き継ぐ機能
- **Progressive Disclosure**: 詳細情報をreferences/に分離し、SKILL.md本体を簡潔に保つ設計原則
