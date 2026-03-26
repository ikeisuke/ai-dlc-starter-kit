# Unit 005 計画: Unitブランチ設定統合

## 概要

aidlc.tomlの`[rules.unit_branch].enabled`設定を`construction.md`に反映し、設定に応じてUnitブランチ作成確認をスキップする。

## 現状分析

- **aidlc.toml**: `[rules.unit_branch]`セクションは既に存在（v1.7.0で追加済み）
- **construction.md**: 設定を参照するロジックが未実装

### 対象ファイル

- `prompts/package/prompts/construction.md`（メタ開発のためsource側を編集）

### 反映タイミング

このプロジェクトはメタ開発のため、`prompts/package/`への変更は**Operations Phase完了時**のrsyncで`docs/aidlc/`に反映される（`docs/cycles/rules.md`参照）。

## 実装計画

### Phase 1: 設計

このUnitはプロンプト修正のみのため、ドメインモデル・論理設計は**最小構成**で作成する。
- ドメインモデル: 概念と責務のみ記載（エンティティ定義等は省略）
- 論理設計: 変更箇所と処理フローのみ記載

**変更点**:
- construction.mdの「6. Unitブランチ作成【推奨】」セクションに設定確認ロジックを追加

### Phase 2: 実装

#### ステップ1: 設定確認ロジック追加

`[rules.unit_branch].enabled`の値を確認するコードブロックを追加:

```markdown
**設定確認**:
`docs/aidlc.toml`の`[rules.unit_branch]`セクションを確認し、`enabled`の値を取得する。
- `enabled = true`（デフォルト）: 従来通りUnitブランチ作成を提案
- `enabled = false`: Unitブランチ作成をスキップ
- **設定が存在しない場合**: `true`（従来動作）として扱う
```

#### ステップ2: 条件分岐の追加

enabled=falseの場合、Unitブランチ作成確認をスキップして次に進むフローを追加。

### テスト計画

- Markdownlintによる構文チェック
- 論理フローの妥当性確認（人間レビュー）

## 成果物一覧

| 成果物 | パス |
|--------|------|
| 修正ファイル | `prompts/package/prompts/construction.md` |
| 設計ドキュメント（最小） | `docs/cycles/v1.7.1/design-artifacts/domain-models/005_unit_branch_setting_domain_model.md` |
| 論理設計（最小） | `docs/cycles/v1.7.1/design-artifacts/logical-designs/005_unit_branch_setting_logical_design.md` |
| 実装記録 | `docs/cycles/v1.7.1/construction/units/005_unit_branch_setting_implementation.md` |

## 見積もり

30分
