# Unit: バージョンチェック改善・setup早期判定改修

## 概要
`/aidlc`起動時のバージョンチェック（ステップ6）を改善し、setupスキルの早期判定を改修してバージョン不一致時にアップグレードモードに遷移できるようにする。

## 含まれるユーザーストーリー
- ストーリー 5: バージョンチェック改善
- ストーリー 7: setupスキルの早期判定改修

## 責務
- バージョンチェックの設定キーリネーム、デフォルト有効化、メタ開発スキップ廃止
- setupスキルのconfig.toml存在時の早期判定にバージョン比較を追加
- `config/defaults.toml`のデフォルト値更新

## 境界
- 3ソース比較のComparisonModeロジックの大枠は維持（メッセージと条件分岐の改修のみ）
- setupスキルの初回セットアップ・移行モードは変更しない

## 依存関係

### 依存する Unit
- なし（ただしUnit 005と同じ `01-setup.md` を編集するため、Unit 004を先に実装し、Unit 005は差分追加とする）

### 外部依存
- GitHub raw content API（リモートバージョン取得）

## 非機能要件（NFR）
- リモート取得タイムアウト: 5秒（既存値維持）

## 技術的考慮事項
- 設定キー: `rules.version_check.enabled`（新キー優先、旧キー`rules.upgrade_check.enabled`フォールバック）
- defaults.toml更新: `upgrade_check.enabled = false` → `version_check.enabled = true`
- 01-setup.md ステップ6: STARTER_KIT_DEVスキップ条件を削除、設定キー参照を変更
- 01-detect.md: config.toml存在時に`starter_kit_version`とsetupスキルのversion.txtを比較、不一致ならアップグレードモード遷移
- migrate-config.sh: `rules.upgrade_check`セクションのマイグレーション処理を`rules.version_check`に更新

## 関連Issue
- なし（バージョンチェック改善は既存機能の改修）

## 実装優先度
High

## 見積もり
中（ステップファイル2件、設定ファイル、マイグレーションスクリプトの改修）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-03
- **完了日**: 2026-04-03
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -
