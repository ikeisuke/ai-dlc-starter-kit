# Unit: アップグレード判定修正

## 概要
check-setup-type.shとcheck-version.shを修正し、既存プロジェクトのアップグレードを正しく検出する

## 含まれるユーザーストーリー
- ストーリー 5（分割1/2）

## 責務
check-version.shのsemver正規表現修正（vプレフィックス正規化）、check-setup-type.shのフォールバック改善（docs/aidlc.toml存在時はinitialではなくupgradeとして扱う）

## 境界
sync処理やパスフォールバックの修正はUnit 006の範囲

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
対象ファイル: prompts/setup/bin/check-setup-type.sh、prompts/setup/bin/check-version.sh。根本原因: vプレフィックス付きバージョンがsemver正規表現に拒否され、not_found→initialにマッピングされる

## 実装優先度
High

## 見積もり
小規模（スクリプト修正）

## 関連Issue
- なし

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-15
- **完了日**: 2026-03-15
- **担当**: @claude
