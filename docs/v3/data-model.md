# AI-DLC v3 データモデル

- **ステータス**: Accepted（Unit 003 設計フェーズ承認済 / 2026-06-10）
- **対象サイクル**: v3.0.0-alpha.1
- **位置づけ**: v3 の状態管理（ディレクトリ構造・state.json schema・work item template・フェーズ導出ロジック・config.toml schema）の設計正本。**フェーズ導出ロジックの Single Source of Truth（SoT）**
- **入力**: `docs/v3/rfc.md`（Unit 001 確定 RFC: DG-6 state format = ハイブリッド）、`docs/v3/workflow.md`（Unit 002: 導出結果の参照元）、`docs/v3-renewal-plan.md`（データモデルセクション）
- **SoT 境界**: フェーズ導出ロジックの正本は本書（§5）。`workflow.md`（§2.3 ルーティング / §3.5 status / §3.6 doctor）は導出**結果**を参照し、導出規則そのものは再定義しない
- **スコープ外**: validator / state 操作スクリプトの実装（後続フェーズ）/ migration のデータ変換マッピング（`migration.md`・Unit 004）/ state format の選定理由（`rfc.md` DG-6）

---

## 1. 概要 / 目的

v3 はフェーズ進行を会話履歴の推論ではなく、リポジトリ内成果物への**明示的な状態書き込み**から導出する（RFC §1 / DG-6）。状態は責務に応じて 2 箇所に分散する（**ハイブリッド state format**）:

- **cycle state（`state.json`）**: サイクルレベルの状態（define 完了・release 状態）。書き込みが少なく、JSON schema validation と機械判定に適する。
- **work item state（各 `work-items/*.md` の Markdown frontmatter）**: work item 個別の状態。per-item で並行編集が起きるため、分散した frontmatter でコンフリクトを回避する。

この分散により、複数人が異なる work item を並行作業しても `state.json` がコンフリクトしない。フェーズを表す `current_phase` は状態として保持せず、`state.json` + work item frontmatter から常に導出する（§5）。

本書はディレクトリ構造（§2）、state.json schema（§3）、work item frontmatter / テンプレート（§4）、フェーズ導出ロジック（§5 / SoT）、破損・不正・矛盾時の扱い（§6）、journal 形式（§7）、size × depth_level マトリクス（§8）、整合方針（§9）、成果物一覧（§10）、config.toml schema（§11）を定義する。

---

## 2. ディレクトリ構造

```text
.aidlc/
  config.toml
  state.json                       (サイクルレベル状態 / リポジトリに 1 つ)
  cycles/
    v3.0.0/
      intent.md                    (define: 必須)
      work-items/
        001-example.md             (define: 必須 / 各 item の frontmatter が個別状態)
      designs/
        001-example.md             (develop: 要否は §8 size×depth_level が正本 / normal×minimal は不要)
      reviews/
        001-example.md             (develop の design/code review 成果物 / 要否は §8 が正本 / normal×standard 以上で生成)
      journal.md                   (全フェーズ: 追記)
      release.md                   (release: 必須)
      reflect.md                   (reflect: 任意)
```

各成果物の生成フェーズと要否は §10（成果物一覧マトリクス / 要否の正本は §8 size×depth_level）で確定する。`state.json` はリポジトリ直下（`.aidlc/state.json`）に置き、cycle ディレクトリ内には置かない。サイクルをまたぐ単一の現在状態として扱い、対象サイクルは `current_cycle` フィールドが指す。

---

## 3. state.json schema

`state.json` はサイクルレベルの状態のみを保持する。目的は (1) AI / script がサイクルレベルの状態を機械判定する、(2) フェーズ導出の最小入力を提供する、(3) doctor が schema validation できるようにする、の 3 点。

### 3.1 schema（確定例示）

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

### 3.2 フィールド定義

| フィールド | 型 | 必須 | 説明 |
|-----------|---|------|------|
| `schema_version` | string | Yes | schema バージョン（初版 `"3.0"`） |
| `current_cycle` | string | Yes | 対象サイクル識別子（例 `"v3.0.0"`） |
| `define_completed` | boolean | Yes | define 完了フラグ |
| `release` | object | Yes | release 状態（下記 3 サブフィールド） |
| `release.pr_number` | integer or null | Yes | PR 番号（未作成は `null`） |
| `release.ready` | boolean | Yes | PR ready 化フラグ |
| `release.merge_approved` | boolean | Yes | merge 承認記録（merge 済みではない） |
| `updated_at` | string (ISO 8601) | Yes | 最終更新時刻 |

