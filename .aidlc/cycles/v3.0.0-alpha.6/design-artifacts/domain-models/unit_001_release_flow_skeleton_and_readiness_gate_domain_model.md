# ドメインモデル: Unit 001 release フロー骨格 + リリース準備ゲート

## 概要

release フェーズ Step 1「リリース準備」の概念モデルを定義する。全 work item の完了状態・state 前提・worktree 状態・test/CI 状態を入力に、release を継続してよいか（continue / stop / warn）を判定する**リリース準備ゲート**の構造と責務を示す。本 Unit は `steps/release.md` の骨格作成と Step 1 実装に限定し、Step 2–4（PR 整備・merge・post-merge）は骨格（プレースホルダ）のみとする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。release.md は実行手順（Markdown）であり、本モデルは手順が表現すべき判定ロジックの概念モデルである。

## ステップ0: 事前コード読込み（設計起草前の既存実装把握）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|-----------|
| `skills/aidlc-v3/steps/define.md` | Step + ゲート(★) + 成果物 + スクリプト契約の記述書式・パス解決セクションの書式を把握 |
| `skills/aidlc-v3/steps/develop.md` | Step 0「前提確認（clean-worktree + cycle 解決）」の書式・「完了後のフェーズ導出」セクションの書式・mutation なし停止パターンの表現を把握（release.md の最も近いお手本） |
| `skills/aidlc-v3/steps/status.md` | フェーズ導出の読み取り専用表示パターンを把握（release Step 1 の状態確認の参考） |
| `skills/aidlc-v3/scripts/state-read.sh` | `current_cycle` / `define_completed` / `release.*` の読取 usage・exit code 契約（0/1/2）を把握 |
| `skills/aidlc-v3/scripts/work-item-validate.sh` | work item frontmatter 検証の usage（`<dir> [expected_status]`）・exit code・検証項目を把握（release 準備の完了検出に read-only で利用可能か判断） |
| `docs/v3/workflow.md` §3.3 / §6 | release フェーズ Step 1–4 の規定・review perspective（骨格表記用）を把握（SoT） |
| `docs/v3/data-model.md` §3 / §5 / §8 | state.json schema（`release.*`）・フェーズ導出規則（§5.1 評価順）・review 集約方針を把握（SoT） |

### (b) 設計時に意識すべき挙動

- **`state-read.sh` の exit 契約**: `current_cycle` 不在（state.json 不在 / キー欠落）は exit 1、jq 不在・読取不可は exit 2、値ありは exit 0。release Step 1 は exit 1 を「active cycle なし → define/develop 案内」に、exit 2 を「システムエラー停止」に写像する（develop.md Step 0 と同一の写像）。
- **`work-item-validate.sh` は status 一覧を返さない**: 出力は `status:valid` か検証エラー（exit 1）のみで、どの item がどの status かは返さない。「未完了 work item を一覧提示」するには、frontmatter の status を別途走査する必要がある。検証スクリプトはあくまで schema 妥当性（read-only）の確認に使える。
- **完了の定義は `done` / `withdrawn` の 2 値**（data-model §5.1 評価順 4）。`blocked` は未完了であり、`done` または `withdrawn` に解決してから release する（workflow §3.3）。
- **`next:none` を release 可能の根拠にしない**（develop.md の注記）。release 可能判定は必ず全 work item frontmatter status の走査で行う。
- **release Step 1 の read-only スコープ**: ゲート評価は aidlc 管理状態（state.json / work item frontmatter / journal / commit）を変更しない（mutation なし / stop でも副作用を残さない）。ただし test 実行はキャッシュ・生成物で worktree を dirty にし得るため、`read-only` は「aidlc 管理状態を変更しない」意味に限定し、test 実行後に worktree dirty を再評価する（後述 GateDecisionService 評価順 / 設計レビュー R1 #1）。
- **test/CI 確認の対象は「リリース対象プロジェクト」のテスト/CI** であり、v3 フレームワーク自身の `scripts/tests/` ではない。release.md は consumer 向け手順なので、test 入口は「プロジェクトで定義されたテスト」と汎用表現する（ドッグフーディング特殊処理を埋め込まない）。
- **status 読取は安全境界スクリプトに委譲**: 各 work item の status 読取は既存 `scripts/work-item-status.sh --read <path>`（develop.md Step 1 と同じ）を用いる。release.md 本体で grep/sed/awk による frontmatter 生パースをしない（`lib/frontmatter.sh` 直叩き・parser 重複も避ける）。手順側は status 集計（`done`/`withdrawn` 以外の抽出）のみを担う。schema 健全性確認は `work-item-validate.sh` の責務（設計レビュー R1 #2）。

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `extend`（既存スクリプト read-only 利用 + status 集計） | `state-read.sh`（state 前提）+ `work-item-validate.sh`（schema 健全性 read-only）+ `work-item-status.sh --read <path>`（各 item の status 読取）を利用し、未完了一覧は手順側で status を集計して提示する | **採用** | Unit 境界（read-only / 新規スクリプト追加なし）に合致。既存 atomic/parser/status 読取資産を再利用し、frontmatter 構造解釈の重複・安全境界逸脱を避ける |
| `replace`（release 専用 readiness スクリプト新規作成） | `release-readiness.sh` のような専用スクリプトを新規実装し完了検出を一括化 | 却下 | Unit 001 スコープは骨格 + Step 1 手順。新規スクリプトは責務肥大化、テスト追加（Unit 004）にも波及。本 Unit は read-only 手順に留める |
| `refactor`（`work-item-validate.sh` に status 集計機能追加） | 検証スクリプトに「未完了 item 一覧出力」を足す | 却下 | 既存 validator の責務（schema 妥当性）を超える機能追加。state.json schema/validator 変更は Unit 境界外。後続 Unit/別 Issue で検討すべき |

