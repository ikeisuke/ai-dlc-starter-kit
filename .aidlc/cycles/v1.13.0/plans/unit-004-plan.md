# Unit 004: Dependabot機能削除 - 計画

## 概要

Dependabot PR確認機能を削除し、メンテナンスコストを削減してコードベースをシンプルに保つ。

関連Issue: Closes #96

## 変更対象ファイル

### 削除対象

1. `prompts/package/bin/check-dependabot-prs.sh` - スクリプトファイル削除

### 編集対象

2. `prompts/package/prompts/inception.md` - ステップ13（Dependabot PR確認）を削除
3. `prompts/setup/templates/aidlc.toml.template` - `[inception.dependabot]`セクションを削除
4. `README.md` - Dependabot関連の説明を削除
5. `prompts/setup-prompt.md` - アップグレード時の廃止設定移行機能を追加（セクション7.5）

### 本Unitでは編集しないファイル

**Operations Phaseで自動反映されるファイル**:
- `docs/aidlc/prompts/inception.md` - rsync で `prompts/package/` から同期
- `docs/aidlc/bin/check-dependabot-prs.sh` - rsync で `prompts/package/` から同期

**根拠**: `docs/cycles/rules.md` の「メタ開発の意識」セクションにより、`docs/aidlc/` は直接編集禁止。

**履歴として保持するファイル**:
- `CHANGELOG.md` - Dependabot機能追加の履歴は歴史的記録として保持（現行機能説明ではなく過去の変更履歴のため）

## 実装計画

### Phase 1: 設計（このUnitはプロンプト・設定の削除のみのため省略）

このUnitは既存機能の削除のみで、新しい設計は不要です。ドメインモデル・論理設計をスキップし、Phase 2に進みます。

### Phase 2: 実装

#### ステップ4: コード生成（削除作業）

1. `prompts/package/bin/check-dependabot-prs.sh` を削除
2. `prompts/package/prompts/inception.md` からステップ13を削除
   - 423行目付近の「#### 13. Dependabot PR確認」セクション全体を削除
   - 後続ステップの番号調整は不要（これが最後のステップ）
3. `prompts/setup/templates/aidlc.toml.template` から `[inception.dependabot]` セクションを削除
4. `README.md` から Dependabot 関連の説明を削除
   - 411行目付近「### 4. Dependabot PR確認オプション化」セクション
   - 988行目付近「### 3. Dependabot PR 確認機能」セクション

#### ステップ5: テスト生成

テストコードは不要（削除作業のため）

#### ステップ6: 統合とレビュー

1. `rg -i dependabot prompts/` で prompts/ 配下に Dependabot 関連記述が残っていないことを確認
2. `rg -i dependabot README.md` で README に Dependabot 機能説明が残っていないことを確認
3. AIレビュー実施
4. `docs/aidlc/` への反映は Operations Phase の rsync で実施されることを確認（本Unitでは直接編集しない）

## 完了条件チェックリスト

- [ ] inception.mdからDependabot PR確認ステップを削除
- [ ] check-dependabot-prs.shスクリプトを削除
- [ ] aidlc.tomlテンプレートから[inception.dependabot]セクションを削除
- [ ] README.mdからDependabot機能の説明を削除
- [ ] 残存確認: `rg -i dependabot prompts/ README.md` で prompts/ と README.md に残存記述がないことを確認
- [ ] 【追加】アップグレード時の廃止設定移行機能をsetup-prompt.mdに追加

## 備考

- 既存プロジェクトの`aidlc.toml`に`[inception.dependabot]`セクションが残っていても、参照箇所が削除されるため影響なし（後方互換性維持）
- `docs/aidlc/` への反映は Operations Phase でのアップグレード時に rsync で実施
- `CHANGELOG.md` は過去の変更履歴であり、削除対象外（歴史的記録として保持）
- `docs/cycles/` 配下の過去サイクル成果物に含まれる dependabot への言及は、過去の履歴として保持（削除しない）
