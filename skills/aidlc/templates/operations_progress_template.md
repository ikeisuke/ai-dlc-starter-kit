# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 未着手 | - | - |
| 2. デプロイ準備 | 未着手 | operations/deployment_checklist.md | - |
| 3. CI/CD構築 | 未着手 | operations/cicd_setup.md | - |
| 4. 監視・ロギング戦略 | 未着手 | operations/monitoring_strategy.md | - |
| 5. 配布 | 未着手 | operations/distribution_feedback.md | - |
| 6. バックログ整理と運用計画 | 未着手 | operations/post_release_operations.md | - |
| 7. リリース準備 | 未着手 | README.md, history.md, PR | - |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=false
completion_gate_ready=false
pr_number=

<!-- release_prep_commit: -->

## 現在のステップ

次回: 1. 変更確認

## 完了済みステップ

なし

## 次回実行時の指示

変更確認（ステップ1）から開始してください。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ5（配布）をスキップ

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
