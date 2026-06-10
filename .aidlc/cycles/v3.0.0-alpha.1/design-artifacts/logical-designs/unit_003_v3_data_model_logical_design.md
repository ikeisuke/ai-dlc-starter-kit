# Unit 003 論理設計: v3 データモデル・state schema・work item template 確定

> docs-only の設計文書 Unit のため、ドメインモデルは N/A。本 logical design に「data-model.md のアウトライン + ディレクトリ構造 + state.json schema + work item frontmatter/template + フェーズ導出ロジック(SoT) + 破損時方針 + journal + size×depth_level マトリクス」を集約する。これが Phase 2（`docs/v3/data-model.md` 執筆）の設計入力となる。

## 0. 事前コード読込み（既存実装の参照）

docs 設計 Unit のため新規 v3 実装コードは存在しない。設計判断の根拠となる入力は、RFC 確定事項（DG-6）・workflow.md（Unit 002 の参照記述）・計画書データモデルセクションである。

### (a) Read 対象 + 目的

| 対象 | Read 目的 |
|------|----------|
| `docs/v3/rfc.md`（Unit 001 確定 §5.6 DG-6 / §7 引き継ぎマトリクス） | state format = ハイブリッド（cycle = state.json / work item = Markdown frontmatter）、フェーズ導出ロジックの正本を data-model.md に置く、`current_phase` 非保持の確定方針を設計制約として取り込む |
| `docs/v3/workflow.md`（Unit 002 確定 §2.3 / §3.5 status / §3.6 doctor / §7.1） | workflow.md が「導出**結果**を参照」する形で記述し、本 Unit が導出**規則本体**の SoT を確定する責務境界を把握。status / doctor のチェック項目から破損パターンの参照範囲を取り込む |
| `docs/v3-renewal-plan.md`（データモデルセクション L235-462） | ディレクトリ構造・分散状態モデル・state.json schema・work item frontmatter/template・フェーズ導出ロジック・size×depth_level・journal・成果物一覧の原案を一次入力とする |

### (b) 設計時に意識すべき挙動

- 計画書原文は一貫して "build" 表記。RFC DG-1 / workflow.md で "develop" に確定済みのため、本設計および data-model.md では **develop を正本**とし、"build" は使用しない（フェーズ導出表の develop 行も同様）。
- workflow.md §7.1 の導出表は「参考（正本は data-model.md）」と明記されている。本 Unit はその正本を確定する。**両者で導出規則を二重定義しない**（workflow.md = 結果参照 / data-model.md = 規則本体）。
- 分散状態モデルの意図はコンフリクト回避。state.json は single-actor moment（define 完了時・release 時）のみ書き込み、work item frontmatter は per-item 並行編集を許容する。この「誰がいつ書くか」の責務を schema 記述に併記する。
- `current_phase` は state として保持しない（導出する）。これにより develop→release 遷移の「誰が変えるか」問題を回避する。
- `complete` 判定には `release.merge_approved`（ブランチ上の承認記録）と PR の実態（実際に merged か）の**両方**が必要。merge 後はブランチが消えるため merge_approved は merge 前の最終コミットで書き込む。
- validator / state 操作スクリプトの実装は本サイクル対象外。data-model.md は schema / template / 破損方針の**文書確定のみ**を行う。

### (c) 既存実装に基づく代替案検討（data-model.md の記述方式）

| 方式 | 適合性 | 採否 |
|------|-------|------|
| `refactor`: 計画書データモデルセクションをそのまま転記 | 低（コマンド名 build 残存・SoT 正本性の明示不足・破損方針が未整理） | 却下 |
| `replace`: 確定例示として再構成（develop 整合・SoT 正本明示・書き込み主体併記・破損方針を新規に方針レベルで整理） | 高（RFC DG-6・workflow.md §7.1 の SoT 委譲方針と整合） | **採用** |
| `extend`: 計画書転記 + 追記 | 中（build 混在・二重記述リスク） | 却下 |

