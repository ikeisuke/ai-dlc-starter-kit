# Unit: Construction/Opsステップファイル乖離修正

## 概要
Construction PhaseおよびOperations Phaseのステップファイルとスクリプトの記述乖離を修正する。

## 含まれるユーザーストーリー
- ストーリー 2: Construction Phase ステップファイルの乖離修正
- ストーリー 4: Operations Phase 乖離一括修正

## 責務
- issue-ops.sh の出力形式をconstruction 01-setup.mdに追記（#474）
- Operations Phase 7項目の乖離修正（#477）

## 境界
- Inception Phaseのステップファイルは対象外（Unit 001で対応）
- スクリプトの引数体系変更は行わない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- メタ開発のため、skills/aidlc/ 配下のファイルを編集する
- post-merge-cleanup.sh の `--` 除去はスクリプト実装修正を含む

## 関連Issue
- #474
- #477

## 実装優先度
Medium

## 見積もり
中（ドキュメント修正+スクリプト軽微修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
