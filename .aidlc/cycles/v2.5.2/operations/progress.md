# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-05-06 |
| 2. デプロイ準備 | スキップ（変更なし） | - | - |
| 3. CI/CD構築 | スキップ（変更なし） | - | - |
| 4. 監視・ロギング戦略 | スキップ（変更なし） | - | - |
| 5. 配布 | スキップ（project.type=general） | - | - |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-05-06 |
| 7. リリース準備 | PR準備完了 | README.md, history.md, CHANGELOG.md, PR #642 | 2026-05-06 |

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=642

## 現在のステップ

次回: 7.7 Gitコミット → 7.8 ドラフトPR Ready化

## 完了済みステップ

- 1. 変更確認（2026-05-06、`automation_mode=semi_auto` により自動「いいえ」選択）
- 2-5. デプロイ準備・CI/CD・監視・配布（スキップ：変更なし／project.type=general）
- 6. バックログ整理と運用計画（2026-05-06、PR本文の Closes に #631/#632/#639 を統合し PRマージで一括自動close、`post_release_operations.md` 作成）
- 7.1-7.6 リリース準備（2026-05-06、version.txt 2.5.2、CHANGELOG/README更新、bash-substitution/defaults-sync/size チェック合格、固定スロット 3 つ更新）

## 次回実行時の指示

7.7 でコミット → 7.8 でドラフト PR Ready 化（PR #642）→ 7.12 PR レビュー → 7.13 マージへ進みます。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ5（配布）をスキップ

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
