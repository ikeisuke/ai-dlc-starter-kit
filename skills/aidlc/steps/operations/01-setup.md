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

リモート追跡ブランチと local HEAD の同期状態を 2 ビット ancestry 分類で検出し、古い状態・diverged 状態で Operations Phase を進行するリスクを低減する（SKILL.md「推奨・提案応答確保ルール」参照）。

**チェック手順**:

`scripts/validate-git.sh remote-sync` を実行して stdout を取得する（一次ソース）:

```bash
scripts/validate-git.sh remote-sync
```

出力の `status:` 行と付随フィールド（`remote:` / `branch:` / `unpushed_commits:` / `behind_commits:` / `diverged_ahead:` / `diverged_behind:` / `recommended_command:` / `error:`）から UI 正規化状態にマッピングする。**AI エージェントは独自の git 判定を行わず、validate-git.sh の出力をそのまま消費する**（2 ビット分類ロジックは validate-git.sh 内に閉じる）。

**正規化状態と分岐**:

| validate-git.sh 出力 | 正規化状態 | 動作 |
|--------------------|-----------|------|
| `status:ok` | `up-to-date` | 「✓ リモートブランチと同期済みです」表示、続行 |
| `status:warning` + `unpushed_commits:N` | `up-to-date` | §6a は push 漏れを扱わない（7.9〜7.11 で検出）。続行 |
| `status:warning` + `behind_commits:N` | `behind` | 「⚠ リモートブランチに未取得のコミットが {N} 件あります」表示 → `AskUserQuestion`「取り込む / スキップして続行」 |
| `status:diverged` + `diverged_ahead:A` + `diverged_behind:B` + `recommended_command:<実値>` | `diverged`（新規） | 「⚠ リモートとローカルの履歴が分岐しています（ahead={A}, behind={B}）。squash 後などで履歴が書き換わった状態が想定されます。」表示 + `recommended_command:` 行の**実値**をそのまま推奨コマンドとしてユーザーに表示 → `AskUserQuestion`「force push を実行する（手動） / スキップして続行 / 中断」 |
| `status:error` + `error:fetch-failed:...` | `skipped`（reason=fetch-failed） | 「⚠ リモート同期チェックをスキップしました（リモート接続失敗）」表示、続行 |
| `status:error` + `error:no-upstream:...` | `skipped`（reason=no-upstream） | 「⚠ リモート同期チェックをスキップしました（upstream未設定）」表示、続行 |
| `status:error` + `error:branch-unresolved:...` | `skipped`（reason=detached-head） | 「⚠ リモート同期チェックをスキップしました（detached HEAD）」表示、続行 |
| `status:error` + `error:upstream-resolve-failed:...` | `skipped`（reason=upstream-resolve-failed） | 「⚠ リモート同期チェックをスキップしました（upstream 設定不正: branch.<name>.merge）」表示、続行 |
| `status:error` + `error:merge-base-failed:...` | `skipped`（reason=merge-base-failed） | 「⚠ リモート同期チェックをスキップしました（git 内部エラー: merge-base）」表示、続行 |
| `status:error` + `error:log-failed:...` | `skipped`（reason=log-failed） | 「⚠ リモート同期チェックをスキップしました（git 内部エラー: rev-list）」表示、続行 |

**behind 時の「取り込む」選択後**: ユーザーに手動で `git merge` または `git rebase` を依頼し、完了後にステップ6aを再実行して `up-to-date` を確認する。

**diverged 時の挙動【重要】**:

- `recommended_command:` 行のコロン以降を**そのまま**ユーザーに表示する（プレースホルダー展開・文字列加工を行わない）
- 例: `recommended_command:git push --force-with-lease origin HEAD:cycle/v2.3.5` → ユーザーには `git push --force-with-lease origin HEAD:cycle/v2.3.5` を表示
- **force push の自動実行は禁止**。ユーザーが「force push を実行する（手動）」を選択しても、AI エージェントが自動で `git push --force-with-lease` を実行してはならない。ユーザー自身が表示されたコマンドをコピペ実行する想定
- **事前確認の案内【必須】**: `recommended_command` は「ローカル側の履歴が正当な上書き対象」（例: 自分のブランチで squash / rebase / amend を行った直後）であることを前提とする推奨値。diverged は他の開発者の push や tracking 設定違いでも発生し、その場合 force push は他者の作業を破壊する。ユーザーへの表示時には以下の確認依頼を**必ず併記**する:
  - `git log HEAD..<remote>/<upstream_branch>` で upstream 側の差分コミットを確認（他者の作業・意図しない変更が含まれていないか）
  - `git log <remote>/<upstream_branch>..HEAD` でローカル側の差分コミットを確認（squash / rebase / amend で上書きする意図どおりか）
  - 上記を確認した上で「ローカル履歴を正として上書きしてよい」場合のみ `recommended_command` を実行
  - 他者のコミットが upstream に含まれる・tracking 設定違いが疑われる場合は「中断」を選択
- 「force push を実行する（手動）」選択後: ユーザーに表示コマンドの手動実行を依頼し、完了後にステップ6aを再実行して `up-to-date` を確認する
- 「中断」選択時: Operations Phase 開始を中断し、ユーザー判断で次アクションを決定

**AskUserQuestion 必須性**: `diverged` / `behind` は「ユーザー選択」（SKILL.md「AskUserQuestion 使用ルール」）に分類され、`automation_mode` に関わらず対話を省略してはならない。

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
