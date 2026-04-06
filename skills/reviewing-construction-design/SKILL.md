---
name: reviewing-construction-design
description: Reviews design artifacts for quality, pattern application, and API design. Use when performing design reviews in Construction Phase.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Construction Design

設計レビューを実行するスキル。

## レビュー観点

### 構造

- レイヤー間の責務が明確に分離されているか
- モジュール/パッケージの凝集度は適切か
- コンポーネント間のインターフェースが明確に定義されているか
- ビジネスロジックがプレゼンテーション層やインフラ層に漏れ出していないか

### パターン

- 採用されたデザインパターンが問題に対して適切か
- アンチパターン（God Class、Spaghetti Code等）が含まれていないか
- パターンの過剰適用（Over-engineering）がないか
- プロジェクト内でパターンの適用が一貫しているか

### API設計

- エンドポイント/インターフェースの命名が一貫しているか
- 入出力の型定義が明確か
- エラーハンドリングの方針が統一されているか
- バージョニング・後方互換性が考慮されているか

### 依存関係

- 依存方向が適切か（上位レイヤーが下位に依存しない等）
- 循環依存が存在しないか
- コンポーネント間の境界（コンテキスト境界）が明確に定義されているか
- 障害の伝播が適切に分離されているか（障害分離）

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
