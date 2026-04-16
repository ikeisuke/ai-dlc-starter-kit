# ユーザーストーリー

## Epic: Operations Phase 堅牢性向上（v2.3.5）

v2.3.4 までに発見された Operations Phase 由来のバグ群を修正し、復帰判定・リモート同期・PRマージフローの堅牢性を高める。

---

### ストーリー 1: Operations 復帰判定が「マージ前完結」ルールと整合する（#579）

**優先順位**: Must-have

As an AIエージェント（AI-DLC Construction/Operations 実行者）
I want to 復帰判定のチェックポイントが 7.7 最終コミット時点で全て確定する参照先を見るようにしたい
So that 7.8 以降に余計な履歴追記を行う誘因がなくなり、worktree に未コミット変更が残らない

**受け入れ基準**:

**正常系**:

- [ ] `operations/progress.md` にステップ7のサブステップ完了フラグ（少なくとも `release_done`, `completion_done` に対応するもの）が保持される構造となっている
- [ ] `phase-recovery-spec.md` §5.3 の `release_done` / `completion_done` 判定が `operations/progress.md` から読み取られるように更新されている
- [ ] `steps/operations/index.md` §3 の判定チェックポイント表が新しい参照先と整合している
- [ ] `templates/operations_progress_template.md` が新構造を含んでおり、新規サイクルではこのテンプレートが適用される

**後方互換**:

- [ ] 旧形式（v2.3.4 以前の `operations/progress.md` に新フラグが存在しない場合）を読み込んでも復帰判定が従来通り成立する
- [ ] 旧サイクルの実ファイル（`.aidlc/cycles/v2.3.4/` 等）には遡及的変更を加えない

**異常系（7.8 / 7.13 失敗時の復帰判定）**:

- [ ] `operations/progress.md` のサブステップフラグが記録された状態で 7.8（PR Ready 化）/ 7.13（PR マージ）が失敗しても、復帰判定はフェーズ全体を「完了」と誤認しない
- [ ] 復帰判定の判定根拠は「progress.md のフラグ（7.7 コミット時点の記録）」と「外部実態（GitHub PR の Ready 状態 / マージ済み状態）」の照合で行われる。フラグのみでは「完了」と判定しない
- [ ] 7.8 失敗時: progress.md の `release_done` 予約は立っているが GitHub PR が `draft=true` の場合、復帰判定は「7.7 まで完了、7.8 未完」と認識し、再開時は 7.8 から再実行できる
- [ ] 7.13 失敗時: progress.md の `completion_done` 予約は立っているが PR が未マージの場合、復帰判定は「7.12 まで完了、7.13 未完」と認識し、再開時は 7.13 から再実行できる
- [ ] GitHub API が利用不可（`gh_status != available`）な場合、復帰判定は `undecidable:<reason_code>`（`phase-recovery-spec.md` §6 の戻り値契約）を返し、`automation_mode=semi_auto` でも自動継続せずユーザー確認フローへ遷移する（`phase-recovery-spec.md` §8 のユーザー確認必須性ルールに従う）。保守的に「未完」扱いで黙って再実行する挙動は取らない
- [ ] `progress.md` のフラグと外部実態の不整合が検出された場合の具体的な巻き戻し手順（rollback）が Construction Phase の設計で扱われる旨が、技術的考慮事項として明記されている

**ステップファイル整合**:

- [ ] Operations Phase のステップファイル（`01-setup.md` / `03-release.md` / `04-completion.md`）で、7.8 以降の history 追記を誘導する記述が存在しない（既存 7.4 は正規タイミングとして維持）
- [ ] 「7.7 最終コミット時点で全判定ソースが確定している」ことがステップファイルまたは index.md に明記されている

**技術的考慮事項**:

- `progress.md` のサブステップ完了フラグは、ステップ 7.4〜7.6 の既存更新フロー内で書き込まれる（7.7 コミットに含まれる）
- 7.8 の PR Ready 化・7.13 の PR マージ自体の実行は引き続き必要。判定は「progress.md の予約フラグ」＋「GitHub 実態確認（`gh pr view` 等）」の AND で「完了」とする二段階方式
- GitHub 実態確認の実装詳細（`gh pr view` のどのフィールドを見るか、キャッシュの扱い、API 利用不可時のフォールバック）は Construction Phase の設計フェーズで明確化する
- 失敗時の rollback 詳細手順（progress.md フラグの再設定・後続 PR での明示的コミット等）は Construction Phase の設計フェーズで明確化する

---

### ストーリー 2: リモート同期チェックが squash 後の divergence を誤検知しない（#574）

**優先順位**: Must-have

As an AI-DLC ユーザー
I want to Construction Phase の squash 後に Operations Phase を開始しても、リモート同期チェックで不要な「取り込む / スキップ」選択が表示されないようにしたい
So that 誤って「取り込む」を選択して squash 前の状態に戻すリスクを回避でき、Operations Phase を滞りなく進められる

**受け入れ基準**:

**主AC - Operations 開始時の runtime 判定ロジック修正（#574 (1)(2)）**:

