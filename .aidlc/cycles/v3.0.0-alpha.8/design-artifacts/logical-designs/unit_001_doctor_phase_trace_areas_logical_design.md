# 論理設計: Unit 001 doctor `[phase]` / `[trace]` 領域

## 概要

doctor.sh に `diagnose_phase` / `diagnose_trace` の 2 関数を追加し、既存の順序実行ブロック・wrap 契約・exit code 集約へ統合する論理設計。契約テスト（test-doctor.sh）の拡張方針も定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコードは Phase 2 で作成する。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

ドメインモデル「ステップ0」と共通の読込みを前提としつつ、本論理設計（関数分割・順序統合・テスト設計）の判断根拠となる観点を以下に記す。

### (a) Read 対象ファイル + 目的

| ファイル | 論理設計上の Read 目的 |
|---------|----------------------|
| `skills/aidlc-v3/scripts/doctor.sh` | 順序実行ブロック（356-364 行目）・グローバル宣言位置（`STATE_PRESENT`:123 / `CYCLE_DIR`:158 / `GH_AVAILABLE`:267）・`diagnose_gh`(268-283) / `diagnose_pr`(289-306) の相対順を把握し、新領域 2 関数の挿入位置と `GH_AVAILABLE` 依存の解決順序を確定する |
| `skills/aidlc-v3/scripts/state-read.sh` | `release.pr_number`(48-50) の許容フィールド化と明示 null の `"null"` 出力（96-98 行目）を確認し、complete 判定の入力取得インターフェースを設計する |
| `skills/aidlc-v3/scripts/lib/frontmatter.sh` | `fm_extract_block`(64-67) + `fm_scalar`(83-102) の loose 抽出契約を確認し、work item の status/size 取得を新規パースなしで設計する |
| `skills/aidlc-v3/scripts/work-item-validate.sh` | size/status enum 不正を exit 1（ERROR）にする（143 行目で `in_list` により `SIZE_ENUM` 照合し不一致は exit 1）ことを確認し、trace/phase の enum 不正責務を `[work-items]` gate に集約する設計判断（レビュー#3）の根拠とする |
| `skills/aidlc-v3/scripts/tests/test-doctor.sh` | `build_fixture` / `make_valid_state` / `make_valid_work_item` / `assert_area`(領域名 grep = 順序非依存) / jq 注入を確認し、新領域テストを既存ハーネスで設計する |

### (b) 設計時に意識すべき挙動

- `diagnose_phase` は complete 確認で `GH_AVAILABLE` を参照するため、**`diagnose_gh` より後に実行される順序が必須**。既存順序では `diagnose_gh` / `diagnose_pr` は work-items の後にある（356-364 行目）。
- `assert_area`（test-doctor.sh）は領域名で grep するため、関数の出力順を変えてもテストは非破壊。
- `work-item-validate.sh` は size enum 不正を ERROR にする（143 行目）。そのため `WORK_ITEMS_INVALID` gate が invalid work item を捕捉した後に trace/phase が走る限り、size enum 不正入力は trace/phase に到達しない。
- `state-read.sh` は明示 null を `"null"` で出力し exit 0、フィールド欠落は exit 1。pr_number 未作成は null。

### (c) 既存実装に基づく代替案検討（論理設計レベル）

| 論点 | 候補 | 採否 |
|------|------|------|
| 新領域の挿入位置 | (i) work-items 直後 / (ii) **`diagnose_pr` 直後**（gh/pr の後） | (ii) 採用。`GH_AVAILABLE` 依存を満たしつつ既存関数を一切移動せず 2 関数を挿入するだけで済み、最小差分かつ矛盾のない順序になる（レビュー#2） |
| size enum 不正の責務 | (i) trace 個別分岐で検証 / (ii) **`[work-items]` gate に集約** | (ii) 採用。work-item-validate が既に ERROR 化するため trace 個別検証は二重責務かつ到達不能（レビュー#3） |
| status/size 取得 | (i) 新規 grep/sed / (ii) **`fm_scalar`** | (ii) 採用。新規パース禁止規約（frontmatter.sh:24-30） |

## アーキテクチャパターン

**既存パターン踏襲（wrap + グローバル伝播 + 集約）**。doctor.sh の確立パターンをそのまま拡張する:

