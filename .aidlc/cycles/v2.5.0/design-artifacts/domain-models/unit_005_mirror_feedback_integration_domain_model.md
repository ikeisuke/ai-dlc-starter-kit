# ドメインモデル: Unit 005 mirror モードの /aidlc-feedback 連動

## 概要

`feedback_mode = mirror` 設定下で retrospective.md の skill_caused=true 項目を upstream Issue として起票するフローを表現するドメインモデル。Unit 004 の RetrospectiveAggregate を入力として、各 ProblemItem に「mirror フローでの処理状態」を機械可読キー（`mirror_state`）で記録し、`AskUserQuestion`（Step 文書側責務）の選択結果に応じて Issue 起票 / ローカル記録のみを実行する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成）で行う。

**Unit 004 ドメインモデルとの関係**: 本 Unit は Unit 004 が定義した `RetrospectiveDocument` / `ProblemItem` / `SkillCausedJudgment` / `CycleVersion` / `ConfigSchema` を**そのまま流用**し、新規エンティティとして `MirrorState` / `MirrorCandidate` / `IssueDraft` / `MirrorFlowResult` を追加する。スキーマ単一ソース原則は維持する。

## エンティティ（Entity）

### MirrorState

ProblemItem ごとに 1 件保持する mirror フローの処理状態エンティティ。retrospective.md の YAML フロントマター内 `mirror_state` ブロックとして永続化される。Unit 005 で新規追加するため、Unit 004 で生成された旧形式 retrospective.md には不在 → 後方互換ルールで `state=""` 同等扱いとする。

- **ID**: `(cycle, problem_index)`（ProblemItem に従属）
- **永続化属性**:
  - `state`: MirrorStateValue — `Sent` / `Skipped` / `Pending` / `Empty`（未処理）
  - `issue_url`: String — `Sent` 時に Issue URL を保持。それ以外は空文字
  - `recorded_at`: String — `Sent` / `Skipped` / `Pending` 確定時の ISO8601 タイムスタンプ。`Empty` 時は空文字
- **不変条件**:
  - `state == Sent` の場合、`issue_url.length > 0` かつ `^https://github\.com/.+/issues/[0-9]+$` フォーマット
  - `state == Skipped` または `state == Pending` の場合、`issue_url == ""`
  - `state != Empty` の場合、`recorded_at` は ISO8601 フォーマット（例: `2026-04-29T12:34:56Z`）
  - 後方互換: `mirror_state` ブロック自体が欠落している場合 → `state = Empty` と等価扱い（fatal 拒否禁止）
- **振る舞い**:
  - `is_processed()`: Boolean — `state != Empty` で true
  - `is_candidate()`: Boolean — `state == Empty` で true（detect の処理対象判定）
  - `to_yaml_block()`: String — YAML フロントマター用テキスト生成（送信時 / 記録時の書き込み用）

### MirrorCandidate

mirror フローで送信候補となる ProblemItem を表すエンティティ。`detect` サブコマンドが skill_caused=true ∧ `MirrorState.is_candidate() == true` の項目を抽出して構築する。一時的な実行時エンティティであり永続化しない。

- **ID**: `(cycle, problem_index)`
- **属性**:
  - `problem_item`: ProblemItem — Unit 004 のドメインオブジェクトを参照（同一性チェック）
  - `draft`: IssueDraft — 起票用 Issue 下書き
- **不変条件**:
  - `problem_item.skill_caused() == true`（派生値計算結果）
  - `problem_item` の MirrorState は `Empty`（処理済みは候補にならない）
  - 同一サイクル内で `problem_index` は一意
- **振る舞い**:
  - `to_tsv_line()`: String — detect 出力用 TSV 行（`mirror\tcandidate\t<idx>\t<title>\t<draft_path>`）
  - `is_legacy()`: Boolean — 入力 retrospective.md が mirror_state ブロック未保持なら true（後方互換フラグ）

### IssueDraft

upstream Issue 用の Markdown スニペット下書きを表すエンティティ。`detect` サブコマンドが ProblemItem から生成し、一時ファイル（`/tmp/retrospective-mirror-draft.<idx>.<random>.md`）に書き出す。

