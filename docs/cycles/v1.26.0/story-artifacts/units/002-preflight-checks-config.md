# Unit: プリフライトチェック項目の設定化

## 概要
プリフライトチェックの項目（gh, review-tools等）のon/offを `aidlc.toml` の `[rules.preflight]` セクションで制御可能にする。

## 含まれるユーザーストーリー
- ストーリー 2: プリフライトチェック項目の設定化

## 関連Issue
- #323

## 責務
- `aidlc.toml` に `[rules.preflight]` セクション（`enabled`, `checks`）を追加
- `preflight.md` のチェック処理を設定値に基づく分岐に変更
- blockerチェック（git, aidlc.toml）は `enabled` 設定に関わらず常時実行を保証
- `enabled=false` 時はオプションチェック（gh, review-tools, config-validation）のみスキップし、blockerチェックは実行する

## 境界
- 既存プリフライトチェック項目の仕様変更は含まない（on/off制御の追加のみ）
- `read-config.sh` の改修は含まない（既存の配列読取機能を活用）
- 新規チェック項目の追加は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- `read-config.sh` の配列読取機能（既存実装）
- `dasel` TOML解析（既存実装）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: `checks` リストに項目を追加するだけで新規チェックを有効化可能
- **可用性**: 該当なし

## 技術的考慮事項
- `prompts/package/prompts/common/preflight.md` の手順4, 5を設定駆動に変更
- `docs/aidlc.toml` にデフォルト設定を追加
- バリデーション: 未知のチェック項目は警告して無視
- 有効値: `gh`, `review-tools`, `config-validation`

## 実装優先度
High

## 見積もり
中規模（プロンプト変更 + 設定ファイル追加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