- 各領域は `diagnose_<area>()` 関数として実装し、末尾の順序実行ブロックで呼ぶ。
- 前段領域の結果はグローバル変数（`STATE_PRESENT` / `CYCLE_DIR` / `GH_AVAILABLE` + 本 Unit で追加する `WORK_ITEMS_INVALID`）で後段へ伝播する。
- 各関数は `report <area> <severity> <detail>` で 1 行出力し、必要に応じて `HAS_ERROR` / `HAS_UNDIAGNOSABLE` を立てる（本 Unit は原則立てない = WARN 止まり）。

選定理由: 既存 9 領域と完全に同型にすることで、レビュー容易性・保守性・テスト容易性を最大化し差分を最小化する。

## コンポーネント構成

### レイヤー / モジュール構成（doctor.sh 内）

```text
doctor.sh
├── ヘッダコメント（領域カウント 9→11 / wrap 契約に [phase]/[trace] 追記）
├── report()                       （既存 / 変更なし）
├── diagnose_work_items()          （既存 / WORK_ITEMS_INVALID 伝播を追加）
├── diagnose_phase()               （新規）
│   ├── WorkItemsValidityGate 参照
│   ├── PhaseDerivationService（§5.1 first-match）
│   └── PrMergedConfirmService（complete 確認 / レビュー#1）
├── diagnose_trace()               （新規）
│   ├── WorkItemsValidityGate 参照
│   ├── depth_level 取得 + enum 検証（レビュー#2）
│   └── DesignRequirementService（§8 マトリクス）
└── 順序実行ブロック（確定順: ... work-items → git → gh → pr → phase → trace → scripts → parse-guard）
```

> **確定した実行順序**（レビュー#2 / 単一化）: `config → state → cycle → work-items → git → gh → pr → phase → trace → scripts → parse-guard`。既存関数は一切移動せず、`diagnose_pr` の直後に `diagnose_phase` / `diagnose_trace` を挿入する。これにより `diagnose_phase` 実行時点で `GH_AVAILABLE`（`diagnose_gh` で設定）が確定済みとなる。本設計内の全ての図・擬似コード・説明はこの順序に統一する。

### コンポーネント詳細

#### diagnose_work_items（既存関数の拡張）

- **責務**: 既存の work-items 検証に加え、結果を後段へ伝播する `WORK_ITEMS_INVALID` を設定する
- **依存**: `work-item-validate.sh`（既存）
- **変更内容**:
  - グローバル `WORK_ITEMS_INVALID=0` を関数定義前に宣言（既存 `STATE_PRESENT` / `CYCLE_DIR` / `GH_AVAILABLE` と同じ位置づけ）
  - ERROR 経路（rc1 = schema 違反 / rc2 = 読み取りエラー）で `WORK_ITEMS_INVALID=1` を設定
  - SKIP / WARN 経路（state なし・cycle dir 未解決・dir 不在・0 件・OK）では 0 のまま（= 未作成/正常前提を invalid 扱いしない。ドメインモデル [Answer] 参照）

#### diagnose_phase（新規 / `[phase]` 領域）

- **責務**: state + work item status から §5.1 first-match でフェーズを導出し、矛盾・確認不能を WARN で報告する
- **依存**: `STATE_PRESENT` / `CYCLE_DIR` / `WORK_ITEMS_INVALID` / `GH_AVAILABLE`（すべて前段で解決済み）、`state-read.sh`、`lib/frontmatter.sh`（`fm_extract_block` + `fm_scalar`）、`gh`
- **公開インターフェース**: なし（doctor.sh 内部関数）。`report phase <severity> <detail>` を 1 回出力

#### diagnose_trace（新規 / `[trace]` 領域）

- **責務**: work item の size × depth_level から design 要否を判定し、`designs/<id>-<slug>.md` の存在整合を WARN で報告する
- **依存**: `STATE_PRESENT` / `CYCLE_DIR` / `WORK_ITEMS_INVALID`、`read-config.sh`（depth_level）、`lib/frontmatter.sh`（size 取得）
- **公開インターフェース**: なし。`report trace <severity> <detail>` を 1 回出力

## スクリプトインターフェース設計

doctor.sh 全体の CLI（引数なし / read-only）は既存のまま変更しない。以下は新領域の**関数内ロジック**の設計。

### diagnose_phase の処理ロジック

