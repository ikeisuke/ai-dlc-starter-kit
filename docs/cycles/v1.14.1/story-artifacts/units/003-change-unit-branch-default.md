# Unit: unit_branch.enabledデフォルト値変更

## 概要

`rules.unit_branch.enabled` の未設定時デフォルト値を `true` から `false` に変更する。ユーザーが明示的に有効化しない限り、Unitブランチ作成は推奨されない。

## 含まれるユーザーストーリー

- ストーリー3: unit_branch.enabledデフォルト値変更 (#182)

## 責務

- construction.mdの判定ロジック反転（未設定時の動作をスキップに変更）
- aidlc.tomlテンプレートのコメント更新

## 境界

- Unitブランチ機能自体の設計変更は行わない
- `enabled = true` 時の既存動作は変更しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

- prompts/package/prompts/construction.md を編集（387行目付近）
  - 変更前: `enabled = true`、未設定、または不正値の場合 → 実行
  - 変更後: `enabled = true` の場合のみ実行、それ以外（`false`、未設定、空文字、型不一致等）はスキップ
- prompts/package/templates/aidlc_toml_template.toml のコメント更新
  - 変更前: `# enabled: true | false - Unit開始時にUnitブランチ作成を提案するか（デフォルト: true）`
  - 変更後: `# enabled: true | false - Unit開始時にUnitブランチ作成を提案するか（デフォルト: false）`

## 関連Issue

- #182

## 実装優先度

Medium

## 見積もり

小規模（判定ロジック1行とコメント1行の変更）

---

## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
