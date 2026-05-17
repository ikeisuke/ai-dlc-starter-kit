# Operations Phase 進捗管理

## ステップ一覧

| ステップ | 状態 | 成果物 | 完了日 |
|---------|------|--------|--------|
| 1. 変更確認 | 完了 | - | 2026-05-17 |
| 2. デプロイ準備 | スキップ | - | 2026-05-17 |
| 3. CI/CD構築 | スキップ | - | 2026-05-17 |
| 4. 監視・ロギング戦略 | スキップ | - | 2026-05-17 |
| 5. 配布 | スキップ | - | 2026-05-17 |
| 6. バックログ整理と運用計画 | 完了 | operations/post_release_operations.md | 2026-05-17 |
| 7. リリース準備 | 完了 | README.md, CHANGELOG.md, history/operations.md, PR | 2026-05-17 |
<!-- ステップ7「完了」状態は §7.6 で書き込み、§7.7 Git コミット時に PR ブランチで確定する（マージ前完結契約の成立点）。実際の main 反映は §7.13 PR マージ時（タイミング契約 SoT: operations-release.md §7.7）。「完了」と「PR準備完了」は §7.6 で書き込む状態の同義表現（02-deploy.md line 17 の状態ラベル定義参照）。マージ後（§7.13 後）の編集は禁止（v2.4.x マージ前完結契約導入元: DR-001 / Unit 002 / #583）。 -->

## 固定スロット（Operations 復帰判定用）

<!-- fixed-slot-grammar: v1 -->
release_gate_ready=true
completion_gate_ready=true
pr_number=711

<!-- release_prep_commit: 0212bdffb4cdaae1b748ab01e744b54855fba8c7 -->

## 現在のステップ

次回: 03-release（PR Ready 化 / マージ前 CI 通過確認 / マージ）

## 完了済みステップ

- 1. 変更確認（2026-05-17 / semi_auto により「いいえ」自動選択 / ステップ2-5 をスキップ）
- 2. デプロイ準備（スキップ / 変更なし）
- 3. CI/CD構築（スキップ / 変更なし）
- 4. 監視・ロギング戦略（スキップ / 変更なし）
- 5. 配布（スキップ / project.type=general）
- 6. バックログ整理と運用計画（2026-05-17 / PR #711 Closes による自動クローズ判定 / post_release_operations.md 作成）
- 7. リリース準備（2026-05-17 / バージョン v2.6.4 / CHANGELOG + README 更新 / 履歴記録 / 固定スロット PR準備完了）

## 次回実行時の指示

変更確認（ステップ1）から開始してください。

## プロジェクト種別による差異

- モバイルアプリ（ios/android）: 全ステップ実施
- デスクトップ/CLI（desktop/cli）: 全ステップ実施
- Web/バックエンド（web/backend/general）: ステップ5（配布）をスキップ

## メタ情報

- Cycle: v2.6.4
- Branch: cycle/v2.6.4
- project.type: general（ステップ5 配布はスキップ）
- automation_mode: semi_auto
- depth_level: standard
- review_mode: required
- review_tools: ['codex']
- squash_enabled: true
- markdown_lint: true
- unit_branch_enabled: false
- max_retry: 3
- merge_method: merge

## 再開時に読み込むファイル

コンパクション後やセッション再開時は、以下のコマンドを実行してください：

- `/aidlc operations`
