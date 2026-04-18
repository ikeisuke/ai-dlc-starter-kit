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

---

### ストーリー 4: setup 直後から ai_author 自動検出が機能する（#577）

**優先順位**: Must-have

As an AI-DLC ユーザー（複数 AI ツールを併用する開発者）
I want to `setup` 直後の `config.toml` で `ai_author` が空文字（`""`）になっていることで、`commit-flow.md` の自動検出フロー（自己認識 → 環境変数 → ユーザー確認）が起動してほしい
So that Claude Code / Codex CLI / Cursor / Kiro 等を使い分けても Co-Authored-By が実作業者に基づいて正しく付与される

**受け入れ基準**:

**主AC - テンプレート・サンプル修正**:

- [ ] `skills/aidlc-setup/templates/config.toml.template` の `ai_author` が `""` になっている
- [ ] 同ファイルのコメント行が「空なら自動検出」と整合している（例: `# - デフォルト: ""（空なら自動検出）`）
- [ ] `skills/aidlc/config/config.toml.example` の `ai_author` のサンプル値・コメントが新既定と整合している（コメントアウトまたは空文字サンプル）

**動作確認**:

- [ ] 新規プロジェクトで `aidlc setup` を実行した結果、`config.toml` の `ai_author` が空のままとなる
- [ ] 続いて Construction Phase でコミットした際、`commit-flow.md` の自動検出フローが実行され、作業者（Claude Code / Codex / Cursor 等）に応じた Co-Authored-By が付与される
- [ ] 手動で `ai_author = "Claude <noreply@anthropic.com>"` のように明示設定した場合は従来通りその値が優先される（設定優先は自動検出より上）

**挙動マトリクス（`ai_author` × `ai_author_auto_detect` の組み合わせ）**:

| `ai_author` | `ai_author_auto_detect` | 挙動 |
|-------------|------------------------|------|
| 空文字 `""` | `true`（デフォルト） | 自動検出フロー起動: 自己認識 → 環境変数 → ユーザー確認。成功値が Co-Authored-By に使用される |
| 空文字 `""` | `false` | 自動検出を抑止。Co-Authored-By なしでコミットする（従来通り `commit-flow.md` の指定に従う） |
| 明示値（例: `"Claude <...>"`） | 任意 | 明示値を優先使用。自動検出は実行されない |

- [ ] 上記 3 パターンで `commit-flow.md` の挙動が一貫していることを目視確認
- [ ] 自動検出フローの「自己認識失敗時はユーザー確認へ進む」挙動（`commit-flow.md` 既存仕様）が維持されている
- [ ] 自動検出失敗かつユーザー確認も拒否された場合、Co-Authored-By なしでコミットを続行する（従来仕様と整合）

**後方互換**:

- [ ] 既存プロジェクトの `.aidlc/config.toml`（実ファイル）には変更を加えない
- [ ] 既存のデフォルト設定 `skills/aidlc/config/defaults.toml` / `skills/aidlc-setup/config/defaults.toml` の `ai_author = ""` と整合している（これらは既に空のため変更不要）
- [ ] `ai_author_auto_detect` 既定値 `true`（`defaults.toml`）は本ストーリーで変更しない

**ドキュメント整合**:

- [ ] `skills/aidlc/guides/config-merge.md` や `commit-flow.md` 等の ai_author 言及箇所で、空文字既定と自動検出フローの関係が矛盾していないことを目視確認

**技術的考慮事項**:

- 本修正は**テンプレート・サンプルのみ**の変更。スクリプト側（`migrate-config.sh` 等）の既定値は既に `""` のため追加変更不要
- setup 直後の動作を目視確認する手段として、新規プロジェクトを `/tmp` 等に作成して確認する手順を Construction Phase で整備する
- 旧既定値（`"Claude <noreply@anthropic.com>"`）で setup 済みのプロジェクトは、ユーザーが手動で `""` に書き換えることで自動検出フローに切り替え可能。本ストーリーは自動マイグレーションを含まない

---

### ストーリー 5: 設定保存フローで意図しない暗黙書き込みが発生しない（#578）

**優先順位**: Must-have

As an AI-DLC ユーザー（`automation_mode=semi_auto` 利用者を含む）
I want to 3 箇所の設定保存フロー（`branch_mode` / `draft_pr` / `merge_method`）で「保存しますか？」の選択が常に `AskUserQuestion` で提示され、デフォルトが「いいえ（今回のみ使用）」になっていてほしい
So that `config.local.toml` に個人設定が暗黙的に書き込まれず、意図した場合のみ保存される