### 3.3 書き込みタイミングと主体（single-actor moment）

`state.json` は書き込みタイミングを define 完了時・release 時に限定する（single-actor moment）。これにより並行作業中の書き込み競合を避ける。

| フィールド | 書き込みタイミング | 主体 |
|-----------|------------------|------|
| `define_completed` | define Step 4 完了時 | define 実行者 |
| `release.pr_number` | PR 作成時 | release 実行者 |
| `release.ready` | PR ready 化時 | release 実行者 |
| `release.merge_approved` | merge 承認時（merge 直前の最終コミット） | release 実行者 |

**`release.merge_approved` の意味**: 人間が「merge してよい」と承認したことの記録であり、merge 済みを意味しない。merge 後はブランチが消えるため、merge 前の最終コミットで書き込む。実際の merge 完了は PR の状態（merged）で判定する（§5）。

---

## 4. work item frontmatter + テンプレート

各 `work-items/*.md` の YAML frontmatter で work item 個別の状態を管理し、本文に trace 情報と作業内容を置く。

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
| `id` | string | Yes | work item 識別子（3 桁ゼロ埋め推奨） |
| `status` | enum | Yes | `pending` / `in_progress` / `blocked` / `done` / `withdrawn` |
| `size` | enum | Yes | `tiny` / `normal` / `risky` |
| `risk` | enum | Yes | `low` / `medium` / `high` |
| `assigned` | string or null | Yes | 担当者（並行作業時 / 未割当は `null`） |
| `dependencies` | array | Yes | 依存する work item ID のリスト（空配列可） |

**status enum**:

| 値 | 意味 |
|----|------|
| `pending` | まだ着手していない |
| `in_progress` | 作業中 |
| `blocked` | 外部依存等で待ち |
| `done` | 完了 |
| `withdrawn` | 取り下げ |

**size enum**:

| 値 | 意味 |
|----|------|
| `tiny` | typo / 軽微な単一ファイル修正 / 挙動リスク低 |
| `normal` | 通常の機能追加 / 小中規模リファクタ / docs + code 両方影響 |
| `risky` | release / migration / security / state model 変更 / 複数サブシステムまたがり |

**risk enum**:

| 値 | 意味 |
|----|------|
| `low` | 既存パターン踏襲、影響範囲が限定的 |
| `medium` | 一部新規、テストで担保可能 |
| `high` | 前例なし、または失敗時の復旧コストが高い |

### 4.2 本文必須セクション（テンプレート確定例示）

```markdown
---
id: "001"
status: pending
size: normal
risk: medium
assigned: null
dependencies: []
---

# Work Item 001: Example

## Goal

何を達成するか。

## Scope

- 含むもの
- 含まないもの

## Acceptance Criteria

- [ ] 条件 1
- [ ] 条件 2

## Traceability

- Intent refs: scope:example
- Acceptance refs: AC-001, AC-002
- Verification: test command or manual check
- Release note required: no

## Size / Risk

- Size: normal
- Risk: medium
- Reason: 理由

## Dependencies

- none

## Implementation Notes

必要な場合のみ記録。
```

本文の必須セクションは `Goal` / `Scope` / `Acceptance Criteria` / `Traceability` / `Size / Risk` / `Dependencies` の 6 つ。`Implementation Notes` は任意。work item の trace 情報（intent_refs / acceptance criteria / verification status 等）の正本は本ファイルに置き、`state.json` には持たせない（§9）。

---

## 5. フェーズ導出ロジック（SoT）

**本セクションがフェーズ導出規則の Single Source of Truth である**。`workflow.md`（§2.3 引数なしルーティング / §3.5 status / §3.6 doctor）は本セクションの結果を参照し、導出規則を再定義しない。

### 5.1 導出表

フェーズは `state.json` + work item frontmatter から導出する。`current_phase` は状態として保持しない。**評価順序は上から first-match。複数条件が同時成立しうるため、最も具体的な `complete` 条件を最初に評価する**:

