# 論理設計: Unit 004 §1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証

## 概要

Unit 004 ドメインモデル（`TryLoopCreationStrategy` / `AggregatedCreationStrategy` / `SectionComposer` / `TIssueGroupSearchService` / `PredecessorResolutionDecider`）の論理実装。**改修は 3 つの物理境界に限定**:

1. `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 4 を分岐 + Try ループ化（4A）
2. `skills/aidlc/templates/retrospective_template.md` の Try セクションを 5 必須見出し構造に再構成（4A）
3. `skills/aidlc/scripts/lib/predecessor-issue.sh` の `_pure_classify_resolution_path` と `predecessor_resolve_issue` に warn_continue 直前の後段経路 2 サブ分岐を追加（4B）

公開シンボル（`retrospective-api.sh` の Facade）は **完全不変**。本 Unit はすべて利用側コード変更で完結し、新規 lib ファイルや新規公開関数は追加しない。

**重要**: 本論理設計では **コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。

---

## ステップ0 事前コード読込み

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 4 周辺（L324-380）+ aggregate_issue_enabled 説明（L219-241）| (i) Step 4 既存 5 段階フロー（dialog token → cap → create → update）の遷移境界 / (ii) `retrospective_api_aggregate_enabled` 分岐の挿入位置 を踏襲するため |
| `skills/aidlc-retrospective/steps/retrospective.md` §1.2.5 セルフレビュー（L151-188）| `retrospective_api_record_selfreview` のフォーマットを参照し「構造課題昇格根拠」自動転記の入力源を特定するため |
| `skills/aidlc/scripts/lib/retrospective-api.sh` | 既存 Facade 公開関数（`retrospective_api_create_issue` / `retrospective_api_check_cap` / `retrospective_api_aggregate_enabled` / `retrospective_dialog_token_verify` / `retrospective_api_ensure_label` / `retrospective_api_record_response`）の引数 / stdout / exit code を踏襲するため |
| `skills/aidlc/scripts/lib/predecessor-issue.sh`（`_pure_classify_resolution_path` L67-100 と `predecessor_resolve_issue` L290-349）| (i) 既存 5 経路の評価順序 / (ii) NDJSON 出力契約 / (iii) `__pred_gh_query` パターン / (iv) `_local_<関数省略名>_<名>` 命名規約 を踏襲するため |
| `skills/aidlc/templates/retrospective_template.md`（L25-31 Try 表）| 既存 Try セクションの構造から 5 必須見出し構造への差分予測のため |
| `tests/predecessor-issue-handoff.bats` / `tests/retrospective-issue-create.bats` / `tests/retrospective-aggregate-enabled.bats`（既存）| bats fixture / gh CLI mock / dialog token bypass パターン参照 |
| `.aidlc/cycles/v2.6.5/`（旧サイクル成果物 + 振り返り Issue 情報）| 旧サイクル fixture（経路 1 `milestone_and_label` 維持）の構造確認 |
| `CLAUDE.md` 「AI エージェント Bash ツール経由の安全パターン」「printf -v 系 result-out 関数の local 命名規約」| コマンド置換禁止 / dynamic scope shadowing 回避規約遵守 |

### (b) 設計時に意識すべき挙動

- `retrospective_api_create_issue` の契約は **1 呼び出し = 1 起票** であり、Try ループ化は呼出側（`steps/retrospective.md` §1.5 Step 4）で N 回反復する形を取る（API 内部 loop 化は禁止）
- `retrospective_dialog_token_verify` は cycle 単位の対話確認トークンを受け取り、TTL 300 秒以内で複数回検証可能。各 T 起票直前に検証することで N ≤ cap でも 300 秒以内完走できる
- `retrospective_api_check_cap` の cap モードは Unit 001 で `t_issue_loop` / `aggregate` の 2 モードを取れるよう SoT 化済（本 Unit は `t_issue_loop` モードを既定で利用）
- predecessor の純粋関数 `_pure_classify_resolution_path` は **引数だけで `resolution_path` を決定する** 設計のため、新経路追加は (i) 引数追加 (ii) case 分岐追加 の 2 点で済む（既存 5 経路の引数バインディングは変更しない）
- 既存 5 経路の `candidates_json` ソートは closedAt 降順だが、新経路では OPEN T Issue（closedAt = null）が混入し得るため、null 安全ソート（null を末尾、または除外）が必要
- 5 セクション非空保証は (i) build 時に空セクションを生成しない (ii) build 後に validate して invalid なら起票せず warn の 2 段防御。明示的「該当なし」記載は非空扱い（false positive 防止）

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `api-internal-loop` Facade に loop 関数追加 | `retrospective_api_create_issue_loop` を新設し API 内部で N 回 loop | **却下** | (i) 既存 Type B 関数の「1 呼び 1 起票」契約を破壊 (ii) cap / dialog token / exit 4 短絡が API 内に多重化して回復ロジックが複雑化 (iii) Unit 001 が API シグネチャ不変を SoT 化済 |
| `caller-loop` 呼出側 (`steps/retrospective.md`) で N 回反復 | Step 4 を分岐 + ループ化。`retrospective_api_create_issue` は契約不変で個別呼出 | **採用** | (i) Facade 契約完全不変 (ii) 既存 dialog token / cap / update フックが各回独立で動作 (iii) ループ各回の独立性が自然に保たれる |
| `predecessor-restructure` 既存 5 経路を新動作経路に統合 | `_pure_classify_resolution_path` を refactor し 5 経路 + 新経路を統一決定木に再編 | **却下** | Intent §「明示的に除外するもの」で「`predecessor_resolve_issue` の経路再設計は v2.7.0+ defer」と明示 |
| `predecessor-append-only` warn_continue 直前に後段追加 | 既存 5 経路の引数 / 評価 / 出力は完全不変。新経路 2 サブ分岐のみを `_pure_classify_resolution_path` に追加 | **採用** | (i) 既存 5 経路の構造的不変保証 (ii) 旧サイクル fixture は経路 1 で resolve され新経路に到達しない (iii) 新経路 0 件時は warn_continue がそのまま機能 |
| `template-dual` 新旧 2 テンプレ並立 | `retrospective_template.md`（新 / T ループ用）と `retrospective_template_aggregate.md`（旧 / 集約用）を分離 | **却下** | Intent §「テンプレ改修は本 Unit で実施」と単一テンプレ前提で書かれている / `aggregate_issue_enabled` 分岐は呼出側で完結する |
| `template-conditional` 単一テンプレに 5 セクション + 集約用ブロックを同居 | テンプレ内で見出し階層を h3 → h4 へ引き上げ、各 Try ごとに 5 必須セクションを展開。集約用フォーマットは既存表構造を別ブロックとして残置 | **採用** | (i) テンプレ単一性維持 (ii) 集約 opt-in 時の旧構造は別ブロック参照で互換維持 (iii) ループ起票時のみ 5 セクション部分を反復 |

---

## アーキテクチャパターン

- **Strategy Pattern**: §1.5 Step 4 が `aggregate_issue_enabled` で `AggregatedCreationStrategy`（旧）/ `TryLoopCreationStrategy`（新）を切り替え
- **Append-Only Decision Tree Extension**: predecessor `_pure_classify_resolution_path` の決定木に warn_continue 直前で新ブランチ 2 つを追加（既存ブランチは介入なし）
- **Facade Preservation**: 公開シンボル不変。本 Unit は利用側コードのみを改修
- **Template Composition with Required Section Set**: テンプレ内に 5 必須見出し集合を SoT として配置、Try ごとにスケルトンを反復展開
- **Dependency Direction**: `steps/retrospective.md` → `retrospective-api.sh` Facade → 既存 lib（変更なし） / `predecessor-issue.sh` 内部のみで完結（外部依存追加なし）

選定理由: 既存 5 経路 / Facade 公開シグネチャの後方互換を構造で保証しつつ、新動作（Try ループ + 新 predecessor 経路）を **後段追加のみで** 達成する。

---

## コンポーネント構成

### コンポーネント一覧

| コンポーネント | 物理位置 | 種別 | 公開境界 | 責務 |
|--------------|---------|------|---------|------|
| §1.5 Step 4 分岐ブロック | `skills/aidlc-retrospective/steps/retrospective.md` L324-380 周辺 | 改修（在来ファイル） | AI エージェント実行手順（プロンプト） | `aggregate_issue_enabled` で `AggregatedCreationStrategy` / `TryLoopCreationStrategy` を切替 |
| §1.5 Step 4 Try ループ起票本体 | 同上（新規セクション） | 追加（在来ファイル内） | AI エージェント実行手順 | Try 件数分のループで dialog token / cap / create / update を反復実行 |
| `SectionComposer` 指示ブロック | 同上（新規セクション） | 追加（在来ファイル内） | AI エージェント実行手順 | 5 必須セクション本文を組み立てる手順を AI エージェントに明示 |
| Try セクションテンプレ（5 必須見出し構造） | `skills/aidlc/templates/retrospective_template.md` L25-31 周辺 | 改修 | テンプレ（プロンプト埋込） | 1 Try = 1 Issue 単位の 5 必須見出しスケルトンを SoT 化。テンプレ内 HTML コメントマーカー `<!-- BEGIN: try_loop_block -->` 〜 `<!-- END: try_loop_block -->` で囲む |
| 集約用 Try セクションテンプレ（旧構造） | 同上（別ブロック） | 改修 | テンプレ（プロンプト埋込） | `aggregate_issue_enabled = true` 時用に既存表構造を別ブロックとして保持。テンプレ内 HTML コメントマーカー `<!-- BEGIN: aggregate_block -->` 〜 `<!-- END: aggregate_block -->` で囲む |
| `_pure_classify_resolution_path` 後段拡張 | `skills/aidlc/scripts/lib/predecessor-issue.sh` L67-100 | 改修（既存関数） | 純粋関数（内部）| warn_continue 直前で新経路 2 サブ分岐の評価を追加。既存 5 経路は引数 / 評価 / 出力すべて不変 |
| `predecessor_resolve_issue` case 分岐拡張 | 同上 L290-349 | 改修（既存関数） | 公開関数（既存）| `t_issue_milestone_scope` / `t_issue_label_fallback` の case を warn_continue 直前に追加 |
| `TIssueGroupSearchService` 内部 helper | 同上（新規 internal 関数） | 追加（既存ファイル内） | 内部（既存命名規約準拠） | `gh issue list --label retrospective [--milestone <ms>]` を実行し candidates を null 安全ソート |
| bats テスト群（4A） | `tests/retrospective-issue-loop-create.bats`（新規） | 追加 | テスト | 起票件数観測 / 5 見出し非空 / cap 境界 |
| bats テスト群（4B） | `tests/predecessor-issue-t-loop.bats`（新規）+ 既存 `predecessor-issue-handoff.bats` 拡張 | 追加 + 改修 | テスト | 5 経路回帰 / 新動作経路 2 サブ分岐 / 旧サイクル維持 |

### 物理ファイル構成（差分）

```text
skills/aidlc-retrospective/
└── steps/
    └── retrospective.md  (改修: §1.5 Step 4 を分岐 + Try ループ化、SectionComposer 手順追加)

skills/aidlc/
├── templates/
│   └── retrospective_template.md  (改修: Try セクションを 5 必須見出し構造に再構成 + 集約用旧構造を別ブロック化)
└── scripts/
    └── lib/
        └── predecessor-issue.sh  (改修: _pure_classify_resolution_path 後段拡張 + predecessor_resolve_issue case 拡張 + 内部 helper 追加)

tests/
├── retrospective-issue-loop-create.bats  (新規: 4A)
├── predecessor-issue-t-loop.bats         (新規: 4B 新動作 + 旧サイクル維持)
└── predecessor-issue-handoff.bats        (改修: 既存 5 経路回帰の bats 化補強)
```

新規追加: bats 2 ファイル / 既存改修: steps × 1 + templates × 1 + scripts/lib × 1 + bats × 1。

---

## インターフェース定義

### §1.5 Step 4 分岐ロジック（AI エージェント実行手順）

```text
INPUT  : cycle_id, try_drafts (List<TryDraft>), verdict_map (Map<try_id, SelfReviewVerdict>)
OUTPUT : creation_summary { strategy, created_count, skipped_count, cap_reached }

DECISION:
  enabled := retrospective_api_aggregate_enabled  # stdout: "true" | "false"
  if enabled == "true":
    invoke AggregatedCreationStrategy (existing flow, v2.6.5 と diff 0)
    # 備考: AggregatedCreationStrategy は verdict_map を使わない（旧フロー互換のため使用箇所なし）
  else:
    invoke TryLoopCreationStrategy(cycle_id, try_drafts, verdict_map)