**受け入れ基準**:

**主AC - 分類のユーザー選択明示**:

- [ ] `skills/aidlc/SKILL.md`（または同等のドキュメント）の「AskUserQuestion 使用ルール」で、以下 3 場面が「ユーザー選択」種別として明記されている
  - `rules.git.branch_mode` の保存（`steps/inception/01-setup.md`）
  - `rules.git.draft_pr` の保存（`steps/inception/05-completion.md`）
  - `rules.git.merge_method` の保存（`steps/operations/operations-release.md`）
- [ ] 「ユーザー選択」種別は `automation_mode=semi_auto` でも常に `AskUserQuestion` 必須（ゲート承認ではない）と明記されている

**主AC - デフォルト選択肢変更**:

- [ ] 上記 3 ファイルの設定保存フローで `AskUserQuestion` の選択肢順が `[ "いいえ（今回のみ使用）", "はい（保存する）" ]` の順（先頭が Recommended）になっている
- [ ] 「いいえ（今回のみ使用）」にラベル `(Recommended)` を付与、または Option の `description` で推奨として明示されている

**主AC - 3 ファイルの統一フォーマット**:

- [ ] 3 ファイルで質問文・選択肢順序・保存先既定の説明が共通化されている（テキストレベルの完全一致までは求めないが、同一のユーザー体験となる記述）
- [ ] 「保存する場合の既定保存先」（`config.local.toml` など）の説明が統一されている

**挙動マトリクス**:

| automation_mode | 従来挙動 | 新挙動 |
|----------------|---------|--------|
| `manual` | `AskUserQuestion`、「はい」または「いいえ」（順序不定） | `AskUserQuestion`、「いいえ（今回のみ）」 Recommended 先頭 |
| `semi_auto` | ゲート承認扱いで自動承認される場合あり | 常に `AskUserQuestion` 必須、自動承認されない |
| `full_auto` | 自動承認 | 「ユーザー選択」種別のため自動承認せず、`AskUserQuestion` 必須 |

**後方互換**:

- [ ] 既存の `.aidlc/config.local.toml` には変更を加えない（読み取りは従来通り）
- [ ] 「はい（保存する）」を選択した場合の書き込み動作は変更なし（既存 `write-config.sh` 等のロジックに変化なし）

**検証**:

- [ ] 各 `automation_mode`（manual / semi_auto / full_auto）で 3 場面をテストし、`AskUserQuestion` が必ず表示されることを目視確認
- [ ] デフォルト Enter 相当で確定した場合、「いいえ（今回のみ使用）」が選ばれ `config.local.toml` に書き込まれないことを検証

**技術的考慮事項**:

- `write-config.sh` 自体の挙動変更は不要（呼び出し側のユーザー選択ロジックを修正するのみ）
- ストーリー 4（#577）と直交: ストーリー 4 は既定値の変更、本ストーリーは保存フローの UX 修正
- SKILL.md「AskUserQuestion 使用ルール」の更新は 3 ファイルの記述と同期して行う（片方だけの更新は整合性違反）

---

### ストーリー 6: suggest-permissions Review で既知安全な指摘が抑制される（#576）

**優先順位**: Should-have

As an AI-DLC ユーザー（定期的に suggest-permissions Review を実行する開発者）
I want to `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` に登録した指摘が Review 出力でデフォルトで非表示になり、末尾に集約サマリで抑制件数だけ見えてほしい
So that 毎回同じ既知安全な指摘を手動判定する負担が解消され、本当に新しい指摘への注意力を確保できる

**受け入れ基準**:

**主AC - 抑制リスト仕様**:

- [ ] `.claude/settings.json` の `suggestPermissions.acknowledgedFindings` フィールドが配列として読み込まれる
- [ ] 配列の各エントリは `{ pattern, severity, note, acknowledgedAt }` の構造を持つ
  - `pattern`: string（マッチング対象のパターン、マッチング方式は Construction Phase 設計で確定）
  - `severity`: string（対象 severity: `CRITICAL` / `HIGH` / `MEDIUM` / `LOW` / `INFO`）
  - `note`: string（承認理由のメモ、任意）
  - `acknowledgedAt`: string（ISO 8601 日時、任意）
- [ ] `.claude/settings.json` が存在しない、またはフィールドが未定義の場合、抑制機能は無効（従来通りの出力）
- [ ] `.claude/settings.json` 自体の新規作成は本機能の責務外（既存ファイルへのフィールド追加を読み取るのみ）

**マッチング条件（Intent 時点で固定する境界）**:

