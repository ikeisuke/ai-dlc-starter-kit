# Unit: dasel v3対応

## 概要
`aidlc-setup` のバージョン比較でdasel v3のコマンド形式変更により失敗する問題を修正する。プロンプトファイル内のdaselコマンド例をv2/v3両対応に更新する。

## 含まれるユーザーストーリー
- ストーリー 3: dasel v3対応

## 責務
- `aidlc-setup/steps/01-detect.md` のdaselコマンド例をv2/v3両対応に更新（プロンプトファイルのみ）
- `aidlc-setup/steps/02-generate-config.md` のdaselコマンド例をv2/v3両対応に更新（プロンプトファイルのみ）
- 注: スクリプト（`read-config.sh`, `bootstrap.sh`, `detect-missing-keys.sh`）は既にv2/v3対応済みのため変更しない。dasel未インストール時のフォールバックも既存スクリプトで処理済み

## 境界
- `read-config.sh` / `bootstrap.sh` の変更は含まない（既にv2/v3対応済み）
- `detect-missing-keys.sh` の変更は含まない（既にv2/v3対応済み）
- dasel以外の設定パーサーへの移行は含まない

## 依存関係

### 依存する Unit
- なし（他のUnitと独立して並列実行可能）

### 外部依存
- dasel (v2/v3)

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: dasel v2/v3の両環境で動作すること

## 技術的考慮事項
- dasel v2: `dasel -f file 'key'`（読取）/ `dasel put -f file -t type 'key' -v 'value'`（書込）
- dasel v3: `cat file | dasel -i toml 'key'`（読取、`-f` フラグ廃止）/ `put` サブコマンド廃止（書込不可、AI直接編集で代替）
- プロンプト内にv2/v3両形式を直接併記し、AIが試行で判定する方式を採用（既存スクリプトへの新たな依存は追加しない）

## 関連Issue
- #528

## 実装優先度
High

## 見積もり
小規模（プロンプトファイル2箇所のコマンド例更新）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-05
- **完了日**: 2026-04-05
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -
