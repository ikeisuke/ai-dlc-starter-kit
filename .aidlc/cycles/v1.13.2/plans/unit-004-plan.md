# Unit 004 実装計画: コンパクション時のプロンプト読み込み

## 概要

コンテキストがコンパクション（自動要約）された後も、フェーズのルールと手順が維持されるよう、各フェーズプロンプトに再読み込み指示を追加する。

## 問題点

現在のコンテキストリセット対応は、ユーザーからの明示的な発言（「継続プロンプト」「リセットしたい」など）に対する対応のみ。コンパクション（自動要約）はシステムによって自動的に行われるため、ユーザー発言がなくてもプロンプトの再読み込みが必要。

## Unit定義・user_stories.mdの修正

元のUnit定義・user_stories.mdに記載されていたテンプレート名が実態と異なっていたため修正済み：
- `progress_inception_template.md` → `inception_progress_template.md` に修正
- `progress_construction_template.md` → 存在しないため、`operations_progress_template.md` に修正
- Construction Phase用テンプレートが存在しない旨を注記追加

## 設計判断

1. **コンパクション時の指示追加**: 各フェーズプロンプトの「コンテキストリセット対応」セクションに、コンパクション時のプロンプト再読み込み指示を追加

2. **progress.mdテンプレートの更新**: Inception/Operations用テンプレートに「再開時に読み込むファイル」セクションを追加

3. **Construction Phaseの継続確認**: Constructionはprogress.mdテンプレートが存在しないため、プロンプト内の指示でUnit定義ファイルの実装状態を確認するよう記載

4. **docs/aidlc/同期はスコープ外**: `prompts/package/`のみ編集し、`docs/aidlc/`への同期はOperations Phaseで行う（Intent制約に従う）

## 変更対象ファイル

- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`
- `prompts/package/templates/inception_progress_template.md`
- `prompts/package/templates/operations_progress_template.md`

**注**: `docs/aidlc/templates/`の更新はOperations Phaseの同期処理で反映される

## 実装計画

### 1. 各フェーズプロンプトに「コンパクション時の対応」を追加

既存の「コンテキストリセット対応【重要】」セクションに、コンパクション時の対応を追加する。

**追加内容（Inception/Operations用）**:

```markdown
- **コンパクション時の対応【自動要約後】**: コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：
  1. このプロンプトファイルの内容が保持されているか確認
  2. 保持されていない場合、以下のプロンプトを読み込む：
     - `docs/aidlc/prompts/{phase}.md`
  3. progress.mdの現在のステップを確認して作業を継続
```

**追加内容（Construction用）**:

```markdown
- **コンパクション時の対応【自動要約後】**: コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：
  1. このプロンプトファイルの内容が保持されているか確認
  2. 保持されていない場合、以下のプロンプトを読み込む：
     - `docs/aidlc/prompts/construction.md`
  3. 作業中のUnit定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクションを確認して作業を継続
```

### 2. progress.mdテンプレートに「再開時に読み込むファイル」セクションを追加

**追加セクション**:

```markdown
## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のファイルを読み込んでください：

- `docs/aidlc/prompts/{phase}.md`
```

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/inception.md` に「コンパクション時の対応」が追加されている
- [ ] `prompts/package/prompts/construction.md` に「コンパクション時の対応」が追加されている（Unit定義ファイルの実装状態確認を含む）
- [ ] `prompts/package/prompts/operations.md` に「コンパクション時の対応」が追加されている
- [ ] `prompts/package/templates/inception_progress_template.md` に「再開時に読み込むファイル」セクションが追加されている
- [ ] `prompts/package/templates/operations_progress_template.md` に「再開時に読み込むファイル」セクションが追加されている

## 影響範囲

- 各フェーズプロンプトのコンテキストリセット対応セクション
- progress.mdテンプレート（Inception/Operations用）
- Lite版プロンプトへの影響はなし（スコープ外）
- `docs/aidlc/templates/`への同期はOperations Phaseで実施

## 関連Issue

- #170
