# Unit: read-config.sh --default廃止とバッチモード化

## 概要
read-config.shから--defaultオプションを廃止し、全プロンプトから使用箇所を除去する。また、preflight.mdの設定取得を--keysバッチモード1回に集約する。

## 含まれるユーザーストーリー
- ストーリー 5: read-config.sh --default廃止
- ストーリー 6: プリフライト設定取得のバッチモード化

## 関連Issue
- #376

## 責務
- read-config.shから--defaultオプションの実装削除（HAS_DEFAULT, DEFAULT_VALUE変数、関連分岐）
- 全プロンプト・ドキュメントから--default使用箇所の除去（20箇所以上）:
  - preflight.md（11箇所）
  - inception.md（3箇所）
  - rules.md（10箇所以上）
  - commit-flow.md, feedback.md, compaction.md, aidlc-setup SKILL.md（各1箇所）
- preflight.mdの設定取得を--keysバッチモード1回に集約
- 終了コード互換性の維持確認

## 境界
- defaults.tomlへの値追加は含まない（Unit 3で完了済み前提）
- read-config.shの--keysバッチモード自体の実装変更は含まない（既存機能を活用）

## 依存関係

### 依存する Unit
- 003-defaults-toml-consolidation（依存理由: defaults.tomlにデフォルト値が集約されている必要がある。--default廃止後はdefaults.tomlがフォールバックの唯一の手段となるため）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- 編集対象は `prompts/package/` 配下
- `grep -r "\-\-default" prompts/package/` で使用箇所を網羅的に検出
- 変更後の動作確認: 各キーがdefaults.toml経由で正しく取得できることを確認
- ロールバック: git revertでコミット単位で可能

## 実装優先度
High

## 見積もり
中（影響範囲が広く、20箇所以上のドキュメント更新）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