## 1. data-model.md アウトライン（章立て）

Phase 2 で以下の構成で執筆する。

```text
1. 概要 / 目的（分散状態モデル: cycle = state.json / work item = Markdown frontmatter / current_phase 非保持）
2. ディレクトリ構造（.aidlc 配下・cycle 配下の成果物配置と生成フェーズ）
3. state.json schema（必須フィールド・型・schema_version・enum・書き込みタイミングと主体）
4. work item frontmatter + テンプレート（必須キー・enum・本文必須セクション）
5. フェーズ導出ロジック（SoT 正本: state.json + frontmatter → define/develop/release/complete）
6. 破損・不正・矛盾時の扱い（doctor が検知するパターンと復帰可否の方針 / 方針レベル）
7. journal 形式（追記型・軽量・目的）
8. size × depth_level マトリクス（per-work-item × per-cycle）
9. trace 整合・RFC/workflow.md との整合（SoT 二重定義回避方針）
10. 成果物一覧マトリクス（フェーズ別 / §2 ディレクトリ構造の要否確定 / §8 と整合）
```

> **章対応の注記**: 上記 1〜10 が data-model.md（Phase 2 成果物）の章立て。本論理設計の §10 は data-model.md の「10. 成果物一覧マトリクス」に対応する。本論理設計の §11（完了条件への対応）は論理設計のメタ章であり、data-model.md には載せない（Phase 2 執筆対象外）。

## 2. ディレクトリ構造設計

```text
.aidlc/
  config.toml
  state.json                       (サイクルレベル状態 / cycle ルートに 1 つ)
  cycles/
    v3.0.0/
      intent.md                    (define: 必須)
      work-items/
        001-example.md             (define: 必須 / 各 item の frontmatter が個別状態)
      designs/
        001-example.md             (develop: 要否は §8 size×depth_level が正本 / normal×minimal は不要)
      reviews/
        001-example.md             (develop: 要否は §8 が正本 / normal×standard 以上で生成 / release perspective)
      journal.md                   (全フェーズ: 追記)
      release.md                   (release: 必須)
      reflect.md                   (reflect: 任意)
```

各成果物の生成フェーズと要否は §10（成果物一覧マトリクス / 要否の正本は §8 size×depth_level）で確定する。state.json は cycle ルート（`.aidlc/state.json`）に置き、cycle ディレクトリ内には置かない（サイクルをまたぐ単一の現在状態として扱う / `current_cycle` フィールドで対象 cycle を指す）。

## 3. state.json schema 設計（確定例示）

確定例示（必須フィールド集合・型・schema_version・enum を明示）:

```json
{
  "schema_version": "3.0",
  "current_cycle": "v3.0.0",
  "define_completed": false,
  "release": {
    "pr_number": null,
    "ready": false,
    "merge_approved": false
  },
  "updated_at": "2026-06-04T00:00:00Z"
}
```

フィールド定義表（data-model.md で確定）:

| フィールド | 型 | 必須 | 説明 |
|-----------|---|------|------|
| schema_version | string | Yes | schema バージョン（初版 `"3.0"`） |
| current_cycle | string | Yes | 対象 cycle 識別子（例 `"v3.0.0"`） |
| define_completed | boolean | Yes | define 完了フラグ |
| release | object | Yes | release 状態（下記 3 サブフィールド） |
| release.pr_number | integer or null | Yes | PR 番号（未作成は null） |
| release.ready | boolean | Yes | PR ready 化フラグ |
| release.merge_approved | boolean | Yes | merge 承認記録（merge 済みではない） |
| updated_at | string (ISO 8601) | Yes | 最終更新時刻 |

書き込みタイミングと主体（single-actor moment の明示）:

| フィールド | 書き込みタイミング | 主体 |
|-----------|------------------|------|
| define_completed | define Step 4 完了時 | define 実行者 |
| release.pr_number | PR 作成時 | release 実行者 |
| release.ready | PR ready 化時 | release 実行者 |
| release.merge_approved | merge 承認時（merge 直前の最終コミット） | release 実行者 |

**release.merge_approved の意味**: 人間が「merge してよい」と承認したことの記録であり、merge 済みを意味しない。実際の merge 完了は PR の状態（merged）で判定する。

## 4. work item frontmatter + テンプレート設計（確定例示）

### 4.1 frontmatter（必須キー・型・enum）

```yaml
---
id: "001"
status: pending
size: normal
risk: medium
assigned: null
dependencies: []
---
```

| キー | 型 | 必須 | enum / 値域 |
|------|---|------|------------|
| id | string | Yes | work item 識別子（3 桁ゼロ埋め推奨） |
| status | enum | Yes | pending / in_progress / blocked / done / withdrawn |
| size | enum | Yes | tiny / normal / risky |
| risk | enum | Yes | low / medium / high |
| assigned | string or null | Yes | 担当者（並行作業時 / 未割当は null） |
| dependencies | array | Yes | 依存 work item ID のリスト（空配列可） |

enum 定義（data-model.md で各値の意味を確定）:

- **status**: pending（未着手）/ in_progress（作業中）/ blocked（外部依存待ち）/ done（完了）/ withdrawn（取り下げ）
- **size**: tiny（typo / 軽微単一ファイル / 挙動リスク低）/ normal（通常機能追加・小中リファクタ・docs+code）/ risky（release / migration / security / state model 変更 / 複数サブシステム）
- **risk**: low（既存パターン踏襲・限定的）/ medium（一部新規・テスト担保可）/ high（前例なし・失敗時復旧コスト大）

### 4.2 本文必須セクション

work item Markdown 本文は以下のセクションを必須とする（テンプレート確定例示）:

```text
# Work Item NNN: <タイトル>
## Goal              (何を達成するか)
## Scope             (含むもの / 含まないもの)
## Acceptance Criteria  (チェックボックス形式)
## Traceability      (Intent refs / Acceptance refs / Verification / Release note required)
## Size / Risk       (Size / Risk / Reason)
## Dependencies      (依存 work item / none)
## Implementation Notes  (任意 / 必要時のみ)
```

## 5. フェーズ導出ロジック設計（SoT 正本）

**本セクションがフェーズ導出規則の Single Source of Truth である**。workflow.md（§2.3 / §3.5 / §3.6）はこの結果を参照する。

導出表（state.json + work item frontmatter → フェーズ）。**評価順序: 上から first-match。最も具体的な `complete` 条件を最初に評価する**（複数条件が同時成立しうるため、評価順序を表順で固定する）:

| 評価順 | 条件 | 導出フェーズ |
|-------|-----|-----------|
| 1 | `release.merge_approved: true` かつ PR が merged 状態 | complete（reflect 可能） |
| 2 | `define_completed: false`（または state.json 不在） | define |
| 3 | `define_completed: true` かつ work item に done/withdrawn 以外がある | develop |
| 4 | `define_completed: true` かつ全 work item が done/withdrawn（上記 1 に未該当） | release 可能 |

設計上の含意（data-model.md に明記する）:

- `current_phase` は state として保持しない。常に上表で導出する。
- 評価は first-match。`complete`（評価順 1）を最優先することで、「全 work item done/withdrawn（評価順 4 = release 可能）」と「merge 済み（評価順 1 = complete）」が同時成立する状態でも一意に `complete` へ導出される。
- develop → release 遷移は「最後の work item を done にした作業者が自動的に release 可能状態を作る」ため、「誰がフェーズを変えるか」問題が発生しない。
- `complete` 判定は `release.merge_approved`（state.json の承認記録）と PR 実態（実際に merged か）の**両方**を要する。merge_approved 単独では complete としない。
- state.json 不在は define フォールバック（workflow.md §2.3 と整合）。

### 5.1 dependency 解決規則（develop の work item 選定）

work item の選定で dependencies をどう解決するかを一意に定める（workflow.md §3.2「dependencies が全て done の候補を選定」を本セクションが正本化する）:

- **選定可能条件**: ある work item を develop 対象に選べるのは、その `dependencies` に列挙された全 work item の status が `done` の場合。
- **`withdrawn` 依存先の扱い**: 依存先が `withdrawn`（取り下げ）の場合は、依存解決を自動では満たさない（`done` のみが自動充足）。`withdrawn` 依存先がある dependent item は、**人間判断で「依存解除（当該依存先を dependencies から除去）」または「dependent も withdrawn」のいずれかを選ぶ**まで `blocked` 相当として進めない。
- **フェーズ導出（§5 評価順 4 の release 可能）との関係**: 全体の release 可能判定では `done` と `withdrawn` の**両方**を完了扱いとする（サイクル全体の終端判定）。これは個別 work item の dependency 解決（`done` のみ自動充足）とは別レイヤの規則であり、両者は矛盾しない（前者 = cycle 終端 / 後者 = item 選定）。

## 6. 破損・不正・矛盾時の扱い設計（方針レベル / validator 実装は対象外）

doctor が検知する破損パターンと復帰可否の**方針**を記述する（doctor は workflow.md §3.6 のとおり**自動修正しない**＝診断のみ）。validator / state スクリプトの実装は本サイクル対象外。

| パターン | 検知元 | 復帰可否方針 |
|---------|-------|------------|
| state.json 不在 | `[state]` | 復帰可（define にフォールバック。正常系の一部） |
| state.json が JSON parse 不能 | `[state]` | 復帰不可（WARN。手動修正を案内 / 自動修正しない） |
| schema_version 不一致 / 未知バージョン | `[state]` | 復帰不可（WARN。migration / 手動対応を案内） |
| 必須フィールド欠落（define_completed / release 等） | `[state]` | 復帰不可（WARN。診断のみ） |
| frontmatter 必須キー欠落 / enum 不正値 | `[work-items]` | 復帰不可（WARN。該当 work item を特定して報告） |
| state.json と frontmatter の矛盾（例: define_completed=false なのに done の work item が存在） | `[phase]` / `[work-items]` | 矛盾を WARN として報告（導出は define 側を優先 = 安全側）。自動解決しない |
| dependencies に存在しない work item ID 参照 | `[work-items]` / `[trace]` | 復帰不可（WARN。trace 整合エラーとして報告） |
| release.merge_approved=true だが PR が未 merged | `[pr]` | complete としない（merge 承認と実態の不一致を WARN） |

**方針の原則**: doctor は OK/WARN と Recommendations を出力するのみで、状態を書き換えない。復帰可否は「導出フェーズが安全側に倒れるか（define/develop 継続可能か）」で判断し、判断不能な破損は人間に手動修正を促す。

## 7. journal 形式設計

journal.md は追記型の軽量記録（v2 history より簡素）。

- **目的**: 作業証跡を残す / 全 step の詳細記録を義務化しない / 次 cycle の define で参照可能にする
- **形式**: 日付見出し（`## YYYY-MM-DD`）配下に箇条書きで「define completed」「develop started/completed: <item> (size: X)」「release ready: PR #N」等を追記

```markdown
# Journal: v3.0.0

## 2026-06-04
- define completed: intent and 3 work items created
- develop started: 001-example (size: normal)

## 2026-06-05
- develop completed: 001-example
- release ready: PR #123
```

（計画書例の "build started/completed" は確定名 "develop started/completed" に補正して記述する。）

## 8. size × depth_level マトリクス設計

size は per-work-item、depth_level は per-cycle のグローバル設定。両者は独立だが組み合わせで実作業量が決まる。

| | depth_level: minimal | depth_level: standard | depth_level: comprehensive |
|---|---|---|---|
| size: tiny | 実装のみ | 実装のみ | 実装 + 短い理由記録 |
| size: normal | 実装 + テスト | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
| size: risky | (risky は minimal 不可) | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

