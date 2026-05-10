# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-05-10 |
| 2. デプロイ準備 | スキップ | - | 2026-05-10 |
| 3. CI/CD構築 | スキップ | - | 2026-05-10 |
| 4. 監視・ロギング戦略 | スキップ | - | 2026-05-10 |
| 5. 配布 | スキップ | - | 2026-05-10 |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-05-10 |
| 7. リリース準備 | 完了 | README.md, CHANGELOG.md, marketplace.json, history/operations.md, PR #676 | 2026-05-10 |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（v2.4.x マージ前完結契約導入元: DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=676

<!-- release_prep_commit: f16cb589c9c6e8a8c3d4413a9910d63515f22a5c -->

## 現在のステップ

次回: 03-release / 04-completion（PR Ready 化以降）

## 完了済みステップ

- ステップ1: 変更確認（semi_auto 自動判定で「変更なし」を選択 → ステップ2-5 スキップ）
- ステップ6: バックログ整理と運用計画（post_release_operations.md 作成 / PR Closes 自動クローズ #614 #615 #617 #618 #667 #673 を確認）
- ステップ7: リリース準備（CHANGELOG / README / marketplace.json は Construction Phase Unit 007 で更新済み、history/operations.md 追記、固定スロット更新、PR #676 は Draft で既存）

## 次回実行時の指示

`03-release.md` の手順に従い、PR Ready 化、コミット漏れ確認、リモート同期、PR マージ前レビューを実施してください。

## プロジェクト種別による差異

- プロジェクト種別: `general` → ステップ5（配布）をスキップ

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