```

### `TryLoopCreationStrategy`（AI エージェント実行手順）

```text
INPUT  : cycle_id, try_drafts (List<TryDraft>), verdict_map (Map<try_id, SelfReviewVerdict>)
PROCESS:
  1. retrospective_api_record_response  cycle_id <dialog_response>    # cycle 単位対話確認トークン発行
  2. for each try in try_drafts:
       2.1 cap := retrospective_api_check_cap t_issue_loop <current_count> <limit>
           if cap.over == true:
             warn(cap_reached) + skipped_count.cap_reached += (try_drafts.size - current_index)
             break    # 残 Try 一括停止（仕様確定）
       2.2 retrospective_dialog_token_verify <cycle_id>
           if exit 4:
             warn(dialog_required) + skipped_count.dialog_required += (try_drafts.size - current_index)
             break    # 残 Try 一括停止
       2.3 verdict := verdict_map[try.try_id]    # Try 単位 verdict lookup
       2.4 ti_draft := SectionComposer.compose(try, verdict, cycle_id, kp_entries)
       2.5 validation := ti_draft.validateSectionsNonEmpty()
           if validation.verdict != "pass":
             warn(section_invalid) + retrospective_api_ensure_label selfreview-incomplete
             skipped_count.section_invalid += 1
             continue    # 当該 1 件のみ skip（残 Try 継続）
       2.6 retrospective_api_create_issue <body_path> t_issue_loop <cycle_id>
       2.7 if verdict.verdict == "capped":
             retrospective_api_ensure_label selfreview-capped (当該 Issue に付与)
       2.8 (optional) retrospective_api_update_issue (既存 update フック)
  3. return creation_summary { created_count, skipped_count: { cap_reached, dialog_required, section_invalid }, cap_reached: bool }
