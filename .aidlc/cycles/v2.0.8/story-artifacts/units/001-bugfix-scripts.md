# Unit: バグ修正（スクリプト）

## 概要
#463, #465, #466の3件のスクリプトバグを修正する。

## 含まれるユーザーストーリー
- ストーリー 1: squash-unit.sh --dry-run修正（#466）
- ストーリー 2: migrate-config.sh --dry-run修正（#463）
- ストーリー 3: bootstrap.sh依存脱却（#465）

## 責務
- squash-unit.sh の --dry-run 時 --message 必須チェックスキップ（1ファイル）
- migrate-config.sh の cleanup trap unbound variable修正（1ファイル）
- aidlc-setup/aidlc-migrate スクリプトの bootstrap.sh 依存除去（対象ファイル:
  - skills/aidlc-migrate/scripts/migrate-verify.sh
  - skills/aidlc-migrate/scripts/migrate-apply-data.sh
  - skills/aidlc-migrate/scripts/migrate-detect.sh
  - skills/aidlc-migrate/scripts/migrate-apply-config.sh
  - skills/aidlc-migrate/scripts/migrate-cleanup.sh
  - skills/aidlc-setup/scripts/migrate-backlog.sh）

## 境界
- スクリプトのリファクタリングは最小限（バグ修正に必要な範囲のみ）
- ステップファイルの修正は含まない

## 依存関係

### 依存する Unit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: 既存と同等
- **セキュリティ**: 変更なし
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- bash スクリプトの修正のみ
- 既存テスト（scripts/tests/）がある場合はテスト更新

## 関連Issue
- #466
- #465
- #463

## 実装優先度
High

## 見積もり
中規模（8ファイル修正: squash-unit.sh 1件 + migrate-config.sh 1件 + bootstrap.sh依存除去 6件）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