| 評価順 | 条件 | 導出フェーズ |
|-------|-----|-----------|
| 1 | `release.merge_approved: true` かつ PR が merged 状態 | complete（reflect 可能） |
| 2 | `define_completed: false`（または `state.json` 不在） | define |
| 3 | `define_completed: true` かつ work item に `done` / `withdrawn` 以外がある | develop |
| 4 | `define_completed: true` かつ全 work item が `done` / `withdrawn`（評価順 1 に未該当） | release 可能 |

設計上の含意:

- 評価は first-match。`complete`（評価順 1）を最優先することで、「全 work item が done/withdrawn（評価順 4 = release 可能）」と「merge 済み（評価順 1 = complete）」が同時成立する状態でも一意に `complete` へ導出される。
- `develop → release` 遷移は「最後の work item を `done` にした作業者が自動的に release 可能状態を作る」ため、「誰がフェーズを変えるか」問題が発生しない。
- `complete` 判定は `release.merge_approved`（`state.json` の承認記録）と PR 実態（実際に merged か）の**両方**を要する。`merge_approved` 単独では complete としない。
- `state.json` 不在は define フォールバック（`workflow.md` §2.3 と整合）。

### 5.2 dependency 解決規則（develop の work item 選定）

work item 選定における依存解決を一意に定める（`workflow.md` §3.2「dependencies が全て done の候補を選定」を本セクションが正本化する）:

- **選定可能条件**: ある work item を develop 対象に選べるのは、その `dependencies` に列挙された全 work item の `status` が `done` の場合。
- **`withdrawn` 依存先の扱い**: 依存先が `withdrawn`（取り下げ）の場合、依存解決は自動では満たされない（`done` のみが自動充足）。`withdrawn` 依存先がある dependent item は、**人間判断で「依存解除（当該依存先を `dependencies` から除去）」または「dependent も `withdrawn`」のいずれか**を選ぶまで `blocked` 相当として進めない。
- **release 可能判定（§5.1 評価順 4）との関係**: サイクル全体の release 可能判定では `done` と `withdrawn` の**両方**を完了扱いとする（cycle 終端判定）。これは個別 work item の dependency 解決（`done` のみ自動充足 = item 選定）とは別レイヤの規則であり、両者は矛盾しない。

---

## 6. 破損・不正・矛盾時の扱い（方針レベル）

doctor が検知する破損パターンと復帰可否の**方針**を定める。doctor は `workflow.md` §3.6 のとおり**自動修正しない**（OK / WARN と Recommendations を出力するのみ）。validator / state 操作スクリプトの実装は本サイクル対象外であり、本セクションは方針レベルの確定に留める。

| パターン | 検知元（doctor チェック） | 復帰可否方針 |
|---------|-----------------------|------------|
| `state.json` 不在 | `[state]` | 復帰可（define にフォールバック。正常系の一部） |
| `state.json` が JSON parse 不能 | `[state]` | 復帰不可（WARN。手動修正を案内 / 自動修正しない） |
| `schema_version` 不一致 / 未知バージョン | `[state]` | 復帰不可（WARN。migration / 手動対応を案内） |
| 必須フィールド欠落（`define_completed` / `release` 等） | `[state]` | 復帰不可（WARN。診断のみ） |
| frontmatter 必須キー欠落 / enum 不正値 | `[work-items]` | 復帰不可（WARN。該当 work item を特定して報告） |
| `state.json` と frontmatter の矛盾（例: `define_completed: false` なのに `done` の work item が存在） | `[phase]` / `[work-items]` | 矛盾を WARN として報告。導出は安全側（define 継続可能側）に倒し、自動解決しない |
| `dependencies` に存在しない work item ID 参照 | `[work-items]` / `[trace]` | 復帰不可（WARN。trace 整合エラーとして報告） |
| `release.merge_approved: true` だが PR が未 merged | `[pr]` | complete としない（merge 承認と実態の不一致を WARN） |

**方針の原則**: doctor は状態を書き換えない。復帰可否は「導出フェーズが安全側に倒れるか（define / develop 継続可能か）」で判断し、判断不能な破損は人間に手動修正を促す。

---

## 7. journal 形式

`journal.md` は追記型の軽量記録（v2 の history より簡素）。

**目的**:

- 作業証跡を残す
- 全 step の詳細記録を義務化しない
- 次サイクルの define で参照可能にする