```

**制御フロー仕様の確定** (R1 指摘 #3 対応):

| 中断要因 | 制御 | skipped_count 計上規則 |
|---------|------|---------------------|
| cap 到達 | `break`（残 Try 一括停止） | `cap_reached += 残 Try 件数` |
| dialog token 失敗（exit 4） | `break`（残 Try 一括停止） | `dialog_required += 残 Try 件数` |
| 5 セクション validate 失敗 | `continue`（当該 1 件のみ skip） | `section_invalid += 1` |

### `SectionComposer.compose`（手順テンプレ）

```text
INPUT  : try (TryDraft), verdict (SelfReviewVerdict, 当該 Try の単数 verdict / caller が verdict_map[try.try_id] で lookup 済), cycle_id, kp_entries
OUTPUT : ti_draft (TIssueDraft) with body containing 5 必須見出し

BUILD ORDER (固定):
  ## 背景         <- kp_entries (related K/P 要旨) | 補完不能なら「該当なし（関連 KP 未指定）」
  ## 主因切り分け  <- §1.2 マトリクスの当該行から (3 分類 + 根拠) | 補完不能なら「該当なし（主因切り分け未記録）」
  ## 構造課題昇格根拠 <- verdict.responses の {A: yes|no, B: yes|no, C: yes|no} を選択肢ラベル形式で列挙 + verdict.verdict
  ## 想定対策     <- try.summary_line + try.priority + try.target
  ## 関連         <- cycle_id / milestone link / (aggregate_enabled=true のみ "Relates: #<集約>")

TITLE:
  title := "[Retrospective: " + cycle_id + "] " + try.extractTitleSeed()
```

### `_pure_classify_resolution_path` 後段拡張（純粋関数 / Bash）

```text
INPUT  : milestone_enabled, gh_available, ml_count (legacy_5_routes 集計済), label_count (新動作 ml_query 集計済),
         t_milestone_count, t_label_count, spool_path, compat_file
OUTPUT : resolution_path (string)

DECISION (順序 / 既存 5 経路は不変):
  if gh_available && milestone_enabled && ml_count >= 1: return "milestone_and_label"
  if gh_available && !milestone_enabled && label_count >= 1: return "label_fallback"
  if spool_path exists: return "spool_fallback"
  if compat_file exists: return "v2_5_0_compat"
  # ↑ ここまで完全不変
  # ↓ 新規 (4B): warn_continue 直前
  if gh_available && t_milestone_count >= 1: return "t_issue_milestone_scope"
  if gh_available && t_label_count >= 1: return "t_issue_label_fallback"
  return "warn_continue"
