# Unit 003 計画: Inception Phaseスキル化

## 概要

Inception Phaseプロンプトを Agent Skills 仕様準拠の `.claude/skills/` 形式スキルとして再実装する。既存の `inception.md` の機能を完全に維持しつつ、スキルとして呼び出し可能にする。Unit 004/005が従う共通設計パターンをこのUnitで確立する。

## 命名規則（3フェーズ共通）

| フェーズ | スキル名 | ディレクトリ名 |
|---------|---------|-------------|
| Inception | `aidlc-inception` | `aidlc-inception/` |
| Construction | `aidlc-construction` | `aidlc-construction/` |
| Operations | `aidlc-operations` | `aidlc-operations/` |

## 変更対象ファイル

### 新規作成

| ファイル | 説明 |
|---------|------|
| `prompts/package/skills/aidlc-inception/SKILL.md` | Inception Phaseスキル本体（< 500行） |
| `prompts/package/skills/aidlc-inception/references/rules.md` | 共通開発ルール |
| `prompts/package/skills/aidlc-inception/references/review-flow.md` | AIレビューフロー |
| `prompts/package/skills/aidlc-inception/references/commit-flow.md` | コミットフロー |
| `prompts/package/skills/aidlc-inception/references/intro.md` | AI-DLC手法の要約 |
| `prompts/package/skills/aidlc-inception/references/project-info.md` | プロジェクト情報 |
| `prompts/package/skills/aidlc-inception/references/compaction.md` | コンパクション対応 |
| `prompts/package/skills/aidlc-inception/references/phase-responsibilities.md` | フェーズ責務分離 |
| `prompts/package/skills/aidlc-inception/references/progress-management.md` | 進捗管理と冪等性 |
| `prompts/package/skills/aidlc-inception/references/context-reset.md` | コンテキストリセット対応 |
| `prompts/package/skills/aidlc-inception/references/agents-rules.md` | AI-DLC共通ルール |
| `prompts/package/skills/aidlc-inception/references/feedback.md` | フィードバック送信 |
| `prompts/package/skills/aidlc-inception/references/ai-tools.md` | AIツール対応 |

### 変更

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/AGENTS.md` | スキル対応ルーティング追加（3フェーズ共通方式の確立） |

### 変更なし（後方互換維持）

| ファイル | 理由 |
|---------|------|
| `prompts/package/prompts/inception.md` | 従来のプロンプト読み込み方式を維持 |

## アーキテクチャ方針（Agent Skills仕様準拠）

### Progressive Disclosure

1. **Metadata**（起動時）: name + description のみ全スキル分プリロード
2. **SKILL.md**（スキル起動時）: < 500行のエントリポイント。コアワークフローと references/ へのリンク
3. **references/**（オンデマンド）: Claude が必要に応じて読みに行く詳細ドキュメント

### SKILL.md の設計方針

- inception.md（835行）を丸ごと含めず、コアワークフローに絞る
- 詳細な共通ルール・レビューフロー等は references/ にリンクで参照
- Inception 固有の仕様（コンテキストリセット等）は SKILL.md 本体に含める

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
#### ステップ2: 論理設計
#### ステップ3: 設計レビュー（AIレビュー → ユーザー承認）

### Phase 2: 実装

#### ステップ4: コード生成
#### ステップ5: テスト生成
#### ステップ6: 統合とレビュー（AIレビュー → ユーザー承認）

## 共通モジュール同期戦略（Unit 004/005への共通設計方式）

- **正本（Single Source of Truth）**: `prompts/package/prompts/common/`
- **コピー先**: 各フェーズスキルの `references/`（aidlc-inception/, aidlc-construction/, aidlc-operations/）
- **開発時の同期**: common/ 変更時に各スキルの references/ にも手動コピー
- **デプロイ時の同期**: upgrading-aidlc の rsync で `docs/aidlc/skills/` に自動反映

## 完了条件チェックリスト

- [ ] `prompts/package/skills/aidlc-inception/SKILL.md` を作成し、inception.md の機能を完全にカバー
- [ ] 共通モジュール（rules, review-flow, commit-flow, intro, project-info, compaction, phase-responsibilities, progress-management, context-reset, agents-rules, feedback, ai-tools）を `references/` に含める
- [ ] AGENTS.md のルーティングを更新してスキル呼び出しに対応（3フェーズ共通方式を確立）
- [ ] `~/.claude/skills/` 配置時の動作を確認（別リポジトリからの呼び出し）
- [ ] スキル未検出時のフォールバック案内を実装
- [ ] `docs/aidlc/bin/` 未デプロイ時の `upgrading-aidlc` 実行案内を実装