- [ ] `scripts/operations-release.sh` の `verify-git remote-sync` で、`git merge-base --is-ancestor @{u} HEAD` が true（リモートがローカルの祖先）なら `up-to-date` と判定する先行チェックが実装されている
- [ ] divergence 検出時（ローカル・リモートが共通祖先から分岐）には `diverged` ステータスを返し、`behind` と区別される
- [ ] `diverged` ステータス時のメッセージに `git push --force-with-lease <remote> <branch>` の推奨コマンドが含まれる
- [ ] 自動 push は行わない（ユーザー承認の明示的コマンド実行を要求する）
- [ ] `steps/operations/01-setup.md` のリモート同期チェック分岐で、`diverged` ステータスに対するユーザー選択フロー（force push 案内を表示 or スキップ）が追加されている

**回帰防止（既存ステータスの維持）**:

以下の判定表に従い、既存ステータスが壊れないことを保証する:

| 状況 | 期待ステータス | 判定条件 |
|------|---------------|---------|
| ローカルがリモートと同一 | `up-to-date` | `@{u}` と `HEAD` が同一コミット |
| リモートがローカルの祖先（squash 後等） | `up-to-date` | `git merge-base --is-ancestor @{u} HEAD` が true |
| ローカルがリモートの祖先（真の behind） | `behind` | `git merge-base --is-ancestor HEAD @{u}` が true |
| 共通祖先から分岐 | `diverged` | 上記いずれにも該当せず、共通祖先が存在 |
| リモート取得失敗 | `fetch-failed` | `git fetch` が非ゼロ終了 |

- [ ] 真に behind の場合は従来通り `behind` と判定される（実装前後で同じ挙動を示す）
- [ ] `fetch-failed`（オフライン等）は従来通り返される（判定ロジックが fetch 前に先行実行されない）

**派生AC - Construction 側の squash 完了後の案内追加（#574 (3)）**:

- [ ] `steps/construction/**` の squash 完了後のフローに、diverged が想定される場合のみ `git push --force-with-lease` 案内を表示する記述が追加されている
- [ ] 既に push 済みまたは squash 未実施の場合は案内を抑制する

**検証**:

- [ ] squash 後に Operations Phase を開始する手順で、誤検知が再現しないことを検証した記録（手動確認または自動テスト）が残る

**技術的考慮事項**:

- `git merge-base --is-ancestor A B` は A が B の祖先なら exit 0、そうでなければ exit 1。ステータス判定ロジックは exit code を含めて丁寧に扱う
- `force-with-lease` は `force` と異なり、リモートの現状を検査してから上書きするため、他者のコミットを壊すリスクを低減できる。案内文言でも `--force` ではなく `--force-with-lease` を推奨する

---

### ストーリー 3: CIチェック未設定リポジトリで merge-pr が安全にスキップできる（#575）

**優先順位**: Must-have

As an AI-DLC ユーザー（CIチェック未設定リポジトリの開発者）
I want to `operations-release.sh merge-pr --skip-checks` で CIチェックが `checks-status-unknown` と解釈される場合の中断をバイパスしたい
So that 個人開発や実験リポジトリでも AI-DLC Operations Phase を利用できる（ただし failed / pending の CI は従来通り拒否される）

**受け入れ基準**:

**主AC - `--skip-checks` オプション追加**:

- [ ] `scripts/operations-release.sh merge-pr` に `--skip-checks` オプションが追加されている
- [ ] CIチェック状態が `checks-status-unknown` と解釈される場合のみ `--skip-checks` でバイパス可能（内部実装は `gh pr checks` 出力の解釈に依存）
- [ ] CIチェック状態が `failed` / `pending` / その他既知状態の場合、`--skip-checks` を指定しても従来通りエラー終了する（安全性を損なわない）

**挙動マトリクス**:

| CI 状態 | `--skip-checks` なし | `--skip-checks` あり |
|---------|---------------------|---------------------|
| `passed`（成功） | マージ続行 | マージ続行（挙動変更なし） |
| `failed` | エラー終了 | エラー終了（バイパス不可） |
| `pending`（進行中） | エラー終了 | エラー終了（バイパス不可） |
| `checks-status-unknown`（未設定等） | エラー終了（案内付き） | マージ続行 |

**エラーメッセージ・ドキュメント**:

- [ ] CIチェック状態が `checks-status-unknown` と解釈されたケースでのエラーメッセージが「CIチェックが設定されていません。`--skip-checks` でスキップできます」のような、具体的な次アクションを案内している
- [ ] `merge-pr --help` またはスクリプト冒頭の Usage 情報に `--skip-checks` の説明と適用条件が追加されている
- [ ] `skills/aidlc/steps/operations/03-release.md` に `merge-pr` がCIチェック存在を前提とする旨と、`--skip-checks` の適用条件が記載されている
- [ ] `skills/aidlc/guides/` 配下に `merge-pr` の挙動サマリ（上記マトリクスを含む）が 1 箇所追加されている

**互換性**:

- [ ] 既存の呼び出し（`--skip-checks` を指定しないケース）のデフォルト挙動が変わらないこと（下位互換）

**技術的考慮事項**:

- CIチェック状態の `checks-status-unknown` 解釈は `gh pr checks` 出力パースで行う（現行実装の `no checks reported` 判定を参照）。出力文言の微細変化に耐える実装とする
- `--skip-checks` のフラグ実装は shell スクリプトの引数パース追加。`getopts` またはループ処理で対応
- guides 配下の新規ファイルのファイル名は Construction Phase で決定（例: `merge-pr-usage.md` など、既存ガイド命名規則に合わせる）
