# Unit: デグレファイル復元

## 概要
v1.2.0で欠落したprompt-reference-guide.mdとoperations関連ファイルを復元または参照を整理する

## 含まれるユーザーストーリー
- ストーリー4: デグレファイルの復元

## 責務
- prompt-reference-guide.mdをprompts/package/prompts/に復元
- operations/README.md参照を確認し、必要に応じて削除または作成

## 境界
- 新規機能の追加は行わない
- 既存ファイルの内容変更は最小限に

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
- v1.1.0のsetup/common.mdからprompt-reference-guide.mdの内容を確認
- setup-init.mdのoperations/README.md参照箇所を特定

## 実装優先度
Low

## 見積もり
0.5時間
