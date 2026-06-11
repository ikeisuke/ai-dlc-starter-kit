# 論理設計: Unit 003 aidlc-v3 skill 骨組み

## 概要

`skills/aidlc-v3/SKILL.md`（ルーティング）と `steps/define.md` / `steps/status.md`（読める手順・出力仕様）のファイル構造・記述内容を定義する。設計正本は `docs/v3/workflow.md` §2/§3.1/§3.5/§4、`docs/v3/data-model.md` §5、`docs/v3/rfc.md` DG-1。

**重要**: この論理設計では**コードは書かず**、ファイル構造と記述内容の定義のみを行う。フロー実行実装は Phase 3。

## ステップ0: 事前コード読込み（新規 skill ファイル作成のため参照基盤の確認）

詳細はドメインモデル `design-artifacts/domain-models/unit_003_v3_skill_skeleton_domain_model.md` のステップ0 に記載。要点:

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `docs/v3/workflow.md` §2/§3.1/§3.5/§4 | コマンド体系・define Step・status 出力・express 適格条件の正本 |
| `docs/v3/data-model.md` §5 | フェーズ導出ロジック（結果参照のみ） |
| `docs/v3/rfc.md` DG-1 | コマンド名 develop |
| `skills/aidlc-v3/scripts/`・`templates/`（Unit 001/002 実体） | 参照パス・I/F の確認 |

### (b) 設計時に意識すべき挙動

- コマンド名 `develop`（build/implement 不採用）
- フェーズ導出は data-model §5 参照（規則再定義なし / first-match 等は非規範サマリ明記）
- 参照パスはスキルベースディレクトリ相対
- フロー実行実装・marketplace.json 登録を含まない
- `skills/**` で `skills/aidlc/` 参照を含めない

### (c) 既存実装に基づく代替案検討

- workflow.md 確定設計の骨組み化（採用） vs SKILL.md へのフェーズ導出再定義（却下: SoT 二重定義）
- 手順記述に留める（採用 / スコープ） vs flow 実装（却下: Phase 3）

## アーキテクチャパターン