- [ ] 指摘のマッチングは `pattern` と `severity` の **AND 条件**で判定する（pattern が一致しても severity が異なれば抑制対象外）
- [ ] `pattern` は Review 出力の「指摘対象文字列」（例: `Bash(bash -n *)`）と照合する。照合対象の具体項目（コマンド文字列・表示ラベル・正規化前/後の文字列）の最終選定は Construction Phase 設計で確定
- [ ] `severity` は大文字小文字を区別せず比較する（`CRITICAL` / `critical` のいずれでも一致）
- [ ] `pattern` 文字列は前後空白をトリムして比較する（`" Bash(bash -n *) "` と `"Bash(bash -n *)"` は一致）
- [ ] `pattern` のマッチング方式（完全一致 / glob / 正規表現）は Construction Phase 設計フェーズで確定する論点として残す（Intent 境界と同期）

**異常系（設定ファイル破損時の失敗モード、本ストーリーで確定）**:

- [ ] `.claude/settings.json` が存在するが JSON パース失敗の場合、**警告を 1 行表示して suppression 機能を無効化**し、Review は従来通り全件表示・従来通りの終了コードで続行する
  - 警告例: `⚠ .claude/settings.json のパースに失敗しました。acknowledged findings 抑制は無効化されました。`
- [ ] `suggestPermissions.acknowledgedFindings` が配列でない場合、警告表示し suppression 機能を無効化して続行（同上）
- [ ] 配列要素の `severity` が既知値（`CRITICAL` / `HIGH` / `MEDIUM` / `LOW` / `INFO`、大文字小文字不問）以外の場合、**該当エントリのみスキップ**し残りのエントリで suppression を続行（部分失敗）
- [ ] 配列要素の `pattern` が欠落または空文字の場合、該当エントリのみスキップ
- [ ] `note` / `acknowledgedAt` の欠落・型不正は警告なしで許容（任意項目のため）
- [ ] 上記すべての異常ケースで Review モードの終了コードは従来通り保たれる（後方互換優先）

**主AC - デフォルト表示モード（非表示＋集約サマリ）**:

- [ ] `suggest-permissions --review` 実行時、`acknowledgedFindings` にマッチする指摘は詳細出力から除外される
- [ ] Review 出力末尾に `ℹ N件の既知指摘を抑制しました（詳細は --show-suppressed）` の 1 行サマリが表示される
- [ ] N=0（抑制対象なし）の場合、集約サマリは表示されない
- [ ] 抑制対象外の新規指摘は従来通り詳細表示される

**主AC - `--show-suppressed` 再表示**:

- [ ] `suggest-permissions --review --show-suppressed` 実行時、抑制対象の指摘も含めて全件を詳細表示する
- [ ] 抑制対象の指摘行には `(suppressed)` などの可視マーカーを付与する

**挙動マトリクス**:

| 抑制リスト状態 | `--show-suppressed` なし | `--show-suppressed` あり |
|---------------|------------------------|------------------------|
| 未設定・空配列 | 従来通り全件表示、集約サマリなし | 同左（挙動差なし） |
| 抑制対象あり（N 件マッチ） | 非マッチ指摘のみ表示 + 末尾に集約サマリ 1 行 | 全件表示（抑制対象に `(suppressed)` マーカー） |

**後方互換**:

- [ ] 既存の suggest-permissions Review モードの主要出力・終了コード・ユーザー入力プロンプトは維持
- [ ] 抑制設定を行わないユーザーにとって挙動変化なし

**検証**:

- [ ] Issue 本文で例示されている指摘（`Bash(bash -n *)` CRITICAL / `Bash(rm /tmp/aidlc-*)` HIGH）を `acknowledgedFindings` に追加し、Review 実行で非表示化されることを確認
- [ ] `--show-suppressed` で同指摘が再表示されることを確認
- [ ] `.claude/settings.json` 不在環境で Review を実行し、従来通りの出力となることを確認

**技術的考慮事項**:

- 読み込み対象の `.claude/settings.json` のパス解決は Claude Code の既定パス解決に従う（プロジェクトルート直下）
- マッチング方式（完全一致 / glob / 正規表現）の最終選定は Construction Phase 設計フェーズ
- JSON パースは既存の Claude Code 周辺ツールチェーンで標準的に使われているライブラリ（jq 等）を利用
- 抑制リストの記述例を `guides/` 配下に追加するかは Construction Phase で判断（新規ガイド or 既存ガイド追記）
- 本機能は suggest-permissions の Review モード**のみ**に影響。Setup モード等には影響しない