- **ID**: `(cycle, problem_index)`
- **属性**:
  - `title`: String — Issue タイトル（ProblemItem.title をそのまま使用、最大 100 文字に切り詰める）
  - `body_markdown`: String — Markdown 本文（検出元 / 問題タイトル / 何が起きたか / なぜ起きたか / skill 内引用箇所 / 損失と影響）
  - `body_path`: FilePath — 一時ファイル絶対パス
  - `mirror_reason_tag`: String — `[mirror-reason] cycle=<v>; problem_index=<N>` 機械可読タグ（本文先頭に挿入）
- **不変条件**:
  - `title.length > 0` かつ `<= 100`
  - `body_markdown` は検出元タグ + 問題本文 + 引用箇所 + 損失影響を必ず含む
  - `body_path` は絶対パスかつ `/tmp/` または `${TMPDIR:-/tmp}/` 配下
- **振る舞い**:
  - `serialize()`: void — body_markdown を body_path へ書き出す
  - `to_gh_args()`: List<String> — `gh issue create` 用引数列（`--title <title> --body-file <body_path>`）

### MirrorFlowResult

mirror フロー全体の実行結果サマリ。Step 5 が複数 candidate 処理後にユーザーへ提示する。一時的なエンティティ。

- **ID**: `(cycle, run_started_at)`
- **属性**:
  - `total_candidates`: Integer — detect で検出された候補数
  - `sent_count`: Integer — 起票成功数
  - `skipped_count`: Integer — 「送信しない」選択数
  - `pending_count`: Integer — 「保留」選択数
  - `send_failed_count`: Integer — recoverable failure 数
  - `fatal_aborted`: Boolean — fatal 失敗で中断したかどうか
- **不変条件**:
  - `total_candidates == sent_count + skipped_count + pending_count + send_failed_count + (中断時の未処理数)`
  - 全カウントは非負整数
- **振る舞い**:
  - `to_summary_line()`: String — `summary\tmirror-flow\tsent=N;skipped=M;pending=K;send-failed=L`

## 値オブジェクト（Value Object）

### MirrorStateValue

mirror フローの処理状態を表す列挙型。

- **値**:
  - `Empty` — 未処理（`state = ""` または mirror_state ブロック欠落）
  - `Sent` — Issue 起票成功（`state = "sent"`）
  - `Skipped` — ユーザーが「送信しない」選択（`state = "skipped"`）
  - `Pending` — ユーザーが「保留」選択（`state = "pending"`）
- **不変条件**:
  - YAML リテラル `""` / `"sent"` / `"skipped"` / `"pending"` のみ受け付ける
  - 不正値（`"on"` / `"off"` / `null` 等）は警告ログ出力後 `Empty` 同等扱いにフォールバック
- **振る舞い**:
  - `from_string(s: String)`: MirrorStateValue — 文字列からの安全構築
  - `is_terminal()`: Boolean — `Sent` で true（最終確定状態）
  - `is_revisable()`: Boolean — `Pending` で true（次サイクルで再提示可能）

### UpstreamRepo

Issue 送信先 owner/repo を表す不変値オブジェクト。`defaults.toml` の `[rules.feedback] upstream_repo` を 4 階層マージで解決する。

- **属性**:
  - `value`: String — `^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$` フォーマット文字列（`/` がちょうど 1 個）
- **不変条件**:
  - フォーマット違反時は警告 + デフォルト値（`ikeisuke/ai-dlc-starter-kit`）にフォールバック
  - 正規表現は `/` を 1 個に固定する（`a/b/c` のような複数スラッシュは reject）
  - owner / repo 部分はそれぞれ `[A-Za-z0-9._-]+` を満たす（GitHub の命名制約と整合）
- **振る舞い**:
  - `to_gh_arg()`: String — `gh issue create --repo <value>` 引数として使用
  - `from_config(raw: String)`: UpstreamRepo — フォーマット検証 + フォールバック構築（不正値は warn + default、`/` 個数違反も同様）