## 9. trace 整合・RFC/workflow.md との整合（SoT 二重定義回避）

- **trace chain**: intent.md → work-items/*.md（frontmatter + 本文 Traceability）→ designs/*.md → reviews/*.md → journal.md → release.md → reflect.md → 次 cycle define input。work item の trace 情報（intent_refs / acceptance criteria / verification status）の正本は各 work-items/*.md に置き、state.json はサイクルレベル状態のみ保持する（workflow.md §7.3 と整合）。
- **SoT 二重定義回避**: フェーズ導出規則の本体は本 data-model.md §5 が正本。workflow.md は結果参照のみ。data-model.md 側に「workflow.md は本セクションの結果を参照する」と相互参照を明記する。
- **RFC DG-6 整合**: cycle = state.json（JSON schema validation 対象）/ work item = Markdown frontmatter（並行編集コンフリクト回避）のハイブリッドを維持。
- **DG-5 整合**: core が依存する GitHub 機能は Issue / PR まで。complete 判定の PR merged 確認は core 範囲。Milestone / Projects / GitHub Release は data-model.md の core スキーマに含めない。

## 10. 成果物一覧マトリクス（フェーズ別 / §2 ディレクトリ構造の要否確定）

下表は **`depth_level: standard` を基準ケース**とした develop の成果物要否を示す（size 別）。**実際の要否は §8 の size × depth_level マトリクスが正本**であり、本表はその standard 列を成果物名で具体化したビューである。`depth_level: minimal` では §8 に従い design / review が省略されうる（例: `normal/minimal` は「実装 + テスト」のみで `designs/*.md` 不要）。`comprehensive` では risk-analysis 等が追加される。

| フェーズ（standard 基準） | 必須成果物 | 任意成果物 |
|---------|----------|----------|
| define | intent.md, work-items/*.md, state.json | stories.md, decisions.md |
| develop (tiny) | journal 追記 | - |
| develop (normal) | designs/*.md, reviews/*.md, journal 追記 | - |
| develop (risky) | designs/*.md, reviews/*.md, rollback-note.md, journal 追記 | risk-analysis.md（comprehensive で必須） |
| release | release.md, journal 追記 | changelog 追記 |
| reflect | reflect.md | Issue 作成 |

**§8 との整合**: 成果物要否の唯一の正本は §8（size × depth_level）。本 §10 は standard 列を成果物パスにマッピングしたビューに過ぎず、minimal / comprehensive では §8 の対応セルが優先する。data-model.md 執筆時は両表の参照関係（§8 = 正本 / §10 = standard ビュー）を明記する。

（計画書 "build (tiny/normal/risky)" は確定名 "develop" に補正。）

## 11. 完了条件への対応（unit-003-plan.md チェックリスト）

| 完了条件 | data-model.md での対応箇所 |
|---------|----------------------|
| data-model.md 作成 | 成果物が data-model.md のみ |
| v3 ディレクトリ構造 + 生成フェーズ | §2 + §10 |
| state.json schema（必須集合・型・schema_version・enum・書込タイミング/主体） | §3 |
| work item template（必須キー・enum・本文必須セクション） | §4 |
| フェーズ導出ロジック SoT（current_phase 非保持・complete 併用） | §5 |
| 破損・不正・矛盾時の扱い（doctor 検知 + 復帰可否方針 / validator 対象外） | §6 |
| journal 形式 + size×depth_level マトリクス | §7 + §8 |
| workflow.md と矛盾せず SoT 二重定義なし | §5 + §9 |
| コマンド名 develop 整合（build 不使用） | 全節（develop 統一・計画書 build を補正） |
| RFC DG-6 整合 | §3 + §9 |
| docs/v3 限定・コード非生成 | 成果物が data-model.md のみ |
| markdownlint | Phase 2 で実行 |
