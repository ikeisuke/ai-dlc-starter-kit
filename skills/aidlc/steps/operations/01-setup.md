# Operations Phase セットアップ（`operations.01-setup`）

> 分岐ロジック・Phase 構成・`automation_mode` / `depth_level` / `project.type` 分岐・bootstrap 分岐・worktree フロー判定・AI レビュー分岐は `steps/operations/index.md`（フェーズインデックス）に集約されている。本ファイルは詳細手順のみを含む。

**フェーズの責務【重要】**:

- **行うこと**: デプロイ計画・実行、監視・ロギング設定、運用ドキュメント作成、CI/CD設定、インフラ設定
- **許可されるコード記述**: CI/CD設定、デプロイスクリプト、監視・アラート設定、インフラ定義
- **禁止**: アプリケーションロジック変更、新機能実装、テストコード追加（バグ修正時を除く）
- **緊急バグ修正**: ユーザー承認 → 最小限の修正 → Construction Phaseへのバックトラック提案

**プロンプト履歴管理**: `/write-history` スキルを使用して `.aidlc/cycles/{{CYCLE}}/history/operations.md` に記録。**AIレビュー対象タイミング**: デプロイ計画承認前、運用ドキュメント承認前。

**テスト記録とバグ対応**: テスト記録テンプレートは `templates/test_record_template.md`、バグ対応は Construction Phase の「バックトラック」セクションに従う。

---

## あなたの役割

DevOpsエンジニア兼SRE。

---

## 最初に必ず実行すること

### 1. サイクル存在確認

`.aidlc/cycles/{{CYCLE}}/` が存在しなければエラー（Inception Phaseを案内）。

### 2. 追加ルール確認

`.aidlc/rules.md` が存在すれば読み込む。

### 3. プリフライトチェック

結果（`gh_status`, `depth_level`, `automation_mode` 等）をコンテキスト変数として保持。

### 4. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合のみ実行。

### 5. Depth Level確認

プリフライトで取得済みの `depth_level` を確認。

### 6. 進捗管理ファイル確認【重要】

**パス**: `.aidlc/cycles/{{CYCLE}}/operations/progress.md`（`operations/` サブディレクトリ内）

- 存在する場合: 完了済みステップを確認、未完了から再開
- 存在しない場合: 初回実行として作成（`project.type` に応じて配布ステップをスキップ設定）

### 6a. リモート同期チェック【推奨】

リモート追跡ブランチに未取得のコミットがないか確認し、古い状態で Operations Phase を進行するリスクを低減する（SKILL.md「推奨・提案応答確保ルール」参照）。

**チェック手順**:

1. upstream remote を解決: `git config branch.<current_branch>.remote`（未設定時はフォールバック `origin`）
2. `GIT_TERMINAL_PROMPT=0 git fetch <resolved_remote>`
3. `git rev-list HEAD..@{u} --count`

**正規化状態と分岐**:

| git操作結果 | 正規化状態 | 動作 |
|------------|-----------|------|
| fetch成功 + rev-list = 0 | `up-to-date` | 「✓ リモートブランチと同期済みです」表示、続行 |
| fetch成功 + rev-list > 0 | `behind` | 「⚠ リモートブランチに未取得のコミットが {N} 件あります」表示 → `AskUserQuestion`「取り込む / スキップして続行」 |
| fetch失敗 | `skipped` | 「⚠ リモート同期チェックをスキップしました（リモート接続失敗）」表示、続行 |
| upstream未設定（`@{u}` 解決不可） | `skipped` | 「⚠ リモート同期チェックをスキップしました（upstream未設定）」表示、続行 |
| detached HEAD | `skipped` | 「⚠ リモート同期チェックをスキップしました（detached HEAD）」表示、続行 |

**behind 時の「取り込む」選択後**: ユーザーに手動で `git merge` または `git rebase` を依頼し、完了後にステップ6aを再実行して `up-to-date` を確認する。

### 6b. タスクリスト作成【必須】

**【次のアクション】** `steps/common/task-management.md` の「Operations Phase: タスクテンプレート」に従いタスクリスト作成。**タスクリスト未作成のまま次のステップに進んではいけない。**

### 7. 既存成果物の確認（冪等性の保証）

`.aidlc/cycles/{{CYCLE}}/operations/` の既存ファイルを確認。存在するファイルのみ読み込み、差分更新。

### 8. 運用引き継ぎ情報の確認【重要】

`.aidlc/operations.md` があれば読み込み、前回サイクルの設定を再利用。なければテンプレートから作成。

### 9. 全Unit完了確認【重要】

全Unit定義ファイルの「実装状態」が「完了」or「取り下げ」であることを確認。

| 状況 | 動作 |
|------|------|
| 全完了 + `semi_auto` | 自動遷移 |
| 全完了 + `manual` | 状態テーブル表示して続行 |
| 未完了あり | Construction Phaseに戻る / 続行の2択 |

### 10. Construction引き継ぎタスク確認【重要】

`.aidlc/cycles/{{CYCLE}}/operations/tasks/` 配下の手動作業タスクを確認。

- タスクあり: 一覧提示 → 順番に確認・実行（または後続ステップで処理）
- タスクなし: 次のステップへ

---
