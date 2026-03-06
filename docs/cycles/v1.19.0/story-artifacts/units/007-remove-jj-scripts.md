# Unit: jjサポート削除 - スクリプト

## 概要
シェルスクリプトからjj関連処理を除去し、git処理のみの環境で正常動作することを確認する。

## 含まれるユーザーストーリー
- ストーリー 5: jjサポート関連処理の削除（スクリプト部分）

## 責務
- `prompts/package/bin/env-info.sh` からjj検出・ブックマーク取得処理を除去
- `prompts/package/bin/aidlc-cycle-info.sh` からjj優先ブランチ取得処理を除去
- `prompts/package/bin/aidlc-env-check.sh` からjjチェック処理を除去
- `prompts/package/bin/aidlc-git-info.sh` からVCS判定・jj状態取得処理を除去
- `prompts/package/bin/squash-unit.sh` からjj squash全実装（約100行）を削除
- `prompts/package/bin/migrate-config.sh` からjjセクション追加処理を除去
- 除去後、git処理のみの環境でsquash・ブランチ情報取得・コミットフローが正常動作することを確認

## 境界
- プロンプトファイルからのjj参照除去はUnit 006の責務
- 編集対象は `prompts/package/bin/` 配下（`docs/aidlc/bin/` は `prompts/package/` からのrsync同期先であり直接編集しない）

## 依存関係

### 依存する Unit
- Unit 006: remove-jj-prompts（依存理由: プロンプト側のjj参照除去が完了している必要がある。プロンプトからスクリプトを呼び出す際のjj条件分岐がUnit 006で除去されるため）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- squash-unit.shのjj実装（約100行）は完全削除
- 各スクリプトのjj関連行番号は既存コード分析時点のもの。実装時に再確認が必要
- git処理への影響がないことをスクリプトの動作確認で検証
- 既存コード分析のスクリプト一覧は `docs/aidlc/bin/` パスで記載されているが、実際の編集は `prompts/package/bin/` 配下で行う
- `migrate-config.sh` はUnit 002（depth_level追加）でも編集対象。推奨実装順: Unit 007（jj削除）→ Unit 002（depth_level追加）で競合リスクを最小化

## 実装優先度
High

## 見積もり
中規模（6スクリプトの修正 + 動作確認）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
