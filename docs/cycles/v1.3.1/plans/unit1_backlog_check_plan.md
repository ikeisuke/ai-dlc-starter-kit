# Unit 1: バックログ対応済みチェック - 実装計画

## 概要

Inception Phaseでバックログを確認する際に、過去に対応済みの項目かどうかを自動チェックする機能を追加する。

## 対象ファイル

- `prompts/package/prompts/inception.md` - バックログ確認ステップに対応済みチェック手順を追加

## 変更内容

### ステップ3「バックログ確認」への追加

現在のinception.mdのステップ3は以下の構成：
- 3-1. 共通バックログ確認
- 3-2. サイクル固有バックログ確認

これに以下を追加：
- 3-3. 対応済みバックログとの照合

### 追加する手順（3-3）

```markdown
#### 3-3. 対応済みバックログとの照合

`docs/cycles/backlog-completed.md` の存在を確認：

- **存在しない場合**: スキップ
- **存在する場合**: 3-1, 3-2で確認したバックログ項目と照合
  - 対応済みファイルに同名または類似の項目があれば、ユーザーに通知
  ```
  以下のバックログ項目は過去に対応済みの可能性があります：
  - [項目名]: backlog-completed.md に類似項目あり

  これらの項目について確認しますか？
  ```
  - 照合は項目名（見出し）ベースで実施
  - 完全一致でなくても、キーワードが重複する場合は通知
```

## 設計方針

- **通知のみ**: バックログ項目の自動移動・自動削除は行わない
- **照合方法**: 見出しテキストの比較（完全一致 + キーワード重複）
- **対象範囲**: `docs/cycles/backlog-completed.md` のみ参照（過去サイクルのhistory.md等は参照しない）

## 実装手順

1. Phase 1: 設計（ドメインモデル設計、論理設計）
2. Phase 2: 実装（prompts/package/prompts/inception.md の修正）
3. 統合とレビュー

## 成果物

- `docs/cycles/v1.3.1/design-artifacts/domain-models/unit1_backlog_check_domain_model.md`
- `docs/cycles/v1.3.1/design-artifacts/logical-designs/unit1_backlog_check_logical_design.md`
- `prompts/package/prompts/inception.md`（修正）
- `docs/cycles/v1.3.1/construction/units/unit1_backlog_check_implementation.md`
