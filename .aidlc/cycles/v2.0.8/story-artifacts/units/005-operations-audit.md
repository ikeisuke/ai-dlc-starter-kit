# Unit: Operations Phase総点検

## 概要
Operations Phaseのステップファイル（steps/operations/01-04 + operations-release.md）と関連スクリプトの記述を実動作と突き合わせ、乖離を検出・修正する。

## 含まれるユーザーストーリー
- ストーリー 7: Operations Phase総点検

## 責務
- steps/operations/ の全ファイル（01-setup.md 〜 04-completion.md、operations-release.md）の記述と実動作の突き合わせ
- 関連スクリプト（pr-ops.sh, issue-ops.sh, post-merge-cleanup.sh等）の動作確認
- 重大な乖離の修正
- 軽微な乖離のIssue化

## 境界
- 共通ステップ（steps/common/）の点検は含まない（参照時に問題が見つかった場合のみ対応）
- テンプレート・ガイドの網羅的な点検は含まない。ただし、参照先で重大な乖離が見つかった場合は当該参照先も修正対象に含む

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
- Operations Phaseはデプロイ・リリース・PR管理を含む
- .aidlc/rules.md のカスタムワークフローとの整合性も確認

## 関連Issue
なし

## 実装優先度
High

## 見積もり
中規模（5ファイル + 関連スクリプト）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-29
- **完了日**: 2026-03-29
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