### MirrorReason

Issue 本文先頭に注入する機械可読タグ。Issue 受領側で経路識別するためのラベル。

- **属性**:
  - `cycle`: CycleVersion — Unit 004 の値オブジェクトを参照
  - `problem_index`: Integer — 1 始まり整数
- **振る舞い**:
  - `to_string()`: String — `[mirror-reason] cycle=<v>; problem_index=<N>` フォーマット
  - `parse(s: String)`: MirrorReason — Issue 本文から逆抽出（v2.6.x で送信先側集計時に使用予定）

### SendFailureReason

`send` サブコマンドの recoverable failure 理由を表す列挙型。fatal 失敗との 2 系統分離（DR-006）の片側を担う。

- **値**:
  - `GhNotInstalled` — gh CLI 未インストール（`command -v gh` 失敗）
  - `GhNotAuthenticated` — `gh auth status` 失敗
  - `GhRateLimit` — gh CLI 戻り値で rate limit を検出
  - `GhNetworkError` — タイムアウト / DNS エラー
  - `GhUnknownError` — 上記いずれにも該当しない gh エラー
- **不変条件**:
  - 上記 5 値以外は `GhUnknownError` へ正規化
  - 本列挙のいずれも recoverable（exit 0 + `mirror\tsend-failed`）。fatal は別の `FatalErrorCode` で表現
  - 列挙値は `retrospective-schema.yml` の `send_failure_reasons` と完全同期する単一ソース契約
- **振る舞い**:
  - `to_payload()`: String — TSV 出力用文字列（`gh-not-installed` / `gh-not-authenticated` 等）

### UserDecision

Step 5 が `AskUserQuestion` で取得する選択結果を表す列挙型。

- **値**:
  - `Send` — 「送信する」
  - `Skip` — 「送信しない」
  - `Pending` — 「後で判断（保留）」
- **不変条件**: 上記 3 値のみ。`AskUserQuestion` の選択肢ラベルと 1:1 対応
- **振る舞い**:
  - `to_subcommand()`: String — Send → `send`, Skip → `record skipped`, Pending → `record pending` のマッピング
  - `to_state_value()`: MirrorStateValue — Send → Sent, Skip → Skipped, Pending → Pending

## ドメインサービス（Domain Service）

### MirrorCandidateDetector

retrospective.md から MirrorCandidate を抽出するドメインサービス。`detect` サブコマンドのドメインロジック本体。

- **責務**:
  - `read-config.sh rules.retrospective.feedback_mode` で値を解決し、`mirror` 以外なら `mirror\tskip\tnot-mirror-mode` を出力して終了（**feedback_mode 解決は本サービスに一本化**、Step は呼び出さない）
  - retrospective.md を `RetrospectiveValidator.extract` 経路で再走査し、各 ProblemItem の `SkillCausedJudgment` を派生値として再計算
  - skill_caused=true かつ `MirrorState.is_candidate() == true` の項目を抽出
  - 各候補に対して `IssueDraft` を生成して一時ファイルに serialize
  - mirror_state ブロック欠落時は `state=Empty` 扱い（後方互換ルール）
- **責務外**:
  - YAML 検証 / ダウングレード（Unit 004 RetrospectiveValidator が担当 / 本フローは validate --apply 後の結果を入力前提）
  - Issue 起票（後段 IssueSender が担当）
  - AskUserQuestion 提示（Step 文書側責務）
- **実装契約**: `skills/aidlc/scripts/retrospective-mirror.sh detect <retrospective.md>`

### IssueSender

upstream Issue を起票し、retrospective.md の `mirror_state` を更新するドメインサービス。`send` サブコマンドのドメインロジック本体。

