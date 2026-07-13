---
name: reviewing-construction-design
description: Reviews design artifacts for quality, pattern application, and API design. Use when performing design reviews in Construction Phase.
argument-hint: "[レビュー対象ファイルまたはディレクトリ]"
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

### 設計プロセス

> 既存「### 構造」「### パターン」「### API設計」「### 依存関係」が**成果物品質**を扱うのに対し、本セクションは**実施プロセスの検証**を扱う（責務直交）。

- **事前コード読込みセクション存在 / 内容充足**:
  - 適用条件: depth_level != minimal の場合のみ必須。minimal は設計ステップ自体スキップ可のため N/A。
  - 判定: 設計成果物（ドメインモデルおよび論理設計）冒頭に「## ステップ 0: 事前コード読込み」相当のセクション見出しが存在し、(a) Read 対象ファイル + 目的 / (b) 設計時に意識すべき挙動 / (c) 既存実装に基づく代替案検討 の 3 観点すべてに具体記述があること（aidlc プラグインの `steps/construction/02-design.md` のステップ 0 仕様を SoT として参照）
  - 失敗時アクション: 「事前コード読込み不足」として指摘し、修正されるまで Round 反復

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