#### 入力
| 入力 | 取得元 |
|------|-------|
| `STATE_PRESENT` | 前段 `diagnose_state` |
| `WORK_ITEMS_INVALID` | 前段 `diagnose_work_items`（レビュー#3） |
| `CYCLE_DIR` | 前段 `diagnose_cycle` |
| `GH_AVAILABLE` | 前段 `diagnose_gh` |
| `define_completed` / `release.merge_approved` / `release.pr_number` | `state-read.sh <field> "$STATE_FILE"`（レビュー#1 で pr_number 追加） |
| 各 work item の `status` | `CYCLE_DIR/work-items/*.md` を走査し `fm_extract_block` + `fm_scalar <fm> status` |

#### 判定手順（§5.1 first-match の code 化）

```text
1. gate: WORK_ITEMS_INVALID == 1
     → report phase WARN "work item が invalid のため phase 導出不能（[work-items] を解消してください）"; return
2. state 不在: STATE_PRESENT == 0
     → report phase OK "define（state.json 不在 → define フォールバック / §5.1 評価順 2）"; return
3. state フィールド取得:
     define_completed = state-read define_completed   （取得不能は "未取得" 扱い → 安全側 define + WARN 予約）
     merge_approved   = state-read release.merge_approved
     pr_number        = state-read release.pr_number   （"null" or 整数）
4. work item status 集合を走査:
     wi_count = 走査した work item ファイル数
     has_open = status ∈ {pending,in_progress,blocked} を持つ item が 1 件以上
     has_done = status == done を持つ item が 1 件以上
     （fm 抽出失敗の item があれば warn 予約 / ただし WORK_ITEMS_INVALID で概ねガード済み）
5. 評価順 1（complete）: merge_approved == true のとき
     if pr_number が正整数（`^[1-9][0-9]*$` / 0 は不正 PR 番号として除外）AND GH_AVAILABLE == 1 AND `gh pr view <pr_number> --json merged` で merged==true:
         → report phase OK "complete（merge_approved=true + PR #<pr_number> merged / §5.1 評価順 1）"; return
     else:
         → complete 非導出。warn 予約 "merge_approved=true だが PR merged 未確認（pr_number 非正整数 / gh 不可 / 未 merged）"
         （評価順 2〜4 へ継続し、実フェーズを導出のうえ最終 severity を WARN にする / §6）
     ※ pr_number は既知 schema では integer/null だが、doctor は state 破損時も継続するため gh へ渡す前に
       正整数を必須検証する（gh 引数注入余地の排除 / コードレビュー#2 反映）。
6. 評価順 2（define）: define_completed != true（false or 取得不能）
     if has_done: → report phase WARN "矛盾: define_completed=false だが done の work item あり → 安全側 define 継続（§6）"; return
     if define_completed 取得不能（空）: → report phase WARN "define（取得不能 → 安全側 define）"; return
     else: → report phase <OK|WARN> "define"（warn 予約あれば WARN）; return
7. wi_count == 0 ガード（コードレビュー#1 反映）: define_completed == true だが work item を確認できない
     （cycle dir 未解決 / work-items 未作成 / 0 件）→ 矛盾。全件を確認できない状態を release 可能扱いしない。
     → report phase WARN "矛盾: define_completed=true だが work item を確認できず → phase 導出不能（§6 安全側）"; return
8. 評価順 3（develop）: define_completed == true AND wi_count>0 AND has_open
     → report phase <OK|WARN> "develop"; return
9. 評価順 4（release 可能）: define_completed == true AND wi_count>0 AND not has_open（全 work item が done/withdrawn）
     → report phase <OK|WARN> "release 可能"; return
```

- `<OK|WARN>`: 手順 5 の complete 確認失敗による warn 予約、または define_completed 取得不能があれば WARN、なければ OK。
- **severity 方針**: 本領域は ERROR / 診断不能を出さない（`HAS_ERROR` / `HAS_UNDIAGNOSABLE` を立てない）。矛盾・確認不能はすべて WARN（exit 0 維持）。

#### 異常系 WARN 分岐（Unit 定義・レビュー反映）
| 異常系 | severity | detail 要点 |
|--------|----------|-------------|
| `merge_approved=true` × pr_number=null / gh 不可 / PR 未 merged | WARN | complete 非導出 + フォールバック導出（release 可能 / 実フェーズ）+ 不一致理由 |
| `define_completed=false` × `done` work item 存在 | WARN | 矛盾検知 + 安全側 define 継続（§6） |
| `WORK_ITEMS_INVALID==1` | WARN | work item invalid のため導出不能（レビュー#3） |

