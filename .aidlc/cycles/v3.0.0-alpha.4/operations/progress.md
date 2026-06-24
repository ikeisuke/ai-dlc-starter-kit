# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-06-24 |
| 2. デプロイ準備 | スキップ | operations/deployment_checklist.md | - |
| 3. CI/CD構築 | スキップ | operations/cicd_setup.md | - |
| 4. 監視・ロギング戦略 | スキップ | operations/monitoring_strategy.md | - |
| 5. 配布 | スキップ | operations/distribution_feedback.md | - |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-06-24 |
| 7. リリース準備 | 完了 | README.md, history.md, PR | 2026-06-24 |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（v2.4.x マージ前完結契約導入元: DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=734

<!-- release_prep_commit: ff088ed1bc9f74b138ad8d0fcde03c7bbc5b3050 -->

## 現在のステップ

次回: PR Ready 化・マージ前レビュー（03-release）

## 完了済みステップ

- 1. 変更確認（完了 / 変更なし選択）
- 2-5. スキップ（変更なし選択 / ステップ5は project.type=general）
- 6. バックログ整理と運用計画（完了 / 自動クローズ対象・手動クローズ対象なし）
- 7. リリース準備（PR準備完了 / バージョン更新・CHANGELOG・README・履歴記録）

## 次回実行時の指示

PR Ready 化・マージ前レビュー（03-release）から開始してください。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ5（配布）をスキップ

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