- **責務**:
  - `gh auth status` 事前チェック → 失敗時は `mirror\tsend-failed\t<idx>\tgh-not-authenticated` を出力して exit 0（recoverable）
  - `UpstreamRepo` を `read-config.sh rules.feedback.upstream_repo` から解決
  - `gh issue create --repo <upstream_repo> --title <title> --body-file <body_path>` を実行
  - `gh` の終了コード / stderr を `SendFailureReason` 列挙にマッピング（rate-limit / network / unknown）
  - 採番 Issue URL を取得し、retrospective.md の該当 ProblemItem の `mirror_state` を `Sent` + `issue_url` + `recorded_at` で更新
  - 書き込みは `_safe_transform` 相当（backup → tmp → mv → rollback）
  - retrospective.md 書き込み失敗 → exit 2 + `error\tapply-failed\trollback-completed`（fatal）
- **実装契約**: `skills/aidlc/scripts/retrospective-mirror.sh send <retrospective.md> <problem_index> <title> <draft_body_path>`

### MirrorDecisionRecorder

ユーザーが「送信しない」/「保留」を選択した場合に retrospective.md の `mirror_state` を更新するドメインサービス。`record` サブコマンドのドメインロジック本体。

- **責務**:
  - `decision ∈ {skipped, pending}` のバリデーション（不正値は exit 2）
  - retrospective.md の該当 ProblemItem の `mirror_state.state` を `Skipped` または `Pending` に書き込み
  - `mirror_state.recorded_at` を ISO8601 で書き込み
  - `mirror_state.issue_url` は空文字を保持
  - 書き込みは `_safe_transform` 相当
  - 後方互換: mirror_state ブロック欠落の旧形式 retrospective.md には新規ブロックを追加
- **実装契約**: `skills/aidlc/scripts/retrospective-mirror.sh record <retrospective.md> <problem_index> <decision>`

### MirrorStateRepository

retrospective.md の YAML フロントマター内 `mirror_state` ブロックの読み書きを担う擬似リポジトリ。実装は dasel + bash `_safe_transform` パターンの組み合わせ。

- **責務**:
  - `find(retrospective_path, problem_index)`: MirrorState — 指定 problem_index の mirror_state を読み出し（欠落時は `Empty` を返す）
  - `save(retrospective_path, problem_index, state)`: void — backup → tmp → mv のトランザクション書き込み
  - `add_block_if_missing(retrospective_path, problem_index)`: void — mirror_state ブロック欠落時の新規追加（後方互換対応）
- **実装非対象**: 概念定義のみ。実装は `IssueSender` / `MirrorDecisionRecorder` 内の helper 関数として封じ込める

## 集約（Aggregate）

### MirrorFlowAggregate

単一サイクルの mirror フロー全体を凝集する集約。Unit 004 の `RetrospectiveAggregate` とは**完全に独立した別境界**で、専用ルート `MirrorFlowContext` を持ち、Unit 004 のドメインオブジェクトは外部参照（snapshot ID 参照のみ）として扱う。これによりクロス集約更新を排除し、永続化責務を `MirrorStateRepository` に一本化する。

- **集約ルート**: `MirrorFlowContext`（Unit 005 専用 / cycle をキーとする実行時ルート）
- **メンバー**:
  - `MirrorFlowContext`（集約ルート / 1 サイクルにつき 1 件）
  - `MirrorState`（problem_index と 1:1 / cycle に従属）
  - `MirrorCandidate`（実行時 / 永続化しない）
  - `IssueDraft`（実行時 / 一時ファイルに serialize）
  - `MirrorFlowResult`（実行時集計）
- **不変条件**:
  - `MirrorFlowContext` は単一の cycle に紐付く（複数 cycle 跨ぎ禁止）
  - `MirrorState` は対応する `MirrorFlowContext.cycle` と `problem_index` で一意
  - `MirrorCandidate` の構築には `RetrospectiveDocument.snapshot_ref(cycle, problem_index)` を経由（直接 RetrospectiveDocument を参照しない）
  - `MirrorState.state` 書き換えは `MirrorStateRepository.save` のみが行う（`IssueSender` / `MirrorDecisionRecorder` も同リポジトリ経由）