```

不変条件:
- 既存 5 経路（milestone_and_label / label_fallback / spool_fallback / v2_5_0_compat / warn_continue）の条件式・戻り値文字列は v2.6.5 と完全一致
- 新経路 2 つは既存 5 経路が「ヒットしなかった場合のみ」評価される
- warn_continue は新経路 2 つも 0 件の場合のみ到達（新経路追加で warn_continue の発火条件は厳格化されるが、戻り値文字列・後段処理は不変）

### `predecessor_resolve_issue` case 拡張（既存関数の追加分のみ）

```text
ADD CASES (warn_continue case の直前に挿入):
  "t_issue_milestone_scope")
      candidates_json := TIssueGroupSearchService.search(label=retrospective, milestone=<ms>)
      emit NDJSON { resolution_path: "t_issue_milestone_scope", candidates: candidates_json, ... }
      ;;
  "t_issue_label_fallback")
      candidates_json := TIssueGroupSearchService.search(label=retrospective, milestone=nil)
      emit NDJSON { resolution_path: "t_issue_label_fallback", candidates: candidates_json, ... }
      ;;
```

不変条件:
- 既存 5 case の処理体は変更しない
- NDJSON 出力フィールドは既存と同一 schema（`resolution_path` / `candidates` / `issue_url`（新経路では使わない）/ ...）

### `TIssueGroupSearchService.search`（internal helper / Bash）

```text
INPUT  : label (string, 既定 "retrospective"), milestone (string|nil)
OUTPUT : candidates_json (JSON array, closedAt 降順 / null は末尾)

PROCESS:
  1. args := ["issue", "list", "--label", label, "--json", "url,title,closedAt,number"]
     if milestone: args += ["--milestone", milestone]
  2. raw := __pred_gh_query args
  3. sorted := raw | jq 'sort_by((.closedAt // "")) | reverse'
     # null → 空文字置換で昇順時に先頭、reverse 後は末尾に配置（R1 指摘 #2 対応）
     # 検証: 昇順 [null="", "2025-01-01", "2025-12-31"] → reverse [latest, earlier, null] → null 末尾
  4. return sorted
```

不変条件:
- 既存 `__pred_gh_query` の呼び出しパターンを踏襲（gh CLI を直接呼ばない）
- 既存 5 経路の candidates 構築ロジックを変更しない

---

## テンプレ選択ルール（R1 指摘 #4 対応）

`retrospective_template.md` には Try セクション用に 2 ブロックを HTML コメントマーカーで明示分離する:

```text
<!-- BEGIN: try_loop_block -->
（5 必須見出し構造: ## 背景 / ## 主因切り分け / ## 構造課題昇格根拠 / ## 想定対策 / ## 関連）
<!-- END: try_loop_block -->

