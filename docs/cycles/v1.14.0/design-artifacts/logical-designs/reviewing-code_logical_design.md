# 論理設計: reviewing-code スキル作成

## 概要

reviewing-codeスキルのディレクトリ構成、ファイル間の情報分割方針、Progressive Disclosure構造を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**Progressive Disclosure パターン**（agentskills.io推奨）

- SKILL.md本体: 概要・チェックリスト・基本コマンド（エージェントがスキル起動時に読み込み）
- references/: 詳細なセッション管理手順（必要時のみ読み込み）

## コンポーネント構成

### ディレクトリ構造

```text
prompts/package/skills/reviewing-code/
├── SKILL.md                              # メインスキルファイル（~100行目標）
└── references/
    └── session-management.md             # セッション管理詳細（~120行目標）
```

### コンポーネント詳細

#### SKILL.md

- **責務**: スキルのメタデータ提供、コードレビュー観点の定義、ツール実行方法の案内
- **依存**: なし（自己完結）
- **参照**: references/session-management.md（1階層のみ）
- **目標行数**: 100行以下（500行上限に対して余裕を持つ）

#### references/session-management.md

- **責務**: Codex/Claude/Geminiそれぞれのセッション管理詳細を提供
- **依存**: なし
- **参照元**: SKILL.mdからリンク
- **目標行数**: 120行以下

## ファイル形式

### SKILL.md 構造

```text
---
[YAML frontmatter: name, description, argument-hint, compatibility, allowed-tools]
---

# Reviewing Code

## レビュー観点
[4観点のチェックリスト]

## 実行コマンド
### Codex
[コマンド1行]
### Claude Code
[コマンド1行]
### Gemini
[コマンド1行]

## セッション継続
[各ツール1行のresume方法 + references/へのリンク]
```

### references/session-management.md 構造

```text
# セッション管理ガイド

## 反復レビューの原則
[共通ルール: resume必須場面の判定表]

## Codex
[コマンド詳細 + 反復レビューの流れ + パラメータ表]

## Claude Code
[コマンド詳細 + 反復レビューの流れ + パラメータ表 + 既知の制限事項]

## Gemini
[コマンド詳細 + 反復レビューの流れ + パラメータ表]
```

## 既存スキルからの情報統合方針

### 統合対象

| 既存スキル | 統合先（SKILL.md） | 統合先（references/） |
|-----------|-------------------|---------------------|
| codex-review | 実行コマンド1行 + resume1行 | セッション管理全文 |
| claude-review | 実行コマンド1行 + session-id1行 | セッション管理全文 + 既知の制限事項 |
| gemini-review | 実行コマンド1行 + resume1行 | セッション管理全文 |

### 統合ルール

- 各ツールの実行コマンドはSKILL.md本体に1つずつ記載（最小限）
- セッション継続の概要（1行程度）をSKILL.md本体に記載
- 反復レビューの詳細手順・パラメータ表・使用例はreferences/に配置
- 既存スキルの「使用例」セクション（設計レビュー、実装レビュー）は省略（レビュー観点チェックリストが文脈を提供するため）
- claude-reviewの「既知の制限事項」はreferences/に含める

## 非機能要件（NFR）への対応

### SKILL.md行数（500行以下）

- 目標100行以下で設計し、500行上限に対して十分な余裕を確保
- チェックリスト項目を簡潔に保つ（各項目1行）

### Progressive Disclosure

- SKILL.md: スキル起動時に読み込まれる（~100行 ≈ ~500トークン）
- references/: 必要時のみ読み込み（セッション継続が必要な場合）

## 実装上の注意事項

- descriptionは三人称（"Reviews code..." or "Performs code review..."）で記述し、"I" や "You" で始めない
- nameフィールドはディレクトリ名と一致させる（"reviewing-code"）
- agentskills.io仕様: nameは小文字英数字+ハイフンのみ、64文字以内
- チェックリスト項目は「High freedom」（テキストベース指示）で記述し、具体的なコマンドやスクリプトは含めない（コードレビューは文脈依存のため）
- references/ファイルは1階層のみ（深いネスト禁止）

## 不明点と質問（設計中に記録）

特になし。
