# Unit 002: Construction → Operations引き継ぎの仕組み

## 概要

Construction Phaseで発生した手動作業をOperations Phaseに明確に引き継ぐ仕組みを構築する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/templates/operations_task_template.md` | 新規作成 - 引き継ぎタスクのテンプレート |
| `prompts/package/prompts/construction.md` | Unit完了時の引き継ぎタスク作成手順を追加 |
| `prompts/package/prompts/operations.md` | 開始時の引き継ぎタスク確認手順・ディレクトリ構造定義を追加 |
| `prompts/package/templates/index.md` | テンプレートインデックスに新規テンプレートを追加 |

## 実装計画

### Phase 1: 設計

**注意**: このUnitはドキュメント・テンプレートの変更のみであり、ドメインモデル・論理設計は省略する（Unit定義の「技術的考慮事項」に基づく）。

#### 設計方針

1. **1作業1ファイル形式**
   - 配置場所: `docs/cycles/{{CYCLE}}/operations/tasks/`
   - ファイル名: `{NNN}-{task-slug}.md` (例: `001-manual-db-migration.md`)
   - 各ファイルに1つの手動作業を記録
   - **パス表記**: プロンプト内では `{{CYCLE}}` プレースホルダーを使用（実行時にサイクルバージョンに置換）

2. **テンプレート構成**
   - タスク名
   - 発生Unit
   - 発生理由（なぜ手動作業が必要か）
   - 作業手順
   - 完了条件
   - 実行状態（未実行/完了）

3. **フロー統合**
   - Construction: Unit完了時に手動作業があれば記録
   - Operations: 開始時にタスク一覧を確認、実行、完了をマーク

4. **ディレクトリ構造定義の記載場所**
   - `prompts/package/prompts/operations.md` の「引き継ぎタスク確認」セクションにディレクトリ構造と命名規則を明記

### Phase 2: 実装

#### ステップ1: テンプレート作成
- `prompts/package/templates/operations_task_template.md` を新規作成

#### ステップ2: テンプレートインデックス更新
- `prompts/package/templates/index.md` に新規テンプレートの参照と用途説明を追加

#### ステップ3: construction.md 更新
- Unit完了時の手順に「手動作業タスク確認・記録」セクションを追加

#### ステップ4: operations.md 更新
- 開始時の手順に「引き継ぎタスク確認・実行」セクションを追加
- ディレクトリ構造定義（`docs/cycles/{{CYCLE}}/operations/tasks/`）を明記

---

## 完了条件チェックリスト

- [ ] 引き継ぎタスクファイルのテンプレート作成（`operations_task_template.md`）
- [ ] テンプレートインデックス（`index.md`）への追加
- [ ] Construction Phase完了時の引き継ぎファイル作成手順をconstruction.mdに追加
- [ ] Operations Phase開始時の引き継ぎファイル確認手順をoperations.mdに追加
- [ ] 1作業1ファイル形式のディレクトリ構造定義をoperations.mdに記載
