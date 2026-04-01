# Unit: 運用安定化

## 概要
write-historyスキルのパス修正、reviewingスキルのCodex呼び出し統一、post-merge-sync.shのエラーハンドリング改善を行う。

## 含まれるユーザーストーリー
- ストーリー 8: write-historyスキルのパス・パーミッション修正 (#494)
- ストーリー 9: reviewingスキルのCodex呼び出し統一 (#491)
- ストーリー 10: post-merge-sync.shのエラーハンドリング改善 (#500)

## 責務
- skills/write-history/SKILL.mdのスクリプトパスを修正
- skills/aidlc-setup/のsettings-template.jsonにSkill(write-history)パーミッションを追加
- 全9つのreviewingスキルのSKILL.mdでCodex呼び出しをcodexスキル経由に変更
- bin/post-merge-sync.shにgit ls-remote --exit-codeによるリモートブランチ存在確認を追加

## 境界
- reviewingスキルのレビューロジック自体の変更は行わない
- post-merge-sync.shのローカルブランチ削除ロジックの変更は行わない

## 依存関係

### 依存する Unit
なし

### 外部依存
- codexスキル（reviewingスキルから参照）

## 非機能要件（NFR）
- **パフォーマンス**: post-merge-sync.shでgit ls-remoteの追加呼び出しが発生するが、ブランチ数は通常少数のため影響は無視できる
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- #491は9つのreviewingスキル全てに同じ変更を適用する必要がある
- #500のIssue本文に修正diffが記載済み（ほぼそのまま適用可能）
- #494のwrite-historyスキルはv2.1.0で新規追加されたスキル
- 3つのIssueは対象ファイルが完全に独立（スキルSKILL.md / settings-template.json / bin/post-merge-sync.sh）のため同一Unitで効率的に対応可能
- 検証観点: #494はwrite-history実行成功、#491は代表的なレビュー実行1件の成功、#500はpost-merge-sync.sh --dry-runでの正常終了

## 関連Issue
- #491
- #494
- #500

## 実装優先度
High

## 見積もり
中規模（複数スキルへの同一変更 + シェルスクリプト修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-01
- **完了日**: 2026-04-01
- **担当**: @ikeisuke
- **エクスプレス適格性**: -
- **適格性理由**: -
