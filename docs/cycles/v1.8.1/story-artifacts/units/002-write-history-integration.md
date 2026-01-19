# Unit: write-history.sh統合

## 概要

write-history.shを各プロンプト（inception.md、construction.md、operations.md）に統合し、履歴記録を標準化する。

## 含まれるユーザーストーリー

- ストーリー 2: write-history.shをプロンプトに統合

## 責務

- inception.mdのheredocをwrite-history.sh呼び出しに置換
- construction.mdのheredocをwrite-history.sh呼び出しに置換
- operations.mdのheredocをwrite-history.sh呼び出しに置換
- 従来のフォーマットとの互換性を維持
- 変更後の各mdファイルがmarkdownlintをパスすることを確認

## 境界

- write-history.sh自体の修正は行わない（既存スクリプトをそのまま利用）
- setup.mdの履歴記録は対象外（setup-context.mdは別処理）

## 依存関係

### 依存するUnit

- なし

### 外部依存

- write-history.sh（既存スクリプト）

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- write-history.shのオプション: `--cycle`, `--phase`, `--step`, `--content`, `--artifacts`
- フォーマット互換性: 見出し`## {TIMESTAMP}`、項目`- **フェーズ**:`等、区切り`---`

## 実装優先度

High

## 見積もり

中規模（3ファイルの複数箇所修正）

---

## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-19
- **完了日**: -
- **担当**: AI