<!-- BEGIN: aggregate_block -->
（既存表構造: 優先度 | 施策 | 反映先）
<!-- END: aggregate_block -->
```

### テンプレ選択インターフェース

| `aggregate_issue_enabled` | 選択ブロック | 適用フロー |
|---------------------------|--------------|-----------|
| `false`（既定） | `try_loop_block` | `TryLoopCreationStrategy` が各 Try に対してブロックスケルトンを反復展開 |
| `true`（opt-in） | `aggregate_block` | `AggregatedCreationStrategy` が単一展開（v2.6.5 と diff 0 構造） |

### 不変条件

- 両ブロックは **テンプレ内で常に共存** する（実装側でフラグに応じて参照ブロックを切り替える）
- マーカー文字列は固定（変更時は本ファイル + テンプレ + steps/retrospective.md の 3 点を同期改訂）
- 旧 fixture との diff 0 は `aggregate_block` 内の構造が v2.6.5 と一致することで保証される
- caller（`steps/retrospective.md`）はマーカーを正規表現または sed で抽出し、対応するブロックのみを Issue 本文構築に使う

---

## API 設計

本 Unit は **公開 API を追加しない**（Unit 001 / 002 / 003 で公開された Facade 関数の利用側変更のみ）。

利用する公開 API 一覧（既存 / シグネチャ不変）:

| Facade 関数 | 用途 | 呼出元 |
|------------|------|-------|
| `retrospective_api_aggregate_enabled` | 4A: §1.5 Step 4 冒頭の分岐判定 | steps/retrospective.md |
| `retrospective_api_check_cap t_issue_loop <current> <limit>` | 4A: 各 T 起票直前の cap 判定 | steps/retrospective.md |
| `retrospective_dialog_token_verify <cycle_id>` | 4A: 各 T 起票直前の dialog token 検証 | steps/retrospective.md |
| `retrospective_api_record_response <cycle_id> <response>` | 4A: cycle 単位 1 回の対話確認トークン記録 | steps/retrospective.md |
| `retrospective_api_create_issue <body_path> t_issue_loop <cycle_id>` | 4A: 各 T 起票の本体 | steps/retrospective.md |
| `retrospective_api_ensure_label <label>` | 4A: `selfreview-capped` / `selfreview-incomplete` のラベル付与 | steps/retrospective.md |
| `retrospective_api_evaluate_selfreview_verdict` | 4A: `SectionComposer` の verdict 取得（read のみ） | steps/retrospective.md |
| `predecessor_resolve_issue` | 4B: 集約 Issue 不在時の resolve（呼出側は本 Unit では変更なし、内部実装のみ拡張） | 外部呼出元（aidlc-feedback 等） |

---

## 後方互換の論理保証

| 観点 | 保証手段 | 検証 |
|------|---------|------|
| `aggregate_issue_enabled = true` で旧 §1.5 Step 4 と diff 0 | Strategy 分岐で旧フローをそのまま起動（コード変更なし） | bats `retrospective-aggregate-enabled.bats` 既存 + Unit 001 同等性 fixture |
| 既存 5 経路の `resolution_path` 戻り値 / NDJSON が v2.6.5 と一致 | `_pure_classify_resolution_path` の既存条件式は完全不変 | bats `predecessor-issue-handoff.bats` 拡張（5 経路の期待値テーブル化） |
| 旧サイクル振り返り（集約 Issue 1 件あり）が経路 1 で resolve される | 既存条件式 `milestone_enabled && ml_count >= 1` で 0 件にならない fixture を使用 | bats `predecessor-issue-t-loop.bats` 新規旧サイクル fixture |
| `retrospective_api_create_issue` の契約（1 呼び 1 起票 / exit 4 = dialog-required） | 本 Unit は呼出元 loop 化のみ。API 内部は変更なし | 既存 `retrospective-issue-create.bats` regression なし |

---

## 5 セクション非空保証の論理設計

### 補完優先順位（補完不能時は明示「該当なし」記載で非空扱い）

| セクション | 一次入力 | 二次補完（一次取得不能時） | 最終フォールバック |
|----------|---------|------------------------|--------------------|
| `## 背景` | TryDraft.related_kp 要旨 | KPT テンプレ全体から該当 K/P を fuzzy match | `該当なし（関連 KP 未指定）` |
| `## 主因切り分け` | §1.2 マトリクスの該当行 | §1.2 マトリクス全体から fuzzy match | `該当なし（主因切り分け未記録）` |
| `## 構造課題昇格根拠` | SelfReviewVerdict.responses + verdict | history/operations.md から直近 selfreview ログ read | `該当なし（セルフレビュー未実施）` |
| `## 想定対策` | TryDraft.summary_line + priority + target | （フォールバックなし、原文必須） | （補完不能なら起票自体を skip + warn） |
| `## 関連` | cycle_id + milestone link | cycle_id のみ | `該当なし（関連リンク未指定）` |

### validate ロジック

- `validateSectionsNonEmpty` は各見出し配下の **空白行・コメントのみを除外した実質本文行** が 1 行以上あるか判定
- 「該当なし」明示記載（行頭が `該当なし` で始まる）は **非空扱い** とする（false positive 防止）
- validation.verdict = `pass` でない場合、`retrospective_api_create_issue` を呼ばず `selfreview-incomplete` ラベル warn + skip

---

## 非機能要件（NFR）

