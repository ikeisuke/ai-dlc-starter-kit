# Unit 002 計画: reviewing-architecture スキル作成

## 概要

設計・アーキテクチャに特化したレビュースキル `reviewing-architecture` を新規作成する。Unit 001（reviewing-code）と同じ構造を踏襲し、観点部分をアーキテクチャ固有のものに差し替える。

## 変更対象ファイル

### 新規作成

- `prompts/package/skills/reviewing-architecture/SKILL.md` - スキル本体
- `prompts/package/skills/reviewing-architecture/references/session-management.md` - セッション管理ガイド

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: SKILL.mdの構造と各セクションの責務を定義
2. **論理設計**: ファイル構成、frontmatter仕様、アーキテクチャ観点チェックリストの詳細を定義
3. **設計レビュー**: AIレビュー（codex）→ ユーザー承認

### Phase 2: 実装

4. **コード生成**: SKILL.mdとreferences/session-management.mdを作成
5. **テスト生成**: 受け入れ基準の検証（ファイル存在、frontmatter、行数制限）
6. **統合とレビュー**: AIレビュー（codex）→ ユーザー承認

## SKILL.mdの主要構成（予定）

- **frontmatter**: name, description（三人称）, argument-hint, compatibility, allowed-tools
- **レビュー観点**:
  - 構造（Structure）: レイヤー分離、モジュール構成、責務の配置
  - パターン（Patterns）: デザインパターンの適用、アンチパターンの検出
  - API設計（API Design）: エンドポイント設計、インターフェース一貫性
  - 依存関係（Dependencies）: 依存方向、循環依存、パッケージ構造
- **実行コマンド**: Codex / Claude Code / Gemini
- **セッション継続**: 反復レビュー用のセッション管理

## 完了条件チェックリスト

- [ ] `prompts/package/skills/reviewing-architecture` ディレクトリが存在する
- [ ] `prompts/package/skills/reviewing-architecture/SKILL.md` が存在する
- [ ] SKILL.md frontmatterに `name: reviewing-architecture` が記載されている
- [ ] SKILL.md frontmatterのdescriptionが三人称で記述されている
- [ ] SKILL.md bodyにアーキテクチャ観点チェックリスト（構造、パターン、API設計、依存関係）が記載されている
- [ ] SKILL.md bodyにCodex、Claude、Geminiの実行コマンドが各1つ以上記載されている
- [ ] `prompts/package/skills/reviewing-architecture/references/` に1ファイル以上存在する
- [ ] SKILL.mdが500行以下である
