# 論理設計: reviewing-architecture スキル作成

## 概要

reviewing-architectureスキルのファイル構成、frontmatter仕様、レビュー観点チェックリストの詳細を定義する。

## アーキテクチャパターン

Unit 001（reviewing-code）と同一のスキルファイル構成パターンを採用。Progressive Disclosureにより、SKILL.md本体は500行以下に収め、詳細はreferences/に配置する。

## コンポーネント構成

```text
prompts/package/skills/reviewing-architecture/
├── SKILL.md                          # スキル本体
└── references/
    └── session-management.md         # セッション管理ガイド
```

### コンポーネント詳細

#### SKILL.md

- **責務**: スキルのメタデータ、レビュー観点、実行コマンド、セッション継続の案内を提供
- **依存**: references/session-management.md（リンク参照）
- **行数制限**: 500行以下

#### references/session-management.md

- **責務**: Codex/Claude/Geminiのセッション継続コマンドと反復レビューの詳細手順を提供
- **依存**: なし
- **内容**: Unit 001の同名ファイルと同一内容を踏襲

## インターフェース設計

### SKILL.md frontmatter仕様

```yaml
---
name: reviewing-architecture
description: Reviews architecture for structural issues including layer separation, design patterns, API design, and dependency management. Use when performing architecture reviews, checking system design, or when the user mentions architecture review, design review, or structural analysis.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---
```

### SKILL.md 本文構成

1. **見出し**: `# Reviewing Architecture`
2. **導入文**: アーキテクチャに特化したレビュースキルであることを1文で説明
3. **レビュー観点**: 4カテゴリ × 各4チェック項目
4. **実行コマンド**: Codex / Claude Code / Gemini の各コマンド
5. **セッション継続**: 反復レビュー用コマンドとreferencesへのリンク

### レビュー観点チェックリスト詳細

#### 構造（Structure）

- レイヤー間の責務が明確に分離されているか
- モジュール/パッケージの凝集度は適切か
- コンポーネント間のインターフェースが明確に定義されているか
- ビジネスロジックがプレゼンテーション層やインフラ層に漏れ出していないか

#### パターン（Patterns）

- 採用されたデザインパターンが問題に対して適切か
- アンチパターン（God Class、Spaghetti Code等）が含まれていないか
- パターンの過剰適用（Over-engineering）がないか
- プロジェクト内でパターンの適用が一貫しているか

#### API設計（API Design）

- エンドポイント/インターフェースの命名が一貫しているか
- 入出力の型定義が明確か
- エラーハンドリングの方針が統一されているか
- バージョニング・後方互換性が考慮されているか

#### 依存関係（Dependencies）

- 依存方向が適切か（上位レイヤーが下位に依存しない等）
- 循環依存が存在しないか
- コンポーネント間の境界（コンテキスト境界）が明確に定義されているか
- 障害の伝播が適切に分離されているか（障害分離）

## 処理フロー概要

### レビュー実行フロー

1. ユーザーがスキルを呼び出し、レビュー対象を指定
2. AIツール（Codex/Claude/Gemini）が実行コマンドでレビューを実行
3. 指摘があれば修正し、セッション継続で再レビュー
4. 指摘0件になるまで反復

## NFRへの対応

### SKILL.md行数制限

- **要件**: 500行以下
- **対応策**: セッション管理の詳細をreferences/に分離（Progressive Disclosure）

## 技術選定

- **ファイル形式**: Markdown（agentskills.io frontmatter付き）
- **フォーマット**: YAML frontmatter + Markdown body

## 実装上の注意事項

- Unit 001のSKILL.mdとの構造的一貫性を維持する（セクション順序、コマンド形式）
- 実行コマンドの一次参照先は既存レビュースキル（codex-review、claude-review、gemini-review）とし、Unit 001と同一パターンを維持する
- descriptionは英語・三人称で記述し、アーキテクチャレビューのトリガーワードを含める
- references/session-management.mdはUnit 001と同一内容（共通のセッション管理手順）
