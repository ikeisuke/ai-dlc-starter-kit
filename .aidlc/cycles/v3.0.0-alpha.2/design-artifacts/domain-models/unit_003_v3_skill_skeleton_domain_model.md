# ドメインモデル: Unit 003 aidlc-v3 skill 骨組み

## 概要

v3 skill の「コマンドルーティング」ドメインを定義する。6 コマンド（define/develop/release/reflect/status/doctor）+ 連続実行ラッパ express + 旧名エイリアス + 引数なし実行のフェーズ導出ルーティングを構造化する。本 Unit は SKILL.md（ルーティング）と steps/define.md・steps/status.md（読める手順・出力仕様）を作成し、フロー実行実装は持たない。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。

## ステップ0: 事前コード読込み（新規 skill ファイル作成のため参照基盤の確認）

本 Unit は `skills/aidlc-v3/SKILL.md` と `steps/` を新規作成する（改修対象の既存実装なし）。本セクションは正本・依存成果物の確認として実施する。

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `docs/v3/workflow.md` §2 | コマンド体系（6 コマンド責務・v2→v3 対応・エイリアス方針・引数なしルーティング）の正本確認 |
| `docs/v3/workflow.md` §3.1 | define フロー Step 1-4・承認ゲートの正本確認 |
| `docs/v3/workflow.md` §3.5 | status 出力仕様の正本確認 |
| `docs/v3/workflow.md` §4 | express 適格条件（単一 work item tiny/normal）の正本確認 |
| `docs/v3/data-model.md` §5 | フェーズ導出ロジック（first-match / complete 最優先）の正本確認（status/ルーティングは結果参照のみ） |
| `docs/v3/rfc.md` DG-1 | コマンド名 `develop`（build/implement 不採用）確認 |
| `skills/aidlc-v3/scripts/`（Unit 001 実体） | define.md/status.md が参照する `state-read.sh` / `state-write.sh` / `state-validate.sh` のパス・I/F 確認 |
| `skills/aidlc-v3/templates/`（Unit 002 実体） | define.md が参照する `intent.md` / `work-item.md` / `journal.md` のパス・構成確認 |

### (b) 設計時に意識すべき挙動

- コマンド名は `develop`（`build` / `implement` はエイリアスにもしない / RFC DG-1）
- フェーズ導出の正本は data-model §5。SKILL.md / status.md は導出**結果**を参照し規則を再定義しない（first-match 等を書く場合は非規範サマリと明記）
- 参照パス（`scripts/` / `templates/`）はスキルベースディレクトリ相対（`steps/` 相対で `steps/templates/...` と解釈されないよう明示）
- 本 Unit は「読める手順・出力仕様」に留め、フロー実行実装・marketplace.json 登録を含まない
- `skills/**` で `skills/aidlc/` プロジェクトルート相対参照を含めない（CI 構造チェック）

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採用 / 却下 | 根拠 |
|------|------|-----------|------|
| workflow.md の確定設計を骨組み化 | §2/§3.1/§3.5/§4 をルーティング表・手順に落とす | **採用** | SoT と一致、Phase 3 インプットが明確化 |
| フェーズ導出を SKILL.md に再定義 | 導出規則を SKILL.md にも書く | 却下 | SoT 二重定義（data-model §5 が正本） |
| build/implement をエイリアス化 | 旧称互換を広く取る | 却下 | RFC DG-1 が不採用動詞のエイリアス化を禁止 |
| flow 実行実装も含める | define/status を実装まで | 却下 | スコープ外（Phase 3）。本 Unit は手順記述に留める |

## エンティティ（Entity）

### Command

v3 の実行コマンド。

- **ID**: コマンド名（`define` / `develop` / `release` / `reflect` / `status` / `doctor`）
- **属性**:
  - `category`: フェーズコマンド（define/develop/release/reflect）/ 補助コマンド（status/doctor）
  - `has_gate`: フェーズコマンドは承認ゲートを持つ / 補助コマンドは持たない
  - `mutates_state`: status は read-only、doctor は診断のみ（状態不変）
- **振る舞い（本 Unit の範囲）**: ルーティング先（手順ファイル）の宣言のみ。実行は Phase 3

## 値オブジェクト（Value Object）

### CommandAlias

旧名から新名への後方互換マッピング。

- **マッピング**: `inception`→`define` / `construction`→`develop` / `operations`→`release` / `retrospective`→`reflect`
- **不変条件**: 不採用動詞（`build` / `implement`）はエイリアスに含めない（RFC DG-1）

### DerivedPhase

state.json + work item frontmatter から導出されるフェーズ（状態として保持しない）。

- **値域**: `define` / `develop` / `release` / `complete`
- **導出規則の正本**: `docs/v3/data-model.md` §5（first-match / complete 最優先）。本 Unit は**結果を参照**する（規則を再定義しない）
- **complete 判定**: `release.merge_approved`（state.json）と PR の merged 実態の**両方**が必要

### ApprovalGate

define フローの承認ゲート。

- **値**: `Intent 承認`（define Step 2）/ `Work Item 承認`（define Step 3）

## 集約（Aggregate）

### SkillRouting 集約

- **集約ルート**: SKILL.md のルーティング定義
- **含まれる要素**: Command 群 + CommandAlias + 引数なし導出ルーティング + コアルール参照
- **境界**: skill の入口（SKILL.md）。詳細手順は steps/*.md に委譲
- **不変条件**:
  - 6 コマンド + express + 旧名 4 エイリアスを網羅
  - 引数なし実行は data-model §5 の導出結果へルーティング（規則再定義なし）

## ドメインサービス

### PhaseRoutingService（SKILL.md が表現 / 実装は Phase 3）

- **責務**: 引数なし実行時に state.json + frontmatter からフェーズを導出し対応コマンドへルーティング。state.json 不在は define フォールバック
- **依存**: data-model §5（導出規則の正本）

本 Unit はこのサービスの**手順記述**のみを行い、実行ロジックは Phase 3 へ defer。

## ユビキタス言語

- **フェーズコマンド**: 状態を進行させ承認ゲートを持つ（define/develop/release/reflect）
- **補助コマンド**: 状態を変更しない（status=読み取り専用 / doctor=診断のみ）
- **express**: 単一 work item（tiny/normal）サイクル専用の連続実行ラッパ。複数 work item / risky は個別実行
- **フェーズ導出**: state.json + frontmatter から現在フェーズを算出（`current_phase` は保持しない）
- **読める手順 / 出力仕様**: 本 Unit の成果物は「AI が 1 ファイル読了で define/status の責務を把握できる」記述。実行実装は Phase 3

## 不明点と質問（設計中に記録）

[Question] コアルール参照の実体（v3 rules）は本 Unit で作るか。
[Answer] 作らない（`steps/rules.md` は後続 Phase / スコープ外）。SKILL.md には参照ポイント（プレースホルダ的記述）のみ置き、実体は Phase 3 以降で追加する。

[Question] develop/release/reflect/doctor の手順ファイルは本 Unit で作るか。
[Answer] 作らない。本 Unit で実体を作る手順ファイルは SKILL.md ルーティング + `steps/define.md` + `steps/status.md` のみ。後続コマンド `develop` / `release` / `reflect` / `doctor` は後続 Phase（スコープ外）であり、SKILL.md ではこれらを「予約コマンド（後続 Phase で実装）」として記述し、**未作成の `steps/*.md` への実ファイル参照は作らない**（存在しない参照を避け、スコープ境界を明確化する）。