- **境界責務の明文化**:
  - **本集約が所有するもの**: `mirror_state` ブロックの永続化と整合性（書き込み権限を独占）
  - **外部から参照のみ行うもの**: `RetrospectiveDocument` / `ProblemItem` / `SkillCausedJudgment`（Unit 004 集約の所有物 / snapshot ID 経由で読み取り専用アクセス）
  - **書き込み経路の単一化**: `IssueSender.send` / `MirrorDecisionRecorder.record` は `MirrorStateRepository.save` のみを呼び出し、`RetrospectiveDocument` の他フィールド（problems / skill_caused_judgment 等）には触らない
- **クロス集約参照ルール**:
  - Unit 004 `RetrospectiveAggregate` への参照は **snapshot ID（cycle + problem_index）** のみ
  - Unit 004 集約の他属性（problems / skill_caused_judgment）への変更権限を Unit 005 集約は持たない
  - Unit 005 集約は `mirror_state` ブロックのみを書き換える（同じ retrospective.md ファイル内であっても他キーには触らない）
- **集約境界外との関係**:
  - Unit 004 `RetrospectiveAggregate`: snapshot ID 参照のみ（read-only）
  - Unit 005 が拡張する `retrospective-schema.yml` の `mirror_state` セクションを ConfigSchema として参照
  - `defaults.toml` の `[rules.feedback] upstream_repo` を read-only で参照（4 階層マージ経由）
  - Unit 006 集約への引き継ぎ点: `MirrorCandidateDetector` の出力 TSV を入力として、Unit 006 が重複統合 + 上限ガードを差し込む

### MirrorFlowContext

mirror フロー実行のスコープを表す集約ルート（実行時エンティティ）。単一サイクルの単一実行に対応する識別子を持つ。

- **ID**: `(cycle, run_started_at)`
- **属性**:
  - `cycle`: CycleVersion — Unit 004 の値オブジェクト
  - `run_started_at`: String — ISO8601 タイムスタンプ
  - `retrospective_path`: FilePath — 操作対象 retrospective.md の絶対パス
  - `upstream_repo`: UpstreamRepo — 解決済み送信先
- **不変条件**:
  - 同一 cycle 内で並行起動した場合でも `run_started_at` で個別識別される（Unit 006 の重複検出はサイクル単位 / 実行単位ではない）
  - `retrospective_path` は `.aidlc/cycles/<cycle>/operations/retrospective.md` パターンに一致
- **振る舞い**:
  - `snapshot_ref(problem_index: Integer)`: SnapshotReference — Unit 004 集約への read-only 参照を返す（書き込み権限なし）

### SnapshotReference

Unit 004 集約への read-only 参照を表す値オブジェクト。Unit 005 集約から Unit 004 のデータを参照する唯一の窓口。

- **属性**:
  - `cycle`: CycleVersion
  - `problem_index`: Integer
- **不変条件**:
  - 構築後は cycle と problem_index を変更できない
  - 本オブジェクトを通じて Unit 004 集約の永続化属性を変更できない（コンパイル時保証）
- **振る舞い**:
  - `read_problem_item()`: ProblemItem — Unit 004 集約から read-only 取得
  - `read_skill_caused()`: Boolean — 派生値計算結果を取得

## リポジトリインターフェース

### UpstreamRepoConfigRepository（概念）

- **責務**: `defaults.toml` の `[rules.feedback] upstream_repo` を 4 階層マージで読み出す
- **インターフェース**:
  - `load()`: UpstreamRepo（不正値時はデフォルトフォールバック）

### IssueDraftRepository（概念）

- **責務**: `IssueDraft.body_path` 配下の一時ファイル管理（書き込み / 削除）
- **インターフェース**:
  - `serialize(draft: IssueDraft)`: void — body_markdown を一時ファイルへ書き出し
  - `cleanup(draft: IssueDraft)`: void — フロー完了時に削除（fatal 中断時は残存させてユーザーが手動で送信可能）

### IssueRemoteRepository（概念）

- **責務**: `gh issue create` を経由した upstream Issue の作成
- **インターフェース**:
  - `create(repo: UpstreamRepo, draft: IssueDraft)`: Result<String, SendFailureReason> — 成功時は Issue URL、失敗時は recoverable reason

