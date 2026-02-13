# Unit 001 計画: reviewing-code スキル作成

## 概要

コード品質に特化したレビュースキル `reviewing-code` を新規作成する。agentskills.io仕様準拠のSKILL.mdと、セッション管理の詳細を記載したreferences/ファイルを作成する。

## 変更対象ファイル

### 新規作成

| ファイル | 説明 |
|---------|------|
| `prompts/package/skills/reviewing-code/SKILL.md` | メインスキルファイル |
| `prompts/package/skills/reviewing-code/references/session-management.md` | セッション管理の詳細 |

### 変更なし

- 既存スキル（codex-review, claude-review, gemini-review）は変更しない（Unit 005で削除）
- review-flow.mdは変更しない（Unit 004で更新）
- シンボリックリンクは作成しない（Unit 009で対応）

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

新規スキルの構造を定義する。

- **SKILL.md frontmatter**: agentskills.io仕様準拠
  - `name: reviewing-code`（ディレクトリ名と一致）
  - `description`: 三人称（"Performs..." or "Reviews..."形式）、コード品質レビューの対象と観点を明記
  - `compatibility`: Claude Code対応を明記
  - `allowed-tools`: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
  - `argument-hint`: レビュー指示のヒント

- **SKILL.md body**: コード品質レビューの観点と実行方法
  - コード品質観点チェックリスト（4観点）
    - 可読性（命名、構造、コメント）
    - 保守性（モジュール化、DRY、拡張性）
    - パフォーマンス（効率、リソース使用）
    - テスト品質（カバレッジ、可読性、境界値）
  - ツール別実行コマンド（Codex / Claude / Gemini）
  - 基本的なセッション継続方法（各ツール1行程度）
  - references/への参照リンク

- **references/session-management.md**: 各ツールの詳細なセッション管理
  - 既存3スキル（codex-review, claude-review, gemini-review）の反復レビュー手順を統合
  - Codex: `codex exec resume <session-id>`
  - Claude: `claude --session-id <uuid> -p`
  - Gemini: `gemini --resume <index> -p`

#### ステップ2: 論理設計

- Progressive Disclosure構造の設計
  - SKILL.md: 500行以下（5000トークン推奨）
  - 詳細はreferences/に分離
- 既存3スキルからの情報統合方針
  - 各ツールの実行コマンド形式をSKILL.md本体に記載
  - セッション管理の詳細手順をreferences/に配置

#### ステップ3: 設計レビュー

### Phase 2: 実装

#### ステップ4: コード生成

- `prompts/package/skills/reviewing-code/SKILL.md` 作成
- `prompts/package/skills/reviewing-code/references/session-management.md` 作成

#### ステップ5: テスト生成

受け入れ基準に基づくチェック:
- ディレクトリ存在確認
- SKILL.mdファイル存在確認
- frontmatter検証（name, description形式）
- body内容検証（チェックリスト、コマンド）
- references/ファイル存在確認
- 行数チェック（500行以下）

#### ステップ6: 統合とレビュー

## 完了条件チェックリスト

- [ ] `prompts/package/skills/reviewing-code/SKILL.md` の作成
- [ ] agentskills.io frontmatter仕様準拠（name: reviewing-code、description: 三人称）
- [ ] コード品質観点チェックリスト（可読性、保守性、パフォーマンス、テスト品質）
- [ ] Codex/Claude/Geminiの実行コマンド記載
- [ ] `references/` ディレクトリにセッション管理の詳細ファイル配置
- [ ] SKILL.mdが500行以下