### diagnose_trace の処理ロジック

#### 入力
| 入力 | 取得元 |
|------|-------|
| `STATE_PRESENT` / `CYCLE_DIR` / `WORK_ITEMS_INVALID` | 前段領域 |
| `depth_level` | `read-config.sh rules.depth_level.level`（rc1/rc2 → standard フォールバック / enum 外 → standard + WARN） |
| 各 work item の `size` | `CYCLE_DIR/work-items/*.md` の `fm_scalar <fm> size` |
| design ファイル存在 | `CYCLE_DIR/designs/<id>-<slug>.md`（work item と同じ basename） |

#### 判定手順（§8 マトリクスの code 化）

```text
1. gate: STATE_PRESENT == 0        → report trace SKIP "（state なし）"; return
2. gate: CYCLE_DIR 空              → report trace SKIP "（cycle ディレクトリ未解決）"; return
3. gate: WORK_ITEMS_INVALID == 1   → report trace WARN "work item が invalid のため trace 判定不能（[work-items] を解消してください）"; return
4. wi_dir = CYCLE_DIR/work-items; 不在 → report trace SKIP "（work-items 未作成）"; return
5. work item md 列挙; 0 件 → report trace SKIP "（work item 0 件）"; return
6. depth_level 取得:
     rc1/rc2 → depth=standard（取得不能フォールバック）
     取得成功だが enum(minimal/standard/comprehensive) 外 → depth=standard + warn_depth 予約（レビュー#2）
7. 各 work item について:
     id-slug = basename（.md 除去）
     size = fm_scalar size （tiny/normal/risky。size enum 不正は上流 work-item-validate が ERROR 化 → 手順 3 の WORK_ITEMS_INVALID gate で捕捉済みのため、ここに到達する size は valid 前提。レビュー#3）
     required, invalid_combo = DesignRequirement(size, depth)     ※下表
     if invalid_combo(risky×minimal): invalid_list += id
     elif required AND not exists(designs/<id-slug>.md): missing_list += id
8. 集計して report:
     if missing_list or invalid_list or warn_depth: → report trace WARN "<内訳>"
     else: → report trace OK "design 要否充足（<N> item(s)）"
```

#### DesignRequirement マトリクス（§8）
| size \ depth | minimal | standard | comprehensive |
|--------------|---------|----------|---------------|
| tiny | 不要 | 不要 | 不要 |
| normal | 不要 | **必須** | **必須** |
| risky | invalid_combo | **必須** | **必須** |

- design 必須 = `(size==normal ∨ size==risky) ∧ depth ∈ {standard, comprehensive}`
- `risky × minimal` = invalid_combo（design 概念上必須だが組み合わせ不正）→ WARN
- **severity 方針**: 欠落・invalid_combo・enum 外はすべて WARN（exit 0 維持）。ERROR / 診断不能は立てない。

### 順序実行ブロックへの統合

確定順（レビュー#2 で単一化 / 既存関数は移動せず 2 関数を `diagnose_pr` 直後へ挿入）:

```text
diagnose_config
diagnose_state
diagnose_cycle
diagnose_work_items      # WORK_ITEMS_INVALID を設定
diagnose_git
diagnose_gh              # GH_AVAILABLE を設定
diagnose_pr
diagnose_phase           # 新規挿入（GH_AVAILABLE / STATE_PRESENT / CYCLE_DIR / WORK_ITEMS_INVALID すべて解決済み）
diagnose_trace           # 新規挿入
diagnose_scripts
diagnose_parse_guard
```

- **挿入位置は `diagnose_pr` の直後**に確定。`diagnose_phase` は complete 確認で `GH_AVAILABLE` を参照するため、`diagnose_gh` 実行後である必要があり、`diagnose_pr` の後ろに置けばこの前提が自然に満たされる。
- 既存関数（config〜pr / scripts / parse-guard）は一切移動しない（最小差分）。
- 出力順の変更（新領域が pr と scripts の間に入る）は既存テストに非破壊（`assert_area` は領域名で grep = 順序非依存）。

## データモデル概要

