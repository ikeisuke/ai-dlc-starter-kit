# AI-DLC v3 ワークフロー設計

- **ステータス**: Accepted（Unit 002 設計フェーズ承認済 / 2026-06-10）
- **対象サイクル**: v3.0.0-alpha.1
- **位置づけ**: v3 のコマンド体系・フェーズ詳細・承認ゲート・review 統合の設計正本
- **入力**: `docs/v3/rfc.md`（Unit 001 確定 RFC: DG-1〜DG-6・core/extension 境界）、`docs/v3-renewal-plan.md`（ワークフロー / フェーズ詳細設計）
- **SoT 境界**: フェーズ導出ロジックの正本は `docs/v3/data-model.md`（Unit 003）。本書は導出**結果**を参照し、導出規則そのものは再定義しない（§2.3 / §7）
- **スコープ外**: state.json schema 詳細（data-model.md）/ migration（migration.md）/ skeleton・スクリプト実装（後続フェーズ）

---

## 1. 概要 / 目的

v3 のワークフローは、**4 つのフェーズコマンド**（`define` / `develop` / `release` / `reflect`）と **2 つの補助コマンド**（`status` / `doctor`）、および連続実行ラッパ `express` で構成される。v2 の inception/construction/operations/retrospective を踏襲しつつ、行為を直接表現する名称に刷新し（RFC DG-1）、フェーズ進行を会話履歴の推論ではなく **state.json + work item frontmatter からの明示的なフェーズ導出**に置換する（RFC DG-6 / RFC §1）。

本書は各コマンドの責務、v2 からのコマンド対応・エイリアス、引数なし実行のルーティング、各フェーズの Step 詳細、Express の適用単位、承認ゲートと review 統合（RFC DG-4）を定義する。

---

## 2. コマンド体系

### 2.1 6 コマンドの責務

| コマンド | 分類 | 責務 | 旧フェーズ |
|---------|------|------|-----------|
| `define` | フェーズコマンド | 目的・スコープ・完了条件・作業単位（work item）を決める | Inception |
| `develop` | フェーズコマンド | 次の work item を実装・検証・完了する（1 実行 = 1 work item） | Construction |
| `release` | フェーズコマンド | main に安全に取り込む（PR 整備・merge） | Operations |
| `reflect` | フェーズコマンド（任意実行） | 振り返り、改善 Issue を作る | Retrospective |
| `status` | 補助コマンド（**読み取り専用**） | state.json + frontmatter からフェーズを導出し現在地・次アクションを表示 | （v2 で preflight に内包） |
| `doctor` | 補助コマンド（**診断**） | config / git / gh / state / work-items / trace の問題を診断（**自動修正しない**） | （v2 で preflight + recovery に分散） |

フェーズコマンドは状態を進行させ承認ゲートを持つ。補助コマンドは状態を変更せず、フェーズ進行ゲートを持たない（`status` は読み取り専用、`doctor` は診断のみで自動修正しない）。`express` は独立コマンドではなくフェーズコマンドの連続実行ラッパである（§4）。

### 2.2 v2 → v3 コマンド対応・エイリアス方針

| v2 コマンド | v3 コマンド | エイリアス方針 |
|------------|------------|--------------|
| inception | `define` | `inception` を後方互換エイリアスとして維持 |
| construction | `develop` | `construction` を後方互換エイリアスとして維持 |
| operations | `release` | `operations` を後方互換エイリアスとして維持 |
| retrospective | `reflect` | `retrospective` を後方互換エイリアスとして維持 |
| express | `express` | 維持（名称変更なし） |
| （なし） | `status` | 新設（v2 では preflight に埋め込まれていた現在地表示を独立） |
| （なし） | `doctor` | 新設（v2 では preflight + recovery spec に分散していた診断を集約） |

**エイリアス方針（RFC DG-1 整合）**: 主表示・正式名は新名称。旧フルネーム（inception / construction / operations / retrospective）のみを後方互換エイリアスとして維持する。**不採用動詞（build / implement 等）はエイリアスにしない**（混乱要因の排除）。"build" は compile を連想させるため不採用とし、設計・実装・テストを含む広義の開発を表す **"develop"** を採用した。

### 2.3 引数なし実行ルーティング