**skill プラグイン構成**（SKILL.md = 入口ルーティング + steps/*.md = 詳細手順）。v2 `skills/aidlc` の SKILL.md + steps 構成を踏襲。SKILL.md は薄いルーティング責務、詳細は steps へ委譲。

## コンポーネント構成

```text
skills/aidlc-v3/
├── SKILL.md            (ルーティング: 6 コマンド + express + 旧名エイリアス + 引数なし導出 + コアルール参照)
├── steps/
│   ├── define.md       (define フロー Step 1-4 / 読める手順)
│   └── status.md       (status 出力仕様)
├── scripts/            (Unit 001 実体: state-read.sh / state-write.sh / state-validate.sh)
└── templates/          (Unit 002 実体: intent.md / work-item.md / journal.md)
```

> パス参照は `skills/aidlc-v3/SKILL.md` を基点とするスキルベースディレクトリ相対（`scripts/state-read.sh` 等）。step ファイルからの単純相対（`steps/templates/...`）と解釈しない。

## ファイル構造定義

### SKILL.md

#### コマンドルーティング表（記述する内容）

| コマンド | 分類 | ルーティング先 | 本 Unit での扱い |
|---------|------|--------------|----------------|
| `define` | フェーズ | `steps/define.md`（本 Unit で作成・実在） | 本 Unit で作成 |
| `develop` | フェーズ | （予約 / 後続 Phase で実装） | **予約コマンド**。SKILL.md には「後続 Phase で実装」と明示し、未作成 `steps/develop.md` への実ファイル参照はしない |
| `release` | フェーズ | （予約 / 後続 Phase で実装） | 同上（実体未作成） |
| `reflect` | フェーズ（任意） | （予約 / 後続 Phase で実装） | 同上（実体未作成） |
| `status` | 補助（read-only） | `steps/status.md`（本 Unit で作成・実在） | 本 Unit で作成 |
| `doctor` | 補助（診断） | （予約 / 後続 Phase で実装） | 同上（実体未作成） |

> **未作成ファイル参照の回避**: 本 Unit で実体を作るのは `steps/define.md` / `steps/status.md` のみ。`develop` / `release` / `reflect` / `doctor` は SKILL.md 上で「予約コマンド（後続 Phase で実装）」として記述し、存在しない `steps/*.md` への実ファイルルーティング参照を作らない（スコープ境界の明確化）。

#### エイリアス・express・引数なしルーティング（記述する内容）

- **旧名エイリアス**: `inception`→`define` / `construction`→`develop` / `operations`→`release` / `retrospective`→`reflect`。**`build` / `implement` はエイリアスにしない**（RFC DG-1）
- **express**: 単一 work item（tiny/normal）の場合のみ define + develop + release を連続実行。**複数 work item または risky を含む場合は連続実行せず個別実行へ案内**（workflow.md §4）
- **引数なし実行**: state.json + work item frontmatter からフェーズを導出して対応コマンドへルーティング。state.json 不在は `define` フォールバック。**導出規則の正本は `docs/v3/data-model.md` §5**（SKILL.md は結果参照のみ）
- **コアルール参照**: 共通ルールへの参照ポイント（v3 rules 実体は後続 Phase。本 Unit は参照記述のみ）

### steps/define.md（workflow.md §3.1）

define フロー Step 1-4 を読める手順として記述する:

| Step | 記述内容 | ゲート / 成果物 |
|------|---------|--------------|
| 1 環境チェック | config.toml 存在確認 / git clean 確認 / 前 cycle の `journal.md`・`reflect.md` があれば読込 | - |
| 2 Intent 定義 | 目的を 1 文で確認（AI 提案 → 人間承認）/ scope in・out / acceptance criteria → `templates/intent.md` を基に `intent.md` 作成 | ★ Intent 承認 / `intent.md` |
| 3 Work Item 分割 | intent を work item に分割（AI 提案 → 人間承認）/ 各 item に size・risk 付与 / 依存整理 → `templates/work-item.md` を基に `work-items/*.md` 作成 | ★ Work Item 承認 / `work-items/*.md` |
| 4 初期化 | `state.json` 初期化 / cycle ディレクトリ作成 / `templates/journal.md` を基に `journal.md` 追記 / git branch + 初回 commit /（`early_pr: true` 時のみ Draft PR 作成。**通常時は PR を作らず** release で作成） | `state.json`・`journal.md`・branch |

**Step 4（初期化）で明示する state.json 仕様**:

- 必須フィールド: `schema_version` / `current_cycle` / `define_completed` / `release`（`pr_number` / `ready` / `merge_approved`）/ `updated_at`
- `define_completed` は define 完了後に `true` を書き込む（書き込みタイミング = Step 4 完了時）
- 状態書き込みは `scripts/state-write.sh`、検証は `scripts/state-validate.sh` を参照（実行実装は Phase 3）

> **記述方針**: 本 Unit は「読める手順」に留め、実行コードは書かない。各 Step は AI エージェントが何をするかを把握できる粒度で記述する。

### steps/status.md（workflow.md §3.5 / data-model §5）

status 出力仕様を記述する:

- **フェーズ導出**: `docs/v3/data-model.md` §5 への参照に留め、導出**結果の表示仕様**を記述する。first-match / complete 最優先を記す場合は「非規範サマリ（正本は data-model §5）」と明記
- **complete 判定**: `release.merge_approved`（state.json）と PR の merged 実態の**両方**を参照する旨を含める
- **read-only**: status は状態を変更しない
- **スクリプト参照**: state.json + frontmatter の読取は `scripts/state-read.sh`（実行実装は Phase 3）
- **出力例**: 現在地（Cycle / Phase / Current work item / Completed / **Blocked** / Remaining / Suggested command。workflow.md §3.5 出力例と一致）。state.json 不在時は「No active cycle found / Suggested command: /aidlc define」

## 処理フロー概要

本 Unit に実行フローはない（手順・仕様の記述）。妥当性は Phase 2 の構造検証（コマンド名・参照パス・導出 SoT 参照・markdownlint・CI 構造チェック）で担保する。

## 非機能要件（NFR）への対応

### 整合性

- **要件**: コマンド名・フェーズ導出・schema が確定 RFC と一致（Unit NFR）
- **対応策**: workflow.md/data-model/rfc を正本参照し、コマンド名 develop・導出 SoT 参照・state.json 必須フィールドを明示

### 可読性

- **要件**: AI が 1 ファイル読了で define/status の責務を把握（Unit NFR）
- **対応策**: SKILL.md ルーティング表 + steps の Step テーブルで責務を明示

### 共存（v2 非影響）

- **要件**: 成果物は `skills/aidlc-v3/` に限定（Unit NFR）
- **対応策**: 新規ディレクトリのみ。`skills/aidlc/` 不変

## 技術選定

- **形式**: Markdown（SKILL.md + steps/*.md）
- **参照記法**: スキルベースディレクトリ相対（`scripts/` / `templates/` / `steps/`）

## 実装上の注意事項

- コマンド名 `develop` を厳守（build/implement をエイリアスにしない）
- フェーズ導出規則を SKILL.md/status.md に再定義しない（data-model §5 参照）
- 参照パスを Unit 001/002 の実体ファイル名（state-read/write/validate.sh、intent/work-item/journal.md）と一致させる
- `skills/**` で `skills/aidlc/` を書かない（CI 構造チェック）

## 不明点と質問（設計中に記録）

[Question] 後続コマンド（develop/release/reflect/doctor）の手順ファイルが未作成だが SKILL.md でどう扱うか。
[Answer] SKILL.md では develop/release/reflect/doctor を「予約コマンド（後続 Phase で実装）」として記述し、**未作成の `steps/*.md`（`steps/develop.md` 等）への実ファイル参照は作らない**。本 Unit で実体を作る手順ファイルは `steps/define.md` / `steps/status.md` のみ（上記「SKILL.md ルーティング表」の注記と一致）。

[Question] コアルール参照の実体は本 Unit に含めるか。
[Answer] 含めない。参照ポイント（記述）のみ置き、v3 rules 実体は後続 Phase。
