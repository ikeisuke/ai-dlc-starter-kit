# Unit: 設定基盤リファクタ

## 概要
aidlc.tomlの設定キー構造を統一し（`[backlog]` → `[rules.backlog]`）、read-config.shのデフォルト値を集中管理に移行する。

## 含まれるユーザーストーリー
- ストーリー 1: aidlc.toml設定キー構造の統一 (#207)
- ストーリー 2: read-config.shデフォルト値の集中管理 (#206)

## 責務
- aidlc.tomlの`[backlog]`セクションを`[rules.backlog]`に移動
- check-backlog-mode.sh、env-info.shの新キー対応（旧キーフォールバック付き）
- デフォルト値定義ファイルの作成
- read-config.shへのデフォルト値レイヤー追加
- プロンプト内の`--default`指定箇所の移行
- init-cycle-dir.shの互換確認（check-backlog-mode.sh経由で間接参照するため）

## 境界
- 新規スクリプト（check-issue-templates.sh等）の作成はこのUnitでは行わない
- aidlc.toml内の他のセクション（[project]等）の移動は行わない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- dasel（TOML解析）

## 非機能要件（NFR）
- **パフォーマンス**: 設定読み取りの応答時間に体感的な変化がないこと
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 新しい設定キーの追加が容易であること
- **可用性**: 該当なし

## 技術的考慮事項
- 後方互換性: 旧キー→新キーのフォールバック読み取り
- prompts/package/ を編集し、docs/aidlc/ へはrsyncで反映
- デフォルト値定義ファイルの配置場所: `prompts/package/config/defaults.toml`

## 関連Issue
- #207
- #206

## 推奨実装順序
001→005→002/003/004。Unit 001はread-config.shを変更するため最初に実施。Unit 005は設計検討（High優先度）のため次に実施。Unit 002-004は相互に独立しておりスクリプト作成のため任意順で並行実行可能。

## 実装優先度
High

## 見積もり
中規模（スクリプト修正5-6ファイル + デフォルト値定義ファイル新規作成 + プロンプト修正 + 全モード互換性テスト）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