## エンティティ（Entity）

### ReleaseReadinessGate（リリース準備ゲート）

- **ID**: なし（手順上の論理判定であり永続エンティティではない / cycle 単位の評価セッション）
- **属性**:
  - cycle: string - 対象サイクル識別子（`state-read.sh current_cycle` で解決）
  - statePrecondition: StatePrecondition - state.json の前提（下記値オブジェクト）
  - workItemCompletion: WorkItemCompletionStatus - 全 work item の完了状態集計
  - worktreeStatus: WorktreeStatus - git ワーキングツリーの clean/dirty
  - testCiStatus: TestCiStatus - プロジェクトの test/CI 状態
- **振る舞い**:
  - evaluate(): GateDecision を導出する（continue / stop / warn-continue）。read-only（state 書き込み・status 遷移なし）
  - reportBlockers(): stop 時に未完了 work item 一覧・原因を提示する

### WorkItemCompletionStatus（work item 完了状態集計）

- **ID**: cycle 単位（work item 集合に対する集計ビュー）
- **属性**:
  - items: List<WorkItemRef> - `.aidlc/cycles/<cycle>/work-items/*.md` の frontmatter status を走査した結果
  - incompleteItems: List<WorkItemRef> - status が `done` / `withdrawn` 以外（= `pending` / `in_progress` / `blocked`）の item
- **振る舞い**:
  - isAllComplete(): incompleteItems が空なら true（全 item が `done` / `withdrawn`）
  - listIncomplete(): 未完了 item の id + status を提示用に列挙

## 値オブジェクト（Value Object）

### StatePrecondition（state 前提）

- **属性**: defineCompleted: boolean / stateExists: boolean - state.json 存在 + `define_completed` の値
- **不変性**: ゲート評価時点のスナップショット（read-only）。release Step 1 では変更しない
- **等価性**: stateExists × defineCompleted の組で判定
- **解釈規則**: `stateExists=false`（state.json 不在 / `current_cycle` 欠落 = `state-read.sh` exit 1）または `defineCompleted=false` の場合、release に入らず define/develop へ案内（data-model §5.1 評価順 2）

### WorktreeStatus（worktree 状態）

- **属性**: dirty: boolean - `git status --porcelain` が非空なら dirty
- **不変性**: 評価時点のスナップショット
- **等価性**: dirty 真偽で判定
- **解釈規則**: dirty → stop（release 準備中の未コミット差分混入を防ぐ / define.md Step 1・develop.md Step 0 と同方針）

### TestCiStatus（test/CI 状態）

- **属性**:
  - testResult: enum（`pass` / `fail` / `unknown`）- プロジェクトのテスト実行結果
  - ciConclusion: enum（`success` / `failure` / `pending` / `none` / `unavailable`）- CI の最新 conclusion
- **不変性**: 評価時点のスナップショット
- **解釈規則**:
  - testResult: `fail` → stop / `pass` → continue / `unknown` → 設計時の方針に従う（実行可能なら実行して判定）
  - ciConclusion: `failure` → stop / `success` → continue / `pending`・`none`・`unavailable`（`gh` 不在・CI 未設定含む）→ warn して継続

## 集約（Aggregate）

### ReleaseReadiness（リリース準備集約）