- `/aidlc`（引数なし）は **state.json + work item frontmatter からフェーズを導出**し、対応するフェーズコマンドへ自動ルーティングする。
- `state.json` が存在しない場合は `define` にフォールバックする。
- **フェーズ導出ロジックの正本（SoT）は `docs/v3/data-model.md`（Unit 003）**。本書は導出**結果**を参照してルーティングを記述し、導出規則そのものを再定義しない（参照形は §7）。

ルーティングの概念フロー:

```text
/aidlc（引数なし）
  ├─ state.json 不在        → define
  └─ state.json 存在        → フェーズ導出（data-model.md SoT）
        ├─ define 未完了     → define
        ├─ work item 残あり  → develop
        ├─ 全 work item 完了 → release
        └─ merged + 承認済   → reflect（任意）
```

---

## 3. フェーズ詳細設計（Step レベル）

各フェーズの Step・承認ゲート（★）・成果物を定義する。承認ゲートの v2→v3 対応は §5、review perspective は §6 を参照。

### 3.1 define（Inception）

目的: 作るもの・作らないもの・完了条件・作業単位を決める。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 環境チェック | config.toml 存在確認 / git clean 確認 / 前 cycle の journal.md・reflect.md があれば読込 | - |
| 2 Intent 定義 | 目的を 1 文で確認（AI 提案 → 人間承認）/ scope in・out / acceptance criteria → intent.md 作成 | ★ Intent 承認 / `intent.md` |
| 3 Work Item 分割 | intent を work item に分割（AI 提案 → 人間承認）/ 各 item に size・risk 付与 / 依存整理 → work-items/*.md | ★ Work Item 承認 / `work-items/*.md` |
| 4 初期化 | state.json 初期化 / cycle ディレクトリ作成 / journal.md に define 完了追記 / git branch + 初回 commit /（`early_pr: true` 時のみ Draft PR） | `state.json`・journal.md・branch |

`state.json` の `define_completed` は完了後に `true` となる（フェーズは `define_completed` + work item 状態から自動導出され、`current_phase` は保持しない / §7）。

**core から外す**（extension / 廃止）: Milestone 作成（extension）/ GitHub Projects 登録（廃止）/ heavy duplicate check（AI 判断に委ねる）/ PRFAQ 強制（任意成果物化）/ decisions 強制（任意成果物化）。

### 3.2 develop（Construction）

目的: 次の work item を安全に終わらせる（1 実行 = 1 work item）。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 Work Item 選定 | frontmatter から次 item を選定（依存解決: dependencies が全て done の候補）/ status: in_progress に更新 | - |
| 2 計画 + 設計（normal / risky のみ） | tiny: スキップ / normal: 簡易 design / risky: design + risk analysis + test plan（comprehensive でシーケンス図追加）。**実際の design 要否・含むセクションは depth_level により異なる（正本は `docs/v3/data-model.md` §8）。本列は概要であり、`risky+standard` は risk analysis / test plan を含まない等の差分は §8 を参照** | ★ Design 承認（normal/risky）/ `designs/*.md` |
| 3 実装 | acceptance criteria に沿って実装 / Self-Healing Loop（テスト → 失敗 → 自動修正 → リトライ）/ work item 単位 commit | 実装コード + commit |
| 4 検証 | テスト / lint / ビルド検証（コンパイル等）/ acceptance criteria チェック | 検証結果 |
| 5 レビュー（normal / risky のみ） | tiny: スキップ / normal: perspective=code / risky: perspective=code（security focus を含む）/ 上限 5R / Defer 戦略（OUT_OF_SCOPE・TECHNICAL_BLOCKER → 自動 Issue）。integration / deploy / premerge は **develop では実行せず release で実行**（§3.3 / §6）。**実際の review 要否・review_mode は depth_level により異なる（正本は `docs/v3/data-model.md` §8）。`normal+minimal` は review 不要、`risky+standard` は code（security focus）、`risky+comprehensive` は code（security）+ design** | `reviews/*.md` |
| 6 完了 | status: done に更新 / journal.md に完了記録追記 / squash commit（設定に応じて）/ 次 item あれば Step 1 へ、全 item が done・withdrawn で release を案内 | frontmatter(done)・journal.md |

**work item ループ**: develop は 1 実行で 1 work item を完了する。全 work item の frontmatter が done / withdrawn になったら release フェーズへの遷移を提案する（フェーズ導出で自動判定 / §7）。**依存解決**: 依存グラフを走査し dependencies が全て done の work item から次候補を選定。候補が複数なら AI が優先度を提案し人間が選択する。

### 3.3 release（Operations）

目的: main に安全に取り込む。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 リリース準備 | 全 work item 完了を確認（done / withdrawn のみ許容、blocked は done または withdrawn に解決してから release）/ git status / test・CI 状態確認 | - |
| 2 PR 整備 | PR 未作成なら作成（デフォルト。`early_pr: true` で define 時作成済みなら更新のみ）/ PR 本文作成・更新 / release.md 作成 / **review 実行**: 複数 work item 完了時は perspective=integration、risky 時は perspective=deploy、**常時** perspective=premerge | ★ PR ready 確認 / PR・`release.md` |
| 3 Merge 承認 + 実行 | PR を ready 化 / CI パス確認 / state.json に `release.merge_approved: true` を **merge 前**に commit + push / merge 実行 | ★ merge 承認（manual/semi_auto）/ `state.json` |
| 4 Post-merge | ローカル branch 更新（main に switch・feature branch 削除）/ tag 作成（`version_tag: true`）/ changelog 追記（`changelog: true`）/ journal.md に release 完了追記 | tag・changelog（任意）・journal.md |

**merge_approved の記録タイミング**: merge 後はブランチが消えるため、`release.merge_approved: true` は merge 前の最終コミットで記録する。`complete` 判定には merge_approved（ブランチ上の承認記録）と PR の実態（実際に merged か）の両方が必要（§7）。

**core から外す**（extension / 廃止）: deploy checklist 強制（project type hook として extension 化）/ monitoring strategy 強制 / distribution feedback 強制 / GitHub Milestone close 強制 / GitHub Release 強制。

### 3.4 reflect（Retrospective・任意実行）

目的: 改善を次の行動に変える。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 材料収集 | journal.md を読む / release.md の結果を読む / work item の withdrawn・blocked 理由を読む | - |
| 2 Problem / Try 抽出 | AI が KPT（Keep / Problem / Try）を提案 → 人間が確認・編集 | （人間確認・編集） |
| 3 行動化 | Try を Issue 化するか確認 / 必要な Issue だけ作成 / reflect.md に記録 | `reflect.md`・Issue |
| 4 完了 | journal.md に reflect 完了を追記 | journal.md |

明示の ★ 承認ゲートは持たない（Step 2 で人間が編集、Step 3 で Issue 化を人間に確認する）。

**core から外す**（廃止）: upstream mirror（starter kit 固有）/ cap 管理 / dialog token / aggregate retrospective issue。

### 3.5 status（補助 / 読み取り専用）

state.json + work item frontmatter を読み取り、フェーズを導出して現在地・次アクションを表示する。**状態を変更しない**。

出力例:

```text
Cycle: v3.0.0
Phase: develop (derived: define_completed=true, 2/4 items remaining)
Current work item: 002-normalize-state (size: normal, risk: medium, status: in_progress)
Completed: 2/4 (001-example done, 003-cleanup withdrawn)
Blocked: none
Remaining: 002-normalize-state, 004-review-merge
Suggested command: /aidlc develop
```

state.json が存在しない場合:

```text
No active cycle found.
Suggested command: /aidlc define
```

### 3.6 doctor（補助 / 診断）

preflight と recovery を通常フローから分離した診断コマンド。**自動修正しない**（診断と推奨のみ）。

チェック項目:

| 項目 | 内容 |
|------|------|
| `[config]` | `.aidlc/config.toml` 存在 + 必須キー確認 |
| `[state]` | `.aidlc/state.json` 存在 + schema validation（`define_completed` / `release` のみ） |
| `[cycle]` | `current_cycle` のディレクトリパス存在確認 |
| `[work-items]` | work item frontmatter の整合性（status / size / risk / dependencies の妥当性） |
| `[phase]` | フェーズ導出結果の表示（state.json + frontmatter → 導出フェーズ） |
| `[git]` | git status（clean / dirty）/ default branch / remote |
| `[gh]` | gh auth status |
| `[pr]` | active PR の存在・状態確認 |
| `[scripts]` | 必須スクリプトの存在確認 |
| `[trace]` | trace chain の整合性（intent → work items → designs の参照チェック） |

出力例:

```text
[config]      OK
[state]       OK (define_completed: true, release.merge_approved: false)
[cycle]       OK
[work-items]  WARN: 002-normalize-state has status: in_progress but no recent commits
[phase]       develop (derived: define_completed=true, 2 items remaining)
[git]         OK (branch: cycle/v3.0.0, clean)
[gh]          OK (authenticated as user)
[pr]          OK (PR #123, draft)
[scripts]     OK
[trace]       WARN: work_item 003 has no design file (size: normal, expected)

Recommendations:
  1. Continue: /aidlc develop (work item 002 is in_progress)
  2. Create designs/003-*.md before completing work item 003
```

---

## 4. Express モード

Express は **単一 work item サイクル専用**である（RFC DG-2 の引き継ぎ事項を本書で確定）。

- define で生成される work item が **1 つ（tiny または normal）の場合のみ**、`define` + `develop` + `release` を連続実行する。
- define の結果 work item が **複数**になった場合、express は define 完了後に終了し、`develop` / `release` を個別に実行するよう案内する。
- **risky work item を含む場合は連続実行しない**（risky は承認・レビューの厚みが必要なため個別実行に案内）。

実装は SKILL.md ルーティングのチェーン記述のみで完結する（フェーズ詳細は §3 を共有）。

---

## 5. 承認ゲート設計

### 5.1 承認ゲート v2 → v3 対応

| v2 ゲート | v3 ゲート | 変更 |
|----------|----------|------|
| Intent 承認 | Intent 承認 | 維持（define Step 2） |
| Stories 承認 | （廃止） | work item 分割に吸収 |
| Unit 定義承認 | Work Item 承認 | 名称変更、承認は維持（define Step 3） |
| Plan 承認 | Design 承認に統合 | normal: 簡易 design 承認 / risky: design + risk analysis 承認（develop Step 2） |
| Design 承認 | Design 承認 | 維持（normal/risky で厚みが変わる） |
| Code Review | Code Review | 維持（normal/risky で実行、develop Step 5） |
| Integration Review | Integration Review | 条件付き（複数 work item 完了時のみ、release Step 2） |
| Deploy Review | Deploy Review | 条件付き（risky のみ、release Step 2） |
| （なし） | Pre-merge Review | 新設（常に実行、release Step 2） |

### 5.2 維持する方法論ロジック

v2 の防御ロジックは削るが、以下の方法論ロジックは維持する（RFC §3）。

- **レビュー上限**: 最大 5 ラウンド、未解決なら人間にエスカレーション。
- **Defer 戦略**: OUT_OF_SCOPE / TECHNICAL_BLOCKER を明示理由付きで defer → 自動 Issue 化。
- **スコープ保護**: Intent 要件を defer する場合は人間確認必須。
- **Self-Healing Loop**: コード生成 → テスト → 自動修正提案 → リトライのサイクル。
- **依存解決**: 依存グラフに基づく work item 実行順序の自動提案。
- **Depth Level 分岐**: minimal（設計スキップ）/ standard（全工程）/ comprehensive（リスク分析・シーケンス図追加）。

---

## 6. review 統合（RFC DG-4）

### 6.1 aidlc-review への perspective 統合

v2 の perspective を持つ `reviewing-*` レビュースキル（**9 個**）を **1 個（`aidlc-review`）に perspective パラメタ化**する（RFC DG-4）。perspective が省略された場合は state.json + work item frontmatter からフェーズと作業状況を導出して自動判定する。

| v2 skill | v3 perspective | 実行条件 |
|----------|---------------|---------|
| reviewing-inception-intent | `intent` | define 完了時 |
| reviewing-inception-stories | `stories` | define 完了時（depth_level: comprehensive） |
| reviewing-inception-units | `units` | define 完了時 |
| reviewing-construction-plan | `plan` | develop 開始時（normal/risky） |
| reviewing-construction-design | `design` | design 完了時（normal/risky） |
| reviewing-construction-code | `code` | 実装完了時（normal/risky） |
| reviewing-construction-integration | `integration` | 複数 work item 完了時（release） |
| reviewing-operations-deploy | `deploy` | release 時（risky のみ） |
| reviewing-operations-premerge | `premerge` | merge 前（常時） |

**実行タイミングは上表の「実行条件」列を正本とする。**

**perspective と focus の区別**: `security` は独立 perspective ではなく、`code`（develop Step 5）/ `premerge`（release Step 2）perspective 内の **focus** として扱う（v2 の `reviewing-construction-code` / `reviewing-operations-premerge` の `code + security` focus を継承）。`integration` / `deploy` / `premerge` perspective は **release で実行**し、develop では実行しない。

`sync-reviewing-common.sh` は不要化し、`reviewing-common-base.md` は `aidlc-review` 内 1 箇所のみに統合する（RFC §1 課題 3 の DRY 違反解消）。

> **数の補足（RFC §1 課題 3 との整合）**: perspective を持つレビュースキルは **9 個**（上表）。一方 `reviewing-common-base.md` は **10 箇所**（9 スキル + 共有基盤ディレクトリ `reviewing-common`）に `sync-reviewing-common.sh` で複製されている。RFC §1 課題 3 の「10 箇所に sync」はこの 10 複製箇所を指す。v3 では 9 perspective を 1 スキルに統合し、共有基盤の複製も解消する。

### 6.2 size × review マトリクス（work item size に由来する review）

下表は work item の **size に由来して追加される review** を実行フェーズ付きで示す（`code` は develop、`deploy` は risky 時の release）。size に依存しない release review（`premerge` / `integration`）は表下の注記を参照。

| size | size 由来で追加される review（実行フェーズ） |
|------|----------------|
| tiny | 原則不要（必要時のみ self review） |
| normal | code review（develop） |
| risky | code review（security focus 含む / develop）+ deploy review（release） |

> **size 非依存の release review**: `premerge` は size に関係なく **常時**実行する。`integration` は複数 work item 完了時に実行する（§3.3 / §6.1）。本表は size 由来で追加される review を示すものであり、release-level の `premerge` / `integration` を除外する意味ではない。

### 6.3 size × depth_level マトリクス

> **非正本ビュー**: 本表は `docs/v3/data-model.md` §8 の参照用ビューである。**成果物要否の唯一の正本は data-model.md §8**。両者に差異が生じた場合は §8 を優先し、本表を §8 に合わせて更新する（SoT 二重定義回避）。

| | depth_level: minimal | depth_level: standard | depth_level: comprehensive |
|---|---|---|---|
| size: tiny | 実装のみ | 実装のみ | 実装 + 短い理由記録 |
| size: normal | 実装 + テスト | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
| size: risky | （risky は minimal 不可） | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

`size` は per-work-item、`depth_level` は per-cycle のグローバル設定で独立。両者の組み合わせで実作業量が決まる。

---

## 7. RFC・data-model との整合（SoT 二重定義回避）

### 7.1 フェーズ導出ロジックの参照

**フェーズ導出ロジックの正本は `docs/v3/data-model.md`（Unit 003）§5（Unit 003 で確定済み）**。本書（§2.3 ルーティング / §3.5 status / §3.6 doctor）は導出**結果**を参照する形で記述し、導出規則本体を再定義しない。以下は条件の**非規範スナップショット**であり、**評価順序は表さない**（first-match の評価順序・`complete` 最優先は data-model.md §5.1 が正本）:

| 条件（非規範 / 順不同） | 導出フェーズ |
|-----|-----------|
| `release.merge_approved: true` かつ PR が merged 状態 | complete（reflect 可能） |
| `define_completed: false` | define |
| `define_completed: true` かつ work item に done / withdrawn 以外がある | develop |
| `define_completed: true` かつ全 work item が done / withdrawn | release 可能 |

**規則の解釈は data-model.md §5 を参照すること**（本表は参考であり、評価順序・排他関係を含む正確な導出規則は data-model.md §5.1 で確定済み）。develop → release のフェーズ遷移は「最後の work item を done にした作業者が自動的に release 可能状態を作る」ため、「誰が変えるか」問題が発生しない。`complete` 判定には merge_approved（ブランチ上の承認記録）と PR の実態（実際に merged か）の両方が必要。

### 7.2 GitHub 前提（RFC DG-5 整合）

core ワークフローが依存する GitHub 機能は **Issue / PR まで**。release の PR 整備・merge、develop の Defer 自動 Issue 化は core。Milestone close / GitHub Release / Projects は extension / 廃止であり、本書の core フローには含めない。core は extension 不在でも成立する。

### 7.3 trace chain 整合

各フェーズの成果物は以下の trace chain を構成し、data-model.md の trace 設計と矛盾しない:

```text
intent.md
  → work-items/*.md
  → designs/*.md        (normal / risky のみ)
  → tests / checks
  → reviews/*.md        (normal / risky または必要時)
  → journal.md
  → release.md
  → reflect.md          (任意)
  → 次 cycle の define input
```

work item の trace 情報（intent_refs / acceptance criteria / verification status 等）の正本は各 `work-items/*.md` の frontmatter と本文に置く。state.json はサイクルレベルの状態（define 完了・release 状態）のみ保持する（詳細は data-model.md）。