| 観点 | 目標 | 検証方法 |
|------|------|---------|
| パフォーマンス | T 件数 N に対し O(N) 起票時間 / dialog token TTL 300 秒内に N ≤ cap の起票完走 | bats `retrospective-issue-loop-create.bats` で N=cap_default 5 件を 300 秒以内完走測定 |
| セキュリティ | T Issue 本文に機密情報を含めない | 既存 `retrospective_api_create_issue` 内の機密スキャン経路を維持 / 5 セクション補完時に追加マスクは行わない（既存挙動を維持） |
| 後方互換性 | `aggregate_issue_enabled = true` 時に v2.6.5 fixture と差分 0 | Unit 001 同等性オラクル fixture 再 pass |
| 可用性 | cap 上限到達時の追加起票拒否動作が新旧両仕様で正しく機能 | bats cap 境界テスト（N 件目 OK / N+1 件目拒否）両モード |

---

## テスト戦略

### bats テストケース（4A: `retrospective-issue-loop-create.bats`）

1. **起票件数観測 - 既定動作**: `aggregate_issue_enabled = false` で N=3 の Try → 集約 Issue 0 件 + T Issue 3 件
2. **起票件数観測 - opt-in**: `aggregate_issue_enabled = true` で N=3 → 集約 Issue 1 件 + T Issue 0 件
3. **5 見出し非空（正常系）**: 5 見出しすべて非空 → 起票成功
4. **5 見出し非空（陰性 1 見出し空）**: 1 見出しでも空 → skip + `selfreview-incomplete` ラベル
5. **5 見出し非空（陰性 全空）**: 全空 → skip + warn
6. **「該当なし」明示記載 = 非空扱い**: `## 背景` が `該当なし` のみ → 起票成功（false positive 防止）
7. **cap 境界（N 件目 OK）**: cap=5 で 5 件起票成功
8. **cap 境界（N+1 件目拒否）**: cap=5 で 6 件目 → skip + cap_reached warn
9. **dialog token 失敗時のループ中断**: 2 件目で exit 4 → 1 件起票成功 + ループ全停止
10. **タイトル生成（80 字 truncate）**: 100 字の summary → 80 字 + cycle prefix
11. **タイトル生成（引用記号除去）**: `> text` → `text`

### bats テストケース（4B: `predecessor-issue-t-loop.bats`）

12. **新動作 `t_issue_milestone_scope`**: 集約 0 件 + 同 milestone 内 retrospective ラベル T Issue 3 件 → `resolution_path=t_issue_milestone_scope` / `candidates` ≥ 1
13. **新動作 `t_issue_label_fallback`**: 集約 0 件 + milestone 無 + retrospective ラベル T Issue 2 件 → `resolution_path=t_issue_label_fallback` / `candidates` ≥ 1
14. **closedAt null 安全ソート**: T Issue が OPEN（closedAt=null）と CLOSED 混在 → CLOSED 降順 → OPEN（null）が末尾
15. **旧サイクル維持（集約 1 件あり）**: 旧サイクル fixture（`Retrospective: v2.6.5` 集約 Issue 1 件）→ `resolution_path=milestone_and_label` / 新経路に到達しない
16. **既存 5 経路すべて 0 件 + 新経路 0 件 → warn_continue**: 何もヒットしない fixture → `warn_continue` 維持

### bats テストケース（既存改修 `predecessor-issue-handoff.bats`）

17-21. **既存 5 経路の `resolution_path` 期待値テーブル**: `milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue` それぞれの陽性 fixture で期待値一致を確認（v2.6.4 Unit 004 の手動再現を bats 化）

---

## 設計上の不変条件まとめ

1. **Facade 公開シグネチャ完全不変**: `retrospective-api.sh` の関数追加・引数変更・stdout 変更を行わない
2. **既存 5 経路完全不変**: `_pure_classify_resolution_path` の既存条件式・戻り値文字列・既存 case 処理体を変更しない
3. **後方互換**: `aggregate_issue_enabled = true` で v2.6.5 と完全一致 / 旧サイクル fixture で経路 1 維持
4. **5 セクション非空保証**: validate fail 時は起票せず skip（部分起票禁止）
5. **dialog token 維持**: 各 T 起票で dialog token 検証経由 / exit 4 でループ中断
6. **AI 透過性**: ループ各回でユーザー対話を介在させない（cycle 単位 1 回の対話確認のみ）