**形式**: 日付見出し（`## YYYY-MM-DD`）配下に箇条書きで追記する。

```markdown
# Journal: v3.0.0

## 2026-06-04

- define completed: intent and 3 work items created
- develop started: 001-example (size: normal)

## 2026-06-05

- develop completed: 001-example
- develop started: 002-normalize-state (size: tiny)
- develop completed: 002-normalize-state
- release ready: PR #123
```

---

## 8. size × depth_level マトリクス

`size` は per-work-item、`depth_level` は per-cycle のグローバル設定。両者は独立だが、組み合わせで実際の作業量が決まる。**本表が成果物要否の唯一の正本である**（§10 はその standard 列のビュー）。

**`depth_level` の保存場所**: `depth_level` は `.aidlc/config.toml` の設定キー（enum: `minimal` / `standard` / `comprehensive`、未設定時の既定値は `standard`）。サイクル単位で固定し、サイクル途中では変更しない。`size` が work item frontmatter（§4）に保存されるのに対し、`depth_level` は config.toml 側に置くため、成果物要否を判定する側（doctor / 後続 Unit 004 migration / validator）は **work item frontmatter の `size` × config.toml の `depth_level`** の組で本表を参照する。

> 注: v3 の config.toml キー全体の終端設計（キー数削減・キーパス命名）は **§11（config.toml schema）で確定済み**である。本節は size × depth_level マトリクスが参照する `depth_level` の保存場所・enum・既定値を確定し、§11 のキー #1（`rules.depth_level.level`）と整合する。

| | depth_level: minimal | depth_level: standard | depth_level: comprehensive |
|---|---|---|---|
| size: tiny | 実装のみ | 実装のみ | 実装 + 短い理由記録 |
| size: normal | 実装 + テスト | 実装 + 簡易 design + テスト + review | 実装 + design + リスク分析 + テスト + review |
| size: risky | （risky は minimal 不可） | design + テスト + review + rollback note | design + リスク分析 + テストプラン + 複数 review + rollback note |

---

## 9. trace 整合・RFC / workflow.md との整合

- **trace chain**: `intent.md` → `work-items/*.md`（frontmatter + 本文 Traceability）→ `designs/*.md` → `reviews/*.md` → `journal.md` → `release.md` → `reflect.md` → 次サイクル define input。work item の trace 情報の正本は各 `work-items/*.md` に置き、`state.json` はサイクルレベル状態（define 完了・release 状態）のみ保持する（`workflow.md` §7.3 と整合）。
- **SoT 二重定義回避**: フェーズ導出規則の本体は本書 §5 が正本。`workflow.md` は結果参照のみ。`workflow.md` §7.1 の導出表は「参考（正本は data-model.md）」と明記されており、本書 §5 がその正本である。
- **RFC DG-6 整合**: cycle = `state.json`（JSON schema validation 対象）/ work item = Markdown frontmatter（並行編集コンフリクト回避）のハイブリッドを維持する。
- **DG-5 整合**: core が依存する GitHub 機能は Issue / PR まで。`complete` 判定の PR merged 確認は core 範囲。Milestone / Projects / GitHub Release は本書の core スキーマに含めない。

---

## 10. 成果物一覧マトリクス（フェーズ別）

下表は **`depth_level: standard` を基準ケース**とした成果物要否を示す（§2 ディレクトリ構造の要否確定に対応）。**成果物要否の唯一の正本は §8（size × depth_level）**であり、本表はその standard 列を成果物パスにマッピングしたビューである。`depth_level: minimal` では §8 に従い design / review が省略されうる（例: `normal × minimal` は「実装 + テスト」のみで `designs/*.md` 不要）。`comprehensive` では risk-analysis 等が追加される。

| フェーズ（standard 基準） | 必須成果物 | 任意成果物 |
|---------|----------|----------|
| define | `intent.md`, `work-items/*.md`, `state.json` | `stories.md`, `decisions.md` |
| develop (tiny) | journal 追記 | - |
| develop (normal) | `designs/*.md`, `reviews/*.md`, journal 追記 | - |
| develop (risky) | `designs/*.md`, `reviews/*.md`, `rollback-note.md`, journal 追記 | `risk-analysis.md`（comprehensive で必須） |
| release | `release.md`, journal 追記 | changelog 追記 |
| reflect | `reflect.md` | Issue 作成 |