### ファイル形式（参照するもの / いずれも read-only）
- `.aidlc/state.json`: `define_completed`(bool) / `release.merge_approved`(bool) / `release.pr_number`(int|null)
- `.aidlc/cycles/<cycle>/work-items/<id>-<slug>.md`: frontmatter `status` / `size`
- `.aidlc/cycles/<cycle>/designs/<id>-<slug>.md`: 存在有無のみ確認
- `.aidlc/config.toml`: `rules.depth_level.level`（read-config.sh 経由）

## 処理フロー概要

### ユースケース: `doctor` 実行時の `[phase]` / `[trace]` 診断

**ステップ**:
1. 既存領域（config〜work-items）が実行され、`STATE_PRESENT` / `CYCLE_DIR` / `WORK_ITEMS_INVALID` が確定
2. `diagnose_gh` / `diagnose_pr` で `GH_AVAILABLE` 確定（確定順で phase より前に位置）
3. `diagnose_phase`: gate → state 読取 → work item status 集合 → §5.1 first-match → complete は PR merged 確認 → `report phase`
4. `diagnose_trace`: gate → depth_level → 各 work item の size で design 要否 → design ファイル存在照合 → `report trace`
5. exit code 集約（本領域は WARN 止まりのため exit 0 に寄与）

**関与するコンポーネント**: diagnose_phase / diagnose_trace / state-read.sh / frontmatter.sh / read-config.sh / gh

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 既存 doctor と同等
- **対応策**: 追加 I/O は work item / designs ディレクトリの列挙 + 各 work item の frontmatter 1 回読取のみ。work item 件数に対し線形（既存 `[work-items]` と同等）

### セキュリティ
- **要件**: read-only。state.json / work item / config を変更しない
- **対応策**: 取得はすべて read-only スクリプト（state-read / fm_scalar / read-config）と `gh pr view`（read-only）。cycle identifier は既存 `diagnose_cycle` のパス安全検証を通過済みの `CYCLE_DIR` を使う（パストラバーサル防止を継承）

### スケーラビリティ
- **要件**: work item 件数に対し線形
- **対応策**: 単純ループ（連想配列不使用 / bash 3.2 互換）

### 可用性
- **要件**: gh 不可 / オフライン時も `[phase]` はフォールバックで継続
- **対応策**: complete 確認のみ gh 依存。gh 不可時は complete 非導出 + WARN で実フェーズを導出し継続（degrade）

## 技術選定
- **言語**: bash（3.2/4.0+ 互換 / 既存 doctor.sh と同一）
- **依存**: `jq`（doctor 前提で確認済み）/ `gh`（complete 確認 / 任意）/ `state-read.sh` / `lib/frontmatter.sh` / `read-config.sh`
- **テストハーネス**: `tests/test-doctor.sh`（自己完結型 / jq のみ前提）

## テスト設計（test-doctor.sh 拡張方針）

`build_fixture` / `make_valid_state` / `make_valid_work_item` / `assert_area` / `assert_rc` / jq 注入を再利用する。

### `[phase]` テストケース
| ケース | fixture | 期待 |
|--------|---------|------|
| state 不在 → define | state なし | `assert_area phase OK`（define / フォールバック）+ rc 0 |
| define_completed=false → define | valid state（define_completed:false）+ pending work item | `assert_area phase OK`（define）+ rc 0 |
| develop | define_completed:true + pending work item | `assert_area phase OK`（develop）+ rc 0 |
| release 可能 | define_completed:true + 全 work item done | `assert_area phase OK`（release 可能）+ rc 0 |
| complete | merge_approved:true + pr_number 設定 + gh stub で merged=true | `assert_area phase OK`（complete）+ rc 0 |
| 異常: merge_approved=true × PR 未 merged/gh 不可/pr_number=null | 上記から PR merged 条件を外す | `assert_area phase WARN` + rc 0 |
| 異常: define_completed=false × done work item 矛盾 | define_completed:false + done work item | `assert_area phase WARN` + rc 0 |
| 根拠検証 | 各導出ケースの detail に導出フェーズ名が含まれる | detail 文字列 grep（既存 assert 補助 or 追加ヘルパ） |

