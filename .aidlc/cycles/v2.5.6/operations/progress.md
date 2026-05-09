# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-05-09 |
| 2. デプロイ準備 | スキップ | - | 2026-05-09 (理由: 変更なし、semi_auto §2.3) |
| 3. CI/CD構築 | スキップ | - | 2026-05-09 (理由: 変更なし、semi_auto §2.3) |
| 4. 監視・ロギング戦略 | スキップ | - | 2026-05-09 (理由: 変更なし、semi_auto §2.3) |
| 5. 配布 | スキップ | - | 2026-05-09 (理由: project.type=general、配布対象外) |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-05-09 |
| 7. リリース準備 | 完了 | README.md, history.md, PR | 2026-05-09 |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（v2.4.x マージ前完結契約導入元: DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=675

<!-- release_prep_commit: -->

## 現在のステップ

PR準備完了（§7.7 コミット待ち / マージ前完結契約成立点）。次回: §7.7.1 release_prep_commit slot 記録 → §7.8 PR Ready 化 → §7.12 PR マージ前レビュー → §7.13 PR マージ。

## 完了済みステップ

- 1. 変更確認（semi_auto §2.3 で「いいえ」自動選択、ステップ2-5 一括スキップ）
- 2-4. デプロイ準備 / CI/CD / 監視（変更なしのためスキップ）
- 5. 配布（project.type=general のためスキップ）
- 6. バックログ整理と運用計画（post_release_operations.md 作成、Closes Issue 自動クローズ判定）
- 7.1-7.6. リリース準備（version v2.5.6 / CHANGELOG / README / history / progress 固定スロット reserve）

## 次回実行時の指示

変更確認（ステップ1）から開始してください。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ5（配布）をスキップ

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
