# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-06-11 |
| 2. デプロイ準備 | スキップ | operations/deployment_checklist.md | - |
| 3. CI/CD構築 | スキップ | operations/cicd_setup.md | - |
| 4. 監視・ロギング戦略 | スキップ | operations/monitoring_strategy.md | - |
| 5. 配布 | スキップ | operations/distribution_feedback.md | - |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-06-11 |
| 7. リリース準備 | 完了 | README.md, CHANGELOG.md, marketplace.json, history.md, PR #730 | 2026-06-11 |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（v2.4.x マージ前完結契約導入元: DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=730

<!-- release_prep_commit: 73e0190d579690055f05fe25625341dec270be56 -->

## 現在のステップ

7. リリース準備 完了（PR準備完了 / §7.7 Git コミット待ち）

## 完了済みステップ

- 1. 変更確認（完了 / 変更なしを選択、ステップ2-5スキップ）
- 2-5. デプロイ準備・CI/CD・監視・配布（スキップ）
- 6. バックログ整理と運用計画（完了 / 手動クローズ対象 Issue なし / post_release_operations.md 作成）
- 7. リリース準備（完了 / marketplace 3.0.0-alpha.1→3.0.0-alpha.2 / CHANGELOG [3.0.0-alpha.2] / README バッジ / 固定スロット 3 行更新。base=v3.0.0 統合ブランチ宛で auto-tag・pr-check ともに非発火）

## 次回実行時の指示

PR準備完了。03-release（PR Ready 化・マージ前レビュー・マージ）へ進む。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ5（配布）をスキップ

本サイクルの `project.type=general` のため、ステップ5（配布）はスキップ設定。

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