- **集約ルート**: ReleaseReadinessGate
- **含まれる要素**: StatePrecondition / WorkItemCompletionStatus / WorktreeStatus / TestCiStatus
- **境界**: release Step 1 の単一評価（cycle 単位）。Step 2 以降（PR・merge）は本集約の外
- **不変条件**:
  - read-only（評価で aidlc state.json / frontmatter / journal / commit を変更しない。test 実行が worktree を汚す可能性は test 後の dirty 再評価で stop に倒す）
  - stop / warn の各条件は独立に評価し、stop が 1 つでも成立すれば GateDecision=stop（fail-closed）
  - 完了判定は `done` / `withdrawn` の 2 値のみを完了扱いとする（`blocked` は未完了）
  - status 読取・frontmatter 構造解釈は安全境界スクリプト（`work-item-status.sh --read`）に委譲し、手順側で生パースしない

## ドメインサービス

### GateDecisionService（ゲート判定サービス）

- **責務**: 4 入力（StatePrecondition / WorkItemCompletionStatus / WorktreeStatus / TestCiStatus）から GateDecision を一意に導出する純粋判定
- **操作**:
  - decide() - 評価順: (1) state 前提不成立 → 案内して停止 / (2a) work item schema preflight（`work-item-validate.sh`）exit 1=validation stop・exit 2=system error stop / (2b) 各 item status 集計（`work-item-status.sh --read`）で未完了あり → 一覧提示して停止 / (3) worktree dirty（事前）→ 停止 / (4) test 実行 fail → 停止 / CI failure → 停止 / (5) test 実行後に worktree dirty 再評価 → dirty なら停止（test 生成物混入の検出 / R1 #1）/ (6) CI pending・未実行・取得不能 → 警告継続 / すべて充足 → Step 2 へ continue

## GateDecision（判定結果 / 値オブジェクト）

- **属性**: outcome: enum（`continue` / `stop` / `warn_continue`）/ reason: string / blockers: List<string>
- **意味**: `continue`=Step 2 へ / `stop`=案内提示して release 中断（mutation なし）/ `warn_continue`=警告表示の上で継続

## リポジトリインターフェース

本 Unit は read-only 手順であり永続化リポジトリを新設しない。状態参照は既存スクリプト経由:

- StateReader（既存 `state-read.sh`）: `current_cycle` / `define_completed` を read（exit 0/1/2）
- WorkItemValidator（既存 `work-item-validate.sh` read-only）: work item の schema 健全性確認（exit 0/1/2）
- WorkItemStatusReader（既存 `work-item-status.sh --read <path>`）: 各 work item の status 読取（`status:<value>` / 安全境界）。手順側はこれを全 item に適用して未完了を集計する

## ユビキタス言語

- **リリース準備ゲート（release readiness gate）**: release フェーズ Step 1。全 work item 完了・state 前提・worktree・test/CI を確認し release 継続可否を判定する read-only ゲート
- **完了（complete）**: work item frontmatter status が `done` または `withdrawn`（cycle 終端判定 / data-model §5.1 評価順 4）
- **未完了（incomplete）**: status が `pending` / `in_progress` / `blocked`
- **mutation なし（read-only）**: state.json への書き込み・status 遷移・journal/commit を一切行わない（stop でも副作用を残さない）
- **stop / warn_continue / continue**: ゲート判定の 3 結果

## 不明点と質問（設計中に記録）

[Question] release Step 1 の test 確認は「その場で実行」か「直近結果の参照」か。
[Answer] 計画レビュー（R3）で確定: 既存テスト入口を**その場で実行**し exit 0=継続 / non-zero=停止。CI は `gh` 利用可時に最新 conclusion を参照（success=継続 / failure=停止 / pending・未実行・取得不能=警告継続）。

[Question] 未完了 work item の「一覧提示」に専用スクリプトを新設するか / status 読取をどう安全に行うか。
[Answer] 新設しない（Unit 境界 / read-only）。schema 健全性は `work-item-validate.sh`、各 item の status 読取は既存 `work-item-status.sh --read <path>`（develop.md と同じ安全境界）を用い、手順側は集計のみ。release.md 本体で frontmatter を生パース（grep/sed/awk）しない（設計レビュー R1 #2/#3 反映）。

[Question] read-only と test 実行（worktree を汚し得る）の整合は。
[Answer] `read-only` は「aidlc state.json / frontmatter / journal / commit を変更しない」意味に限定。test 実行は worktree を汚し得るため、test 後に `git status --porcelain` を再評価し dirty なら stop（評価順 5 / 設計レビュー R1 #1 反映）。
