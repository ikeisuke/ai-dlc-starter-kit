# Unit 002 論理設計: v3 ワークフロー設計

> docs-only の設計文書 Unit のため、ドメインモデルは N/A。本 logical design に「workflow.md のアウトライン + 6 コマンド責務 + v2 対応 + 引数なしルーティング + 各フェーズ Step 詳細 + Express + review 統合」を集約する。これが Phase 2（`docs/v3/workflow.md` 執筆）の設計入力となる。

## 0. 事前コード読込み（既存実装の参照）

docs 設計 Unit のため新規 v3 実装コードは存在しない。設計判断の根拠となる「既存実装の挙動」は v2 のコマンド表面と RFC 確定事項である。

### (a) Read 対象 + 目的

| 対象 | Read 目的 |
|------|----------|
| `skills/aidlc/SKILL.md`（v2 ARGUMENTS パーシング・引数ルーティング表） | v2 の `inception/construction/operations/...` ルーティングと短縮形・引数なし判定（`cycle/*` ブランチで construction）を把握し、v3 ルーティングの後方互換エイリアス設計の起点とする |
| `docs/v3/rfc.md`（Unit 001 確定 RFC §5・§7） | DG-1（develop 確定）/ DG-2（Express）/ DG-4（review perspective 統合）/ DG-5（GitHub core は Issue/PR まで）と core/extension 境界を設計制約として取り込む |
| `docs/v3-renewal-plan.md`（ワークフロー / フェーズ詳細設計） | 各フェーズの Step 構成・承認ゲート位置・成果物・承認ゲート v2→v3 対応・size×review マトリクスの原案を一次入力とする |

### (b) 設計時に意識すべき挙動

- v2 は引数なし実行時に **ブランチ名（`cycle/*`）で construction を判定**している。v3 は state.json + work item frontmatter からのフェーズ導出に置換する（明示状態ベース、推論削減）。ただし v3 でもブランチ文脈は補助的判断材料になりうるため、フェーズ導出の正本は data-model.md に置き、workflow.md は導出結果を参照する。
- v2 のコマンド短縮形（`inc/con/ops/...`）とエイリアス慣習が存在する。v3 では旧フルネームを後方互換エイリアスに保つ（DG-1）。
- 計画書原文は一貫して "build" 表記。RFC DG-1 で "develop" に確定済みのため、本設計および workflow.md では **develop を正本**とし、"build" は使用しない（v2→v3 対応表でも v3 列は develop）。

### (c) 既存実装に基づく代替案検討（ルーティング方式）

| 方式 | 既存（v2）適合性 | 採否 |
|------|----------------|------|
| `refactor`: v2 のブランチ名推論ルーティングを踏襲 | 低（推論ベースで RFC の「明示状態」方針に反する） | 却下 |
| `replace`: 引数なしを state.json + frontmatter 導出に全面置換 | 高（RFC DG-6 ハイブリッド state・明示状態方針と整合） | **採用** |
| `extend`: 旧名エイリアスのみ追加し中身は v2 維持 | 低（コマンド体系刷新の目的を満たさない） | 却下 |

## 1. workflow.md アウトライン（章立て）

Phase 2 で以下の構成で執筆する。

```text
1. 概要 / 目的（v3 ワークフローの全体像。フェーズ4 + 補助2 + Express）
2. コマンド体系
   2.1 6 コマンドの責務（フェーズコマンド4 / 補助コマンド2 の区別）
   2.2 v2 → v3 コマンド対応・エイリアス方針
   2.3 引数なし実行ルーティング（フェーズ導出は data-model.md SoT を参照）
3. フェーズ詳細設計（Step レベル）
   3.1 define（Inception）
   3.2 develop（Construction）
   3.3 release（Operations）
   3.4 reflect（Retrospective）
   3.5 status（補助 / 読み取り専用）
   3.6 doctor（補助 / 診断）
4. Express モード（適用単位・連続実行仕様）
5. 承認ゲート設計（v2→v3 対応 + 維持する方法論ロジック）
6. review 統合（DG-4: aidlc-review perspective / size×review・size×depth_level マトリクス）
7. RFC・data-model との整合（SoT 二重定義回避方針）
```

