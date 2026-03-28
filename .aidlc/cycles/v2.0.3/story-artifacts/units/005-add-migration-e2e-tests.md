# Unit: v1→v2移行スクリプトE2Eテスト追加

## 概要
v1→v2移行スクリプト群（migrate-detect.sh, migrate-apply-*.sh, migrate-verify.sh）のE2Eテストをbats-coreで作成する。

## 含まれるユーザーストーリー
- ストーリー 5: v1→v2移行スクリプトE2Eテスト追加 (#427)

## 関連Issue
- #427

## 責務
- v1構造fixtureディレクトリの作成（tests/fixtures/）
- migrate-detect.shの8リソースタイプ全てのテスト
- migrate-apply-config.shのテスト（config.toml内のdocs/aidlc→skills/aidlcパス置換）
- migrate-apply-data.shのテスト（Markdownファイル内の参照パス置換）
- migrate-cleanup.shのテスト（削除対象リソースの除去確認）
- migrate-verify.shの3検証チェックのテスト
- E2Eテスト（detect→apply-config→apply-data→cleanup→verifyの一連フロー）
- CI自動実行の確認

## 境界
- 移行スクリプト本体の変更は含まない（テスト追加のみ）
- Unit 002によるバックログ関連変更がmigrate-detect.shに入る場合、テストはその変更を反映する

## 依存関係

### 依存するUnit
- Unit 002: ローカルバックログ廃止（依存理由: migrate-detect.shのバックログ検出ロジックが変更されるため、テストはその変更後の状態を対象とする）

### 外部依存
- bats-core（テストフレームワーク）

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- bats-coreフレームワーク使用
- SHA256ハッシュ検証を含むファイル完全性テスト
- fixtureは最小構成（テストに必要なファイルのみ）

## 実装優先度
Medium

## 見積もり
中規模（fixture作成＋テストケース作成）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-28
- **完了日**: 2026-03-28
- **担当**: @claude
- **エクスプレス適格性**: -
- **適格性理由**: -
