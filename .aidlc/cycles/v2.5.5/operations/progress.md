# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-05-08 |
| 2. デプロイ準備 | スキップ | - | semi_auto 変更なし |
| 3. CI/CD構築 | スキップ | - | semi_auto 変更なし |
| 4. 監視・ロギング戦略 | スキップ | - | semi_auto 変更なし |
| 5. 配布 | スキップ | - | project.type=general のためスキップ |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-05-08 |
| 7. リリース準備 | 完了 | README.md, history.md, PR | 2026-05-08 |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（v2.4.x マージ前完結契約導入元: DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=668

<!-- release_prep_commit: 1dd38b70a4ff7a30c5da0733316caf8e50d46c0a -->

## 現在のステップ

次回: PR Ready 化 → マージ前レビュー → PRマージ → 04-completion

## 完了済みステップ

- 1. 変更確認（2026-05-08, semi_auto: 変更なし → 2-5 スキップ）
- 6. バックログ整理と運用計画（2026-05-08, post_release_operations.md 作成）
- 7. リリース準備（2026-05-08, version.txt/CHANGELOG/README/履歴更新, PR準備完了）

## 次回実行時の指示

PR #668 の Ready 化 → マージ前レビュー → PR マージ → 04-completion へ進む。

## プロジェクト種別による差異

- project.type=general: ステップ5（配布）をスキップ

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