## 2. コマンド体系設計

### 2.1 6 コマンドの責務

| コマンド | 分類 | 責務 | 旧フェーズ |
|---------|------|------|-----------|
| `define` | フェーズコマンド | 目的・スコープ・完了条件・作業単位（work item）を決める | Inception |
| `develop` | フェーズコマンド | 次の work item を実装・検証・完了する（1 実行 = 1 work item） | Construction |
| `release` | フェーズコマンド | main に安全に取り込む（PR 整備・merge） | Operations |
| `reflect` | フェーズコマンド（任意実行） | 振り返り、改善 Issue を作る | Retrospective |
| `status` | 補助コマンド（**読み取り専用**） | state.json + frontmatter からフェーズを導出し現在地・次アクションを表示 | （v2 で preflight に内包） |
| `doctor` | 補助コマンド（**診断**） | config / git / gh / state / work-items / trace の問題を診断（**自動修正しない**） | （v2 で preflight + recovery に分散） |

`express` は独立コマンドではなくフェーズコマンドの連続実行ラッパ（§4）。補助コマンド 2 つは状態を変更せず、フェーズ進行に承認ゲートを持たない点でフェーズコマンドと区別される。

### 2.2 v2 → v3 コマンド対応・エイリアス方針

| v2 コマンド | v3 コマンド | エイリアス方針 |
|------------|------------|--------------|
| inception | define | `inception` を後方互換エイリアスとして維持 |
| construction | develop | `construction` を後方互換エイリアスとして維持 |
| operations | release | `operations` を後方互換エイリアスとして維持 |
| retrospective | reflect | `retrospective` を後方互換エイリアスとして維持 |
| express | express | 維持（名称変更なし） |
| （なし） | status | 新設（v2 では preflight に埋め込まれていた現在地表示を独立） |
| （なし） | doctor | 新設（v2 では preflight + recovery spec に分散していた診断を集約） |

**DG-1 整合**: 主表示・正式名は新名称。旧名は後方互換エイリアスのみ。**不採用動詞（build / implement 等）はエイリアスにしない**（混乱要因の排除）。"build" は不採用、"develop" を採用。

### 2.3 引数なし実行ルーティング

- `/aidlc`（引数なし）は **state.json + work item frontmatter からフェーズを導出**し、対応するフェーズコマンドへ自動ルーティングする。
- `state.json` が存在しない場合は `define` にフォールバックする。
- **フェーズ導出ロジックの正本（SoT）は data-model.md（Unit 003）**。workflow.md は導出**結果**を参照してルーティングを記述し、導出規則そのものを再定義しない（二重定義回避）。導出表の現時点の確定形は §7 に参照リンクとして示し、確定値は data-model.md に委ねる。

## 3. フェーズ詳細設計（Step レベル）

各フェーズの Step・承認ゲート（★）・成果物を定義する。承認ゲートの v2→v3 対応は §5、review perspective は §6 を参照。

### 3.1 define（Inception）

