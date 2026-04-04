# Unit: Git関連設定キーの統合

## 概要
Git関連の設定キーが `rules.branch`, `rules.worktree`, `rules.unit_branch`, `rules.squash`, `rules.commit` の5セクションに分散している問題を解消し、`[rules.git]` セクションに統合する。

## 含まれるユーザーストーリー
- ストーリー 1: Git関連設定キーの統合

## 責務
- `defaults.toml` の新キー定義（`[rules.git]` セクション）
- `read-config.sh` への旧キーフォールバック実装
- `preflight.md` のバッチ取得キーリスト更新
- ステップファイル内の設定キー参照更新（`inception/01-setup.md`, `construction/01-setup.md`, `common/commit-flow.md`）
- `aidlc-setup` の `detect-missing-keys.sh` の新キー対応
- `aidlc-setup` の `defaults.toml` 同期

## 境界
- `read-config.sh` の基本アーキテクチャ変更は含まない（フォールバックロジック追加のみ）
- `config.toml` のマージ戦略変更は含まない

## 依存関係

### 依存する Unit
- なし（最初に実施）

### 外部依存
- dasel (v2/v3)

## 非機能要件（NFR）
- **パフォーマンス**: `read-config.sh` のフォールバック追加による実行時間増加は無視できる範囲
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- フォールバック方向: 新キー（`rules.git.*`）を優先、不在時に旧キー（`rules.branch.mode` 等）を読み取り
- 既存フォールバックパターン（`rules.history.level` → `rules.depth_level.history_level`）を参考にする
- `defaults.toml` 更新後は `aidlc-setup/config/defaults.toml` との同期が必要

## 関連Issue
- #521

## 実装優先度
High

## 見積もり
中規模（defaults.toml + read-config.sh + ステップファイル群の参照更新）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-04
- **完了日**: 2026-04-04
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -
