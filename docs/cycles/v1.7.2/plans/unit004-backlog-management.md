# Unit 004: バックログ管理改善 - 実行計画

## 概要

バックログ管理機能を改善し、モード対応と方針の明文化を行う。

## 対象ストーリー

1. **ストーリー 3-1**: バックログ移行処理のモード対応 (#38)
2. **ストーリー 3-2**: AGENTS.mdへのバックログ管理方針追加 (#41)
3. **ストーリー 3-3**: modeに"git-only"/"issue-only"オプション追加 (ローカル)

## Phase 1: 設計

### ステップ1: ドメインモデル設計

バックログ管理の概念モデルを定義：

- **バックログアイテム**: 管理対象の気づき・課題
- **保存先モード**: git / issue / git-only / issue-only

### ステップ2: 論理設計

各ファイルの変更内容を設計：

1. **prompts/package/prompts/AGENTS.md**
   - バックログ管理方針セクションを追加
   - mode設定と保存先の対応表を記載

2. **prompts/setup-prompt.md**
   - aidlc.tomlテンプレートのbacklog.modeに"git-only"/"issue-only"オプションを追加

3. **prompts/package/prompts/inception.md**
   - 排他モード（*-only）の場合のバックログ記録フローを条件分岐

4. **prompts/package/prompts/operations.md**
   - 排他モード（*-only）の場合のバックログ確認フローを条件分岐

5. **prompts/package/prompts/construction.md**
   - 排他モード（*-only）の場合のバックログ記録フローを条件分岐

## Phase 2: 実装

### ステップ4: コード生成

1. AGENTS.mdにバックログ管理方針を追加
2. setup-prompt.mdのテンプレートを更新
3. inception.md、construction.md、operations.mdに排他モード対応を追加

### ステップ5: テスト生成

- Markdownlintによる構文チェック
- 手動レビュー（プロンプトのテストは手動確認）

### ステップ6: 統合とレビュー

- 全ファイルの変更を統合
- AIレビュー実施（mcp_review.mode = required）
- 実装記録の作成

## 編集対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/AGENTS.md` | バックログ管理方針セクション追加 |
| `prompts/setup-prompt.md` | backlog.modeに"git-only"/"issue-only"オプション追加 |
| `prompts/package/prompts/inception.md` | 排他モード対応ロジック追加 |
| `prompts/package/prompts/construction.md` | 排他モード対応ロジック追加 |
| `prompts/package/prompts/operations.md` | 排他モード対応ロジック追加 |

## 注意事項

- `docs/aidlc/` は直接編集禁止。必ず `prompts/package/` を編集する
- 変更はOperations PhaseのrsyncでAI-DLC環境に反映される

## 完了条件

- 全編集対象ファイルの更新完了
- Markdownlintパス
- AIレビュー完了
- 実装記録作成