### `[trace]` テストケース
| ケース | fixture | 期待 |
|--------|---------|------|
| design 必須 × 存在 | normal work item + standard + designs/<id>-<slug>.md あり | `assert_area trace OK` + rc 0 |
| design 必須 × 欠落 | normal work item + standard + design なし | `assert_area trace WARN` + rc 0 |
| design 不要 | tiny work item（or normal×minimal） | `assert_area trace OK` + rc 0 |
| normal × comprehensive | comprehensive + normal work item + design なし | `assert_area trace WARN`（必須）+ rc 0 |
| risky × minimal（不正組み合わせ） | minimal + risky work item | `assert_area trace WARN` + rc 0 |
| depth_level 未設定 | read-config stub rc1 → standard フォールバック | 期待は standard 相当の判定 + rc 0 |
| depth_level enum 外（レビュー#2） | read-config stub が `deep` 等を返す | `assert_area trace WARN`（enum 外）+ standard フォールバック + rc 0 |

### 領域間ゲート（レビュー#3）
| ケース | fixture | 期待 |
|--------|---------|------|
| work item invalid 時の phase/trace | 壊れた frontmatter work item（work-items ERROR） | `assert_area work-items ERROR` + `assert_area phase WARN` + `assert_area trace WARN` + rc 1（work-items の ERROR で総合 exit 1） |
| size enum 不正時の phase/trace | size に不正値（例 `huge`）を持つ work item | `assert_area work-items ERROR` + `assert_area phase WARN` + `assert_area trace WARN` + rc 1（size enum 不正は work-item-validate ERROR → gate 捕捉。trace は個別 size 検証を持たないことの確認 / レビュー#3） |

### 「全領域 OK 正常系」11 領域化
- 既存 `all_ok` ブロック（9 領域 assert）に `assert_area phase OK` / `assert_area trace OK` を追加。
- fixture は phase が OK（例: define or develop）かつ trace が OK（design 要否充足）になる状態を用意する（`make_valid_state` の define_completed:false + `make_valid_work_item` の size に応じ design 不要 or design 配置）。

## 実装上の注意事項
- 新規 grep/sed で frontmatter を解釈しない（`fm_scalar` を使う / `lib/frontmatter.sh:24-30` 規約）。
- `report()` の固定幅（`%-14s`）を変更しない。`[phase]`/`[trace]` は 7 文字で収まる。
- `[phase]`/`[trace]` は ERROR / 診断不能フラグを立てない（WARN 止まり = exit 0 維持）。work item ERROR による総合 exit 1 はあくまで `[work-items]` の責務。
- ヘッダコメント（3 / 5-7 行目の「9 領域」、21-33 行目 wrap 契約、355 行目「9 領域を順に診断」）を 11 領域へ更新。SoT ドキュメント（doctor.md 等）反映は Unit 002。
- `set -uo pipefail` 下で未設定変数参照を避ける（グローバルは関数定義前に初期化）。
- `gh pr view` の JSON パースは jq（doctor 前提で確認済み）を使用。

## ガイド照合（`.aidlc/rules.md`「設計レビュー時のガイド照合ルール」）
- **exit-code-convention**: `[phase]`/`[trace]` は WARN=exit 0、診断不能のみ exit 2 の既存規約に整合（本 Unit は診断不能を出さない）。警告付き完了を exit 2 にする等の規約違反はしない。
- **error-handling**: read-only 診断で自動修正しない方針（§6 原則）に整合。

## 不明点と質問（設計中に記録）

[Question] 新領域 `[phase]`（`GH_AVAILABLE` 依存）を既存順序のどこへ挿入するか（レビュー#2）。
[Answer]（設計判断 / 確定）既存関数を移動せず `diagnose_pr` の直後に `diagnose_phase` / `diagnose_trace` を挿入する。既存順序で `diagnose_gh` / `diagnose_pr` は work-items の後にあるため、pr 直後なら `GH_AVAILABLE` は確定済み。`assert_area` は領域名 grep で順序非依存のため既存テストに非破壊。確定順は「順序実行ブロックへの統合」に単一記載。

[Question] work item の size enum 不正を `[trace]` 側で個別検証するか（レビュー#3）。
[Answer]（設計判断 / 確定）検証しない。`work-item-validate.sh:143` が size enum 不正を ERROR にするため `WORK_ITEMS_INVALID` gate が捕捉し、trace には valid な size のみ到達する。trace の size 個別 enum 分岐は二重責務かつ到達不能のため排除。size enum 不正ケースはゲート動作テストで担保する。
