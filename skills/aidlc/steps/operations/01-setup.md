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

### 11. Milestone 紐付け確認・fallback 判定【重要】

**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
scripts/read-config.sh rules.github.milestone_enabled
```

実行結果（exit 0 で stdout が `true`、それ以外はキー不在 / 致命エラー）を `MILESTONE_ENABLED` として扱う。stdout が `true` 以外、または exit コードが 0 でない場合は `false` 相当として扱う。

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=01-setup-step11:reason=opt-out` を出力し、**本ステップ（11-1 Milestone 状態確認 + 11-2 関連 Issue 紐付け補完 + 11-3 PR 紐付け確認 + 末尾 `LINK_FAILED` 集約判定）をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定 / Milestone 紐付け処理 / `LINK_FAILED` 集約判定 exit 1 契約は **一切実行しない**（紐付け処理自体を実施しないため）
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定 + 11-1 / 11-2 / 11-3 + 末尾 `LINK_FAILED` 集約判定を実行する

**`gh_status` を参照する。**

`gh_status` が `available` 以外の場合: 以下のメッセージを表示し **exit 1 で中断する**（Milestone 作成・紐付け未実施のままサイクル進行を許すと、04-completion 5.5 で Milestone close 必須契約に到達不能になるため）:

```text
ERROR: GitHub CLI が利用できないため Milestone 紐付け確認・fallback 作成を実行できません。
[rules.github].milestone_enabled=true の opt-in 設定では、Milestone は Inception Phase で作成され、Operations Phase で close される運用が必須です。
gh CLI / 認証を復旧してから 01-setup ステップ 11 を再実行してください。

復旧が困難な場合の選択肢:
1. .aidlc/config.toml の [rules.github].milestone_enabled=false に切り替えて opt-out（Milestone 関連ステップを全てスキップ、サイクル可視化機能なしで進行）
2. GitHub UI で Milestone {{CYCLE}} を手動作成 + 関連 Issue/PR を手動紐付け後、本ステップをスキップ可（04-completion 5.5 でも UI から手動 close 想定）
```

`gh_status` が `available` の場合、`scripts/milestone-ops.sh setup-step11` を実行する。本 subcommand は 11-1 / 11-2 / 11-3 を 1 回で実行し、Issue 紐付け失敗 + PR 紐付け失敗を **末尾で集約してから exit 1** する設計のため、Issue 失敗時に PR 紐付けが skip される問題を回避できる。

```bash
scripts/milestone-ops.sh setup-step11 {{CYCLE}}
```

スクリプトの内部処理（順次実行 + 末尾集約判定）:

#### 11-1. Milestone 状態確認（5 ケース判定 + fallback 作成）（setup-step11 内部処理）

OWNER/REPO 動的解決 + `gh api --paginate ...?state=all&per_page=100` で全ページ取得 + 5 ケース分岐:

- `closed≥1` → ERROR + exit 1（同名 closed 衝突、誤再オープン防止）
- `open≥2 closed=0` → ERROR + exit 1（重複作成）
- `open=1 closed=0` → 既存 Milestone を再利用 / `milestone:{{CYCLE}}:exists:number=<N>`
- `open=0 closed=0` → WARNING + fallback 作成 (`gh api --method POST`) / `milestone:{{CYCLE}}:fallback-created:number=<N>`

#### 11-2. 関連 Issue/PR の Milestone 紐付け確認・補完（setup-step11 内部処理）

Unit 定義ファイル群から関連 Issue 番号を抽出（Inception 05-completion ステップ1-2 と同じ awk ロジック、5 形式対応）。各 Issue について:

- `gh issue view --json milestone` で現在の紐付け状態を確認
- empty → `gh api --method PATCH .../issues/<N> -F milestone=<MILESTONE_NUMBER>` で新規紐付け（**operations モードでは PATCH を主経路に**: 既存紐付け済み多数前提で番号指定が確実）
- 同 cycle → already-linked（冪等動作）
- 他 cycle → WARNING + skip-overwrite（**冪等補完原則**: 1 Issue = 1 Milestone 制約遵守）
- view 失敗 / PATCH 失敗 → `LINK_FAILED` に蓄積、**continue で次の Issue を処理**

stdout 出力（1 行 / Issue）:

- `issue:<N>:linked:milestone={{CYCLE}}:via-api`（新規紐付け成功）
- `issue:<N>:already-linked:milestone={{CYCLE}}`（同 cycle に既紐付け）
- `issue:<N>:other-milestone:current=<TITLE>:skip-overwrite`（他 cycle に紐付け済み）
- `milestone:{{CYCLE}}:no-issues-to-link`（Unit 定義に関連 Issue 不在 / units/ ディレクトリ空）

#### 11-3. PR の Milestone 紐付け確認（setup-step11 内部処理）

現在のブランチに紐づく open PR を `gh pr list --head <current-branch> --state open` で取得し、同様の 3 分岐で処理（PR は Issue API 経由で Milestone を操作する GitHub 仕様）。失敗時は `LINK_FAILED` に追加し continue。

stdout 出力:

- `pr:<N>:linked:milestone={{CYCLE}}:via-api`（新規紐付け成功）
- `pr:<N>:already-linked:milestone={{CYCLE}}`（同 cycle に既紐付け）
- `pr:<N>:other-milestone:current=<TITLE>:skip-overwrite`（他 cycle に紐付け済み）
- `pr:not-found-or-not-open`（PR 未作成 / 既マージ、警告なし）

**末尾集約判定契約**: 11-2 の Issue 紐付け失敗 + 11-3 の PR 紐付け失敗を `LINK_FAILED` 変数で合算し、**1 件でもあれば最後に exit 1** で中断する。これにより、Issue 失敗時に PR チェックが skip される問題（codex round 10 P2）を回避し、運用者は 1 回の実行で全ての要修正対象を把握できる。失敗対象を手動で復旧してから本ステップを再実行する（または `.aidlc/cycles/{{CYCLE}}/operations/tasks/` に手動対応タスクを作成）。link-failed が解消するまで 04-completion ステップ5.5 (Milestone close) は実施しない契約とする。

**注**: `gh issue edit --milestone` ではなく `gh api PATCH` を主経路にしているのは、Operations 開始時点では Inception で既に紐付け済みケースが多く、確実に Milestone 番号を指定するため。

**判定マトリクス**（5 ケース、ストーリー 2 受け入れ基準準拠、Unit 005 と同じ 5 行表記）:

| open 件数 | closed 件数 | 動作 |
|----------|-----------|------|
| ≥ 2 | 0 | エラー停止（重複作成、手動整理を要求） |
| 1 | 0 | 再利用（既存 open を使用） |
| 0 | 0 | **fallback 作成**（Inception スキップ漏れ救済、警告メッセージ表示） |
| 0 | ≥ 1 | エラー停止（誤再オープン防止、手動判断要求） |
| ≥ 1 | ≥ 1 | エラー停止（混在、誤再オープン防止 / 優先順位 1 と整合） |

実装側では `CLOSED_COUNT >= 1` を最優先停止条件としており、この優先順位はストーリー 2 受け入れ基準と完全一致（4 段階優先順位で 5 ケースを畳み込んで表現）。

---