| Step | 内容 | ゲート/成果物 |
|------|------|--------------|
| 1 環境チェック | config.toml 存在 / git clean / 前 cycle の journal.md・reflect.md 読込 | - |
| 2 Intent 定義 | 目的 1 文（AI 提案→人間承認）/ scope in-out / acceptance criteria → intent.md | ★ Intent 承認 / `intent.md` |
| 3 Work Item 分割 | intent を work item 分割（AI 提案→人間承認）/ 各 item に size・risk 付与 / 依存整理 → work-items/*.md | ★ Work Item 承認 / `work-items/*.md` |
| 4 初期化 | state.json 初期化 / cycle ディレクトリ作成 / journal.md に define 完了追記 / git branch + 初回 commit /（`early_pr: true` 時のみ Draft PR） | `state.json`・journal.md・branch |

core から外す（extension/廃止）: Milestone 作成（extension）/ Projects 登録（廃止）/ heavy duplicate check（AI 判断）/ PRFAQ・decisions 強制（任意成果物化）。

### 3.2 develop（Construction）

| Step | 内容 | ゲート/成果物 |
|------|------|--------------|
| 1 Work Item 選定 | frontmatter から次 item 選定（依存解決: dependencies 全 done の候補）/ status: in_progress | - |
| 2 計画+設計（normal/risky のみ） | tiny: スキップ / normal: 簡易 design / risky: design + risk analysis + test plan（comprehensive でシーケンス図） | ★ Design 承認（normal/risky） / `designs/*.md` |
| 3 実装 | acceptance criteria に沿って実装 / Self-Healing Loop（テスト→失敗→自動修正→リトライ）/ work item 単位 commit | 実装コード + commit |
| 4 検証 | テスト / lint / ビルド検証（コンパイル等）/ acceptance criteria チェック | 検証結果 |
| 5 レビュー（normal/risky のみ） | tiny: スキップ / normal: perspective=code / risky: perspective=code（security focus を含む）/ 上限 5R / Defer 戦略（OUT_OF_SCOPE・TECHNICAL_BLOCKER→自動 Issue）。**integration / deploy / premerge は develop では実行せず release で実行**（§3.3 / §6.1） | `reviews/*.md` |
| 6 完了 | status: done / journal.md 完了追記 / squash commit / 次 item あれば Step 1、全 item done・withdrawn で release 案内 | frontmatter(done)・journal.md |

**work item ループ**: develop は 1 実行 = 1 work item 完了。全 work item の frontmatter が done/withdrawn になったら release 遷移を提案（フェーズ導出で自動判定）。依存解決は依存グラフ走査で dependencies 全 done の候補を選定、複数時は AI が優先度提案 → 人間選択。

### 3.3 release（Operations）

| Step | 内容 | ゲート/成果物 |
|------|------|--------------|
| 1 リリース準備 | 全 work item 完了確認（done/withdrawn のみ許容、blocked は解決必須）/ git status / test・CI 状態確認 | - |
| 2 PR 整備 | PR 未作成なら作成（デフォルト。early_pr 時は更新のみ）/ PR 本文作成・更新 / release.md 作成 / **review 実行**: 複数 work item 完了時は perspective=integration、risky 時は perspective=deploy、**常時** perspective=premerge | ★ PR ready 確認 / PR・`release.md` |
| 3 Merge 承認+実行 | PR ready 化 / CI パス確認 / state.json に release.merge_approved: true を **merge 前**に commit + push / merge 実行 | ★ merge 承認（manual/semi_auto）/ `state.json` |
| 4 Post-merge | ローカル branch 更新（main switch・feature 削除）/ tag（version_tag: true）/ changelog（changelog: true）/ journal.md release 完了追記 | tag・changelog（任意）・journal.md |

**merge_approved の記録タイミング**: merge 後はブランチが消えるため、merge 前の最終コミットで `release.merge_approved: true` を記録する。complete 判定には merge_approved（承認記録）と PR 実態（実際に merged か）の両方が必要。core から外す: deploy checklist / monitoring / distribution feedback / Milestone close / GitHub Release 強制（extension/廃止）。

### 3.4 reflect（Retrospective・任意実行）

| Step | 内容 | ゲート/成果物 |
|------|------|--------------|
| 1 材料収集 | journal.md / release.md 結果 / work item の withdrawn・blocked 理由を読む | - |
| 2 Problem/Try 抽出 | AI が KPT（Keep/Problem/Try）提案 → 人間が確認・編集 | （人間確認） |
| 3 行動化 | Try を Issue 化するか確認 / 必要な Issue のみ作成 / reflect.md 記録 | `reflect.md`・Issue |
| 4 完了 | journal.md に reflect 完了追記 | journal.md |

明示の ★ 承認ゲートは持たない（Step 2 で人間編集、Step 3 で Issue 化を人間確認）。core から外す: upstream mirror / cap 管理 / dialog token / aggregate retrospective issue（すべて starter kit 固有のため廃止）。

### 3.5 status（補助 / 読み取り専用）

- state.json + work item frontmatter を読み取り、フェーズを導出して「Cycle / Phase（導出根拠付き）/ Current work item / Completed / Blocked / Remaining / Suggested command」を表示する。
- 状態を変更しない。state.json 不在時は「No active cycle found. Suggested command: /aidlc define」を表示。
- 承認ゲートなし。

### 3.6 doctor（補助 / 診断）

- チェック項目: `[config]`（toml 存在 + 必須キー）/ `[state]`（存在 + schema validation: define_completed・release のみ）/ `[cycle]`（ディレクトリ存在）/ `[work-items]`（frontmatter 整合: status/size/risk/dependencies）/ `[phase]`（導出フェーズ表示）/ `[git]`（clean-dirty・default branch・remote）/ `[gh]`（auth status）/ `[pr]`（active PR 状態）/ `[scripts]`（必須スクリプト存在）/ `[trace]`（intent→work items→designs の参照整合）。
- **自動修正しない**。診断結果（OK/WARN）と Recommendations のみ出力。承認ゲートなし。

## 4. Express モード（適用単位・連続実行仕様）

- **結論**: Express は **単一 work item サイクル専用**（RFC DG-2 の引き継ぎ事項を本 Unit で確定）。
- define で生成される work item が **1 つ（tiny または normal）の場合のみ** define + develop + release を連続実行する。
- define の結果 work item が **複数**になった場合、express は define 完了後に終了し、develop / release を個別実行するよう案内する。
- risky work item を含む場合は連続実行しない（risky は承認・レビューの厚みが必要なため個別実行に案内）。実装は SKILL.md ルーティングのチェーン記述のみで完結。

## 5. 承認ゲート設計（v2→v3 対応 + 維持する方法論ロジック）

### 5.1 承認ゲート v2→v3 対応

| v2 ゲート | v3 ゲート | 変更 |
|----------|----------|------|
| Intent 承認 | Intent 承認 | 維持（define Step 2） |
| Stories 承認 | （廃止） | work item 分割に吸収 |
| Unit 定義承認 | Work Item 承認 | 名称変更、承認は維持（define Step 3） |
| Plan 承認 | Design 承認に統合 | normal: 簡易 design 承認 / risky: design + risk analysis 承認（develop Step 2） |
| Design 承認 | Design 承認 | 維持（normal/risky で厚みが変わる） |
| Code Review | Code Review | 維持（normal/risky で実行、develop Step 5） |
| Integration Review | Integration Review | 条件付き（複数 work item 完了時のみ） |
| Deploy Review | Deploy Review | 条件付き（risky のみ、release） |
| （なし） | Pre-merge Review | 新設（常に実行、release Step 2） |

### 5.2 維持する方法論ロジック

- レビュー上限: 最大 5 ラウンド、未解決なら人間にエスカレーション。
- Defer 戦略: OUT_OF_SCOPE / TECHNICAL_BLOCKER を明示理由付きで defer → 自動 Issue 化。
- スコープ保護: Intent 要件を defer する場合は人間確認必須。
- Self-Healing Loop: コード生成 → テスト → 自動修正提案 → リトライのサイクル。
- 依存解決: 依存グラフに基づく work item 実行順序の自動提案。
- Depth Level 分岐: minimal（設計スキップ）/ standard（全工程）/ comprehensive（リスク分析・シーケンス図追加）。

## 6. review 統合（DG-4）

### 6.1 aidlc-review への perspective 統合

10 個の reviewing-* スキルを **1 個（aidlc-review）に perspective パラメタ化**する（DG-4）。perspective 省略時は state.json + frontmatter からフェーズと作業状況を導出し自動判定する。

| v2 skill | v3 perspective | 実行条件 |
|----------|---------------|---------|
| reviewing-inception-intent | intent | define 完了時 |
| reviewing-inception-stories | stories | define 完了時（depth_level: comprehensive） |
| reviewing-inception-units | units | define 完了時 |
| reviewing-construction-plan | plan | develop 開始時（normal/risky） |
| reviewing-construction-design | design | design 完了時（normal/risky） |
| reviewing-construction-code | code | 実装完了時（normal/risky） |
| reviewing-construction-integration | integration | 複数 work item 完了時 |
| reviewing-operations-deploy | deploy | release 時（risky のみ） |
| reviewing-operations-premerge | premerge | merge 前 |

`sync-reviewing-common.sh` は不要化し、`reviewing-common-base.md` は aidlc-review 内 1 箇所のみに統合する。

**perspective と focus の区別**: `security` は独立 perspective ではなく、`code`（develop Step 5）/ `premerge`（release Step 2）perspective 内の **focus** として扱う（v2 の `reviewing-construction-code` / `reviewing-operations-premerge` の `code + security` focus を継承）。`integration` / `deploy` / `premerge` perspective は **release で実行**し、develop では実行しない（§3.2 Step 5 / §3.3 Step 2 と整合）。実行タイミングは上表の「実行条件」列を正本とする。

### 6.2 size × review マトリクス

| size | 実行する review |
|------|----------------|
| tiny | 原則不要（必要時のみ self review） |
| normal | code review |
| risky | code review（security focus 含む）+ deploy review（deploy は release で実行） |

### 6.3 size × depth_level マトリクス

| | minimal | standard | comprehensive |
|---|---|---|---|
| tiny | 実装のみ | 実装のみ | 実装 + 短い理由記録 |
| normal | 実装 + テスト | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
| risky | （risky は minimal 不可） | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

size は per-work-item、depth_level は per-cycle のグローバル設定で独立。組み合わせで実作業量が決まる。

## 7. RFC・data-model との整合（SoT 二重定義回避方針）

- **フェーズ導出ロジックの正本は data-model.md（Unit 003）**。workflow.md（§2.3 / §3.5 status / §3.6 doctor）は導出結果を参照する形で記述し、導出規則本体（state.json + frontmatter → フェーズ の条件表）を再定義しない。現時点の導出形（参考）:

  | 条件 | 導出フェーズ |
  |-----|-----------|
  | define_completed: false | define |
  | define_completed: true かつ work item に done/withdrawn 以外あり | develop |
  | define_completed: true かつ全 work item が done/withdrawn | release 可能 |
  | release.merge_approved: true かつ PR が merged | complete（reflect 可能） |

  上表は data-model.md 確定時に正本化される（workflow.md には「正本は data-model.md」と明記し、確定値の重複記載を避ける）。

- **DG-5 整合**: core ワークフローが依存する GitHub 機能は Issue / PR まで。release の PR 整備・merge、develop の Defer 自動 Issue 化は core。Milestone close / GitHub Release / Projects は extension/廃止として workflow.md の core フローに含めない。
- **trace chain 整合**: 各フェーズ成果物（intent.md → work-items → designs → tests → reviews → journal.md → release.md → reflect.md → 次 cycle define input）は data-model.md の trace 設計と矛盾しないこと。

## 8. 完了条件への対応（unit-002-plan.md チェックリスト）

| 完了条件 | workflow.md での対応箇所 |
|---------|----------------------|
| workflow.md 作成 | 成果物が workflow.md のみ |
| 6 コマンド責務 + フェーズ/補助区別 | §2.1 |
| v2 対応表・エイリアス方針（DG-1 整合） | §2.2 |
| 引数なしルーティング（SoT 二重定義回避） | §2.3 + §7 |
| 各フェーズ Step 詳細 | §3.1〜3.6 |
| Express 適用単位確定（DG-2） | §4 |
| DG-4 review perspective 反映 | §6 |
| DG-5 整合（core は Issue/PR まで） | §7 |
| RFC 設計判断・境界と矛盾しない | 全節（§2.2/§4/§6/§7 で DG 参照） |
| docs/v3 限定・コード非生成 | 成果物が workflow.md のみ |
| markdownlint | Phase 2 で実行 |