## ドメインルール（Business Rules）

### Rule 1: feedback_mode ガード

- `feedback_mode != "mirror"`（`silent` / `disabled` / 不正値）の場合、mirror フロー全体をスキップ（detect が `mirror\tskip\tnot-mirror-mode` を 1 行出力して終了）
- `feedback_mode` 解決は detect サブコマンド一元責務（Step 文書側で `read-config.sh` を呼ばない）

### Rule 2: 候補抽出ルール

- 候補条件: ProblemItem.skill_caused() == true ∧ MirrorState.is_candidate() == true（state=Empty）
- skill_caused は派生値（Unit 004 のスキーマ単一ソース原則 / 6 キーから都度計算）
- Unit 004 と同一の派生値計算を使用（共通ヘルパー切り出し可否は Phase 2 設計時に再評価）

### Rule 3: 送信契約（recoverable / fatal の 2 系統）

- `Sent` 確定: gh issue create 成功 + retrospective.md 書き込み成功 → `mirror\tsent\t<idx>\t<url>` + exit 0
- `Recoverable failure`: gh エラー（auth / rate-limit / network / unknown）→ `mirror\tsend-failed\t<idx>\t<reason>` + exit 0（次の候補へ続行）
- `Fatal failure`: retrospective.md 書き込み失敗 / schema 不在 / dasel 不在 / 引数不正 → `error\t<code>\t<payload>` + exit 2（フロー全体停止）

### Rule 4: ユーザー決定 → 状態遷移

| UserDecision | サブコマンド | MirrorState.state |
|--------------|-------------|--------------------|
| Send | send | Sent（または Empty 維持 + send-failed） |
| Skip | record skipped | Skipped |
| Pending | record pending | Pending |

### Rule 5: 後方互換（mirror_state 欠落時）

- 旧形式 retrospective.md（Unit 004 で生成 / mirror_state ブロックなし）→ `state = Empty` と等価扱い、fatal 拒否禁止
- 書き込み時に欠落していた mirror_state ブロックを新規追加（`MirrorStateRepository.add_block_if_missing`）

### Rule 6: 単一ソース原則の維持

- 検証ルール / state 列挙 / mirror_state キー定義は `retrospective-schema.yml` に集約（Unit 004 から拡張）
- Markdown 文言ベースの「処理済み判定」は禁止（Codex Round 1 指摘 #4 / Round 2 指摘 #1）
- 送信先 owner/repo は `defaults.toml` の `[rules.feedback] upstream_repo` を単一ソースとし、ハードコード禁止

### Rule 7: マージ前完結契約との整合（Unit 004 から継承）

- mirror フローの retrospective.md 書き込みは Operations Phase の **5. PR マージ後の手順より前**で完結
- マージ後に呼び出した場合は `write-history.sh` の exit 3 ガード相当で拒否される（同契約に従う）

## 用語集

| 用語 | 定義 |
|------|------|
| mirror フロー | feedback_mode=mirror 時に skill_caused=true 項目を upstream Issue として下書き → 承認 → 起票するフロー |
| candidate | mirror フローで送信対象となる ProblemItem（state=Empty かつ skill_caused=true）|
| recoverable failure | 個別 candidate 単位の失敗で、フロー全体を止めない（exit 0 + send-failed）|
| fatal failure | フロー継続不能な失敗（exit 2 + error）|
| upstream_repo | Issue 送信先 owner/repo（defaults.toml の単一ソース）|
| mirror_state | retrospective.md の YAML フロントマター内に追加される処理状態ブロック（state / issue_url / recorded_at）|
| 後方互換ルール | Unit 004 で生成された旧形式 retrospective.md（mirror_state 欠落）を Empty 扱いとして処理する規約 |

## 派生値原則（Unit 004 から継承）

- `skill_caused` は永続化せず 6 キーから都度計算する原則を維持（Unit 005 でも同等）
- `mirror_state.state` は永続化する契約値（Unit 004 の派生値原則の対象外）
- `MirrorState.is_processed()` / `MirrorState.is_candidate()` は派生値（state から都度計算）
