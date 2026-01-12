# Unit: iOSバージョン確認強化

## 概要
Operations PhaseでiOSプロジェクトのビルド番号（CURRENT_PROJECT_VERSION）の確認手順を追加する。

## 含まれるユーザーストーリー
- ストーリー 4-1: Operations Phaseでのビルド番号確認 (新規)

## 責務
- Operations Phase ステップ1でMARKETING_VERSIONの確認
- CURRENT_PROJECT_VERSIONが前バージョンからインクリメントされているか確認
- 同じ場合はインクリメントを提案
- project.type = "ios" の場合のみ実行

## 境界
- MARKETING_VERSION（アプリバージョン）の自動更新は既存機能
- ビルド番号の自動インクリメントは対象外（CI/CD推奨）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- prompts/package/prompts/operations.md のステップ1を修正
- project.type = "ios" の判定はaidlc.tomlから読み取り
- 確認コマンド:
  ```bash
  # 現在のバージョン
  grep -E "MARKETING_VERSION|CURRENT_PROJECT_VERSION" *.xcodeproj/project.pbxproj | sort -u

  # 前バージョン（mainブランチ）と比較
  git show main:*.xcodeproj/project.pbxproj | grep -E "CURRENT_PROJECT_VERSION" | head -1
  ```
- App Storeは同一ビルド番号での再提出を許可しない点を注意書きに追加

## 実装優先度
Medium

## 見積もり
AI-DLCでは見積もりを行わない

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