**review 成果物の保存先（develop と release の区別）**: `reviews/*.md` は **develop の work item レビュー（perspective = design / code）**の成果物のみを格納する（要否は §8）。release フェーズで実行される release-level review（perspective = premerge〔常時〕/ integration〔複数 work item 完了時〕/ deploy〔risky 時〕、`workflow.md` §3.3 / §6.1）の結果は **`release.md` に集約**し、`reviews/*.md` には残さない（PR コメント等は補助）。これにより release review が work item 単位の `reviews/*.md` と混在しない。

---

## 11. config.toml schema（v3 終端キー集合）

**本節が v3 `.aidlc/config.toml` の終端キー集合（キー名 / 型 / 既定値 / 用途）の唯一の正本である**（RFC §6.4 の委譲先 / v3.0.0-beta.3 work item 001 で確定）。v2 → v3 のキー変換**規則**は `migration.md` §3.1 が定義し、schema 本体は本節のみが定義する（SoT 二重定義回避）。

### 11.1 キー集合（8 キー）

キーパス命名は v2 互換の `[rules.<domain>]` 階層を維持する（リネームなし / 削減のみ）。v3 skeleton・doctor・共有 review 資産が既に v2 パス（`rules.depth_level.level` 等）を読んでおり、維持により migration の retained キーは identity mapping となる。

| # | キー | 型 | 既定値 | 用途 |
|---|------|----|--------|------|
| 1 | `rules.depth_level.level` | string enum（`minimal` / `standard` / `comprehensive`） | `"standard"` | size × depth_level マトリクス（§8）の cycle 側入力 |
| 2 | `rules.automation.mode` | string enum（`manual` / `semi_auto`） | `"manual"` | 承認ゲートの自動承認制御（`workflow.md` §5） |
| 3 | `rules.reviewing.mode` | string enum（`required` / `recommend` / `disabled`） | `"recommend"` | review 処理パス選択（routing_review_mode） |
| 4 | `rules.reviewing.tools` | array of string | `["codex"]` | review ツール優先順位（フォールバック順序） |
| 5 | `rules.reviewing.exclude_patterns` | array of string | `[]` | review 時の機密情報除外パターン |
| 6 | `rules.release.changelog` | bool | `false` | release の changelog 追記 opt-in |
| 7 | `rules.release.version_tag` | bool | `false` | release の tag 作成 opt-in（extension 相当 / 既定 off / RFC DG-5 整合） |
| 8 | `rules.release.required_ci_zero_fallback` | bool | `false` | required CI 0 件時の release hard gate フォールバック opt-in（#745） |

### 11.2 採用基準・整合

- **採用基準**: v3 フェーズフロー（steps）または委譲先共有資産が現に参照する**挙動制御キー**のみを残す。v2 の情報フィールド・v2 固有機能キー（feedback / retrospective / git 細粒度制御 / inception / linting / cycle / version_check / construction / documentation / github 等の 27 キー）は終端集合に含めない（v2 34 − 維持 7 = drop 27 / v3 新規 1 を加えて終端 8）。
- **RFC §6 整合**: 本節により RFC §6.4 の終端値の揺れ（8 か 12 か）は **8 で確定**する（削減率 34 → 8 = ~76% / RFC §6.2 と整合）。
- **未知キーの扱い**: v3 は本節にないキーを**無視する**（エラーにしない / `migration.md` 非互換点 #3 と整合。migration 実行時は警告を出す）。
- **`required_ci_zero_fallback` の発動形態**: config フラグは**経路の解放**のみを担い、実際のフォールバック発動時には別途**ユーザー承認 + release.md / journal への記録**を必須とする（既定 `false` = 現行 fail-closed 挙動不変。承認手順の詳細は release フロー側で定義する / #745）。
- **共存期間の注記**: v3 が一時的に委譲する v2 共有資産（`review-flow.md` / `review-routing.md` 等）が参照する v2-only キー（例: `rules.reviewing.codex_bot_account`）は本 schema に含めない。不在時は各資産の文書化された既定値へフォールバックし、review 統合（9→1 `aidlc-review`）で解消する。
- **defaults.toml 実体化**: 本 schema を既定値として持つ v3 defaults.toml の実体ファイルはローダー実装側（本流化フェーズ）で配置する。本節は schema 定義のみを確定する。
