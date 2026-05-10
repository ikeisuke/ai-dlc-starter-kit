# Unit 006 計画: GitHub Projects (ProjectsV2) フル移行

## Unit 概要

Issue #524 の手動チェックリスト運用を GitHub Projects (ProjectsV2) に移行する。具体的には以下を一括実施する:

1. `gh` CLI トークンスコープ拡張ガイド整備（実行はユーザー手動）
2. ProjectsV2 の作成（命名 / Visibility）
3. フィールド定義（`Status` / `Priority` / `Cycle` / `Type`）
4. ビュー定義（Roadmap / Backlog Board / Priority Table / Feedback View）
5. 自動化ワークフロー（`Item closed` → `Status=Done`）の有効化と実証
6. 既存 Open Issue（Issue #524 リスト記載分）の Item 一括投入と初期値セット
7. Issue #524 のリダイレクト化（本文を Project URL + 運用ルールのみに置換）
8. AI-DLC 運用ガイダンス更新（Inception ステップ17 にバックログ確認の Project 参照を組み込み）
9. CHANGELOG / README 更新
10. 異常系ハンドリング（gh トークンスコープ不足時のスキップ + 警告）

- 関連 Issue: #673
- 依存 Unit: なし（独立）
- 見積もり: 5〜8 時間
- 移行作業: GitHub.com 上の Project 作成・Item 投入・Issue #524 編集を含む（**外部共有状態への変更**）

## 依存関係

- **依存元**: なし
- **被依存**: なし（次サイクル以降のバックログ確認運用を変更する）

## Phase 1 意思決定ゲート（完了条件の前提）

| ゲート | 論点 | 採用案（候補） |
|------|------|-------------|
| GATE-1 | gh トークンスコープ最小集合 | `project`（書き込み）+ `read:org`（`gh project list --owner @me` 要件）+ `read:project`（互換）。**事前検証で `read:org` 追加が必須と判明（Unit 定義の `project,read:project` のみではエラー）**。ガイドには `gh auth refresh -s project,read:org,read:project` を記載 |
| GATE-2 | Project 命名・Visibility | **採用案: 命名 `AI-DLC Starter Kit Roadmap`、Visibility=`public`**（Issue #524 / Milestone と同等に閲覧可能なため、運用一貫性を優先）。確定はユーザー承認を別途取得 |
| GATE-3 | Owner 種別 | **採用案: `@me`（ユーザー: `ikeisuke`）の personal project**。リポジトリは `ikeisuke/ai-dlc-starter-kit`、Org 移管予定なし。`gh project create --owner @me` を使用 |
| GATE-4 | フィールド設計の確定 / `Type` の位置付け（指摘 #3 反映） | **Project managed field は `Status` / `Priority` / `Cycle` の 3 種**。`Type` は **Project 上の field としては作成せず、Issue labels (`type:*`) を参照する派生軸**として定義する。ビュー要件は Project field 3 種 + labels 派生軸 1 種の組み合わせ表現で統一（Issue 受け入れ基準の `Status/Priority/Cycle/Type` 表記と整合させる）。`Type` を Project field 化する将来拡張点は別サイクル候補として明示（GATE-9 の双方向同期に類似する拡張保留扱い） |
| GATE-5 | `Cycle` フィールド初期値リスト + 正規化レイヤー（指摘 #6 反映 / R2 指摘 #1 反映で spec 内包に変更） | Milestone 名を直接 Project の `Cycle` 単一選択値に流し込まず、**`config/github-project-spec.yaml` の `cycle_map` セクション**として内包する正規化レイヤーを経由する。マップ定義: `{milestone_title_pattern: cycle_label, fallback: "Later"}`。例: `^v\d+\.\d+\.\d+$` → そのままラベル使用、マッチ外 / Milestone 削除済 → `Later` にフォールバック。`cycle_map` を spec に含めることで設定 SoT を 1 系統に統合（R2 指摘 #1 反映、外部 JSON ファイル分離は廃止） |
| GATE-6 | `Item closed` → `Status=Done` workflow の有効化方法（R2 指摘 #2 反映で probe / audit 分離） | **採用案: GitHub UI 経由で有効化**（現時点で GraphQL `enableProjectV2Workflow` は GA 不安定のため）。Phase 1 設計でドキュメント化、ユーザー手動操作ステップとして明示。**監査機構を 2 段構成に分離（R2 指摘 #2 反映）**: ①`bin/probe-github-project.sh --probe workflow-item-closed`（write 副作用あり = sandbox Issue 作成・close・削除）+ ②`bin/audit-github-project.sh --check workflow-item-closed`（read-only = probe 結果を評価し audit-summary.json 出力）。実行順は `probe → audit` の 2 段で、probe 失敗 / audit 失敗を独立に切り分け可能 |
| GATE-7 | スクリプトの冪等性方針 + サブコマンド分割（指摘 #2 反映） | 単一の `bin/setup-github-project.sh` に責務を集約せず、**plan / apply 分離 + サブコマンド分割**で実装する: `bin/gh-project-cli.sh <subcommand>` + サブコマンド `ensure-project` / `ensure-fields` / `ensure-views` / `sync-items` / `audit`。各サブコマンドは独立に dry-run / apply 可能、idempotent ラッパー関数 `ensure_*` を内部で呼ぶ。`bin/setup-github-project.sh` は本 CLI を順番に呼ぶ薄い orchestrator として残す（後方互換維持） |
| GATE-8 | Item 一括投入の対象範囲 | **採用案: Issue #524 本文に列挙された Open Issue 全件 + `backlog` ラベルが付いた全 Open Issue**（差分があれば union を採用）。closed は対象外（移行コスト圧縮）。投入順序は Issue 番号昇順 |
| GATE-9 | `priority:*` ラベルと Project `Priority` の SoT | **採用案: 移行直後は label を SoT、Project `Priority` は label の派生（読み取り専用）**。双方向同期は別サイクル（Unit 定義の境界に明記済み）。本サイクルでは「初期投入時のみ label → Project へ転写」する片方向同期 |
| GATE-10 | Issue #524 のリダイレクト化方針 | 本文を以下に置換: ①Project URL ②「ロードマップは GitHub Projects へ移行しました」案内 ③運用ルール抜粋（バックログ確認手順 / Inception 開始時の Project 参照）。完了済セクションは Project 側で自動管理されるため削除 |
| GATE-11 | AI-DLC スキル統合の介入箇所 | **採用案: `skills/aidlc/steps/inception/02-preparation.md` ステップ17（バックログ確認）に Project 参照ステップを追記**。`gh project item-list --owner @me <number>` の例示と Project URL を含める。`gh_status != available` 時はスキップして既存挙動（Issue 検索）にフォールバック |
| GATE-12 | スコープ不足時の異常系 + strict/soft 分離（指摘 #5 反映 / R2 指摘 #3 反映でデフォルトを strict 寄りに） | `gh-project-cli.sh` および AI-DLC スキル統合は `gh auth status` で必要スコープを事前チェック。**動作モードを 2 系統に分離**: ①`--strict` モード（CI / 自動実行 / リリース系 / 実環境 apply 系）→ 不足時 exit 2（fatal）+ 構造化結果 `{status: "scope_missing", missing: [...]}` を stderr に JSON 出力。②`--soft` モード（参照 / 対話 / 非破壊用途）→ 不足時 exit 0 + warn 出力 + 結果コードを `.aidlc/cache/gh-project-last-run.json` に書き出し。**デフォルトモード（R2 指摘 #3 反映）**: 実環境 apply 系（`bin/setup-github-project.sh` / `bin/gh-project-cli.sh ensure-* sync-items` の apply 経路 / `bin/migrate-issue-524.sh` apply / `bin/probe-github-project.sh`）は **デフォルト `--strict`**。参照系（`bin/audit-github-project.sh`（read-only） / AI-DLC スキル統合の Inception ステップ17 / dry-run 単独経路）は `--soft`。ユーザーが明示指定で上書き可能 |
| GATE-13 | スクリプトの配置（R2 指摘 #2 反映で probe / audit 分離） | `bin/gh-project-cli.sh`（サブコマンド分割実装、GATE-7）+ `bin/setup-github-project.sh`（薄い orchestrator）+ `bin/migrate-issue-524.sh`（Issue #524 リダイレクト化）+ `bin/probe-github-project.sh`（**書き込み副作用あり / sandbox 操作 / GATE-6**）+ `bin/audit-github-project.sh`（**read-only / 状態評価のみ / GATE-6 + 構造監査**）+ 共通ライブラリ `bin/lib/gh-scope-check.sh` / `bin/lib/gh-project-state.sh`。すべて dry-run オプション必須。実環境 apply 系はデフォルト `--strict`、参照系は `--soft`（GATE-12） |
| GATE-14 | 完了条件の二段分離（指摘 #1 反映 / `Phase 2 Done` ↔ `Execution Done`） | **2 段階の完了定義に分離**: ①`Phase 2 Done`（実装完了 / コミット可能状態）= スクリプト群 + ドキュメント + AI-DLC 統合 + テスト整備。Construction Phase の Unit 完了処理はここまでで完結。②`Execution Done`（実環境反映完了 / 工程 D 完了）= 実 Project 作成 + workflow 有効化 + Item 投入 + Issue #524 リダイレクト。**Construction Phase の完了条件は ① のみ**で判定し、② は Operations Phase（または事後フォローアップ）で実行する。各チェックリスト項目には `[実装]` / `[実行]` 属性を付与（後段「完了条件チェックリスト」参照） |
| GATE-15 | 宣言的仕様の一元管理（指摘 #4 反映） | Project の desired state（フィールド / ビュー / workflow / 命名 / Visibility）を **`config/github-project-spec.yaml`** に集約宣言する。`bin/gh-project-cli.sh` の各サブコマンドは本 spec を読み込み、CLI / GraphQL / UI 案内を適用アダプタとして実行する。UI 手動工程は spec 内に `manual_action: { description, audit_check }` として定義し、`bin/audit-github-project.sh` で監査チェックを必ず実行する |

## 完了条件チェックリスト

> **属性表記（指摘 #1 反映）**: 各項目の先頭に `[実装]` または `[実行]` を付与する。
>
> - **`[実装]` = Phase 2 Done**: スクリプト・ドキュメント・AI-DLC 統合・テストの整備完了。**Construction Phase Unit 完了の判定対象**。
> - **`[実行]` = Execution Done**: GitHub.com 上の Project 作成・Item 投入・Issue #524 編集など外部状態への反映完了。**工程 D（Operations Phase または事後フォローアップ）で実施**し、Construction Phase の Unit 完了条件には含めない。

### Phase 1 ゲート由来

- [x] `[実装]` GATE-1〜GATE-15 すべての論点が確定し、設計ドキュメントに記録されている

### Unit 定義「責務」由来

- [x] `[実装]` **gh CLI トークンスコープ拡張ガイド整備**: `gh auth refresh -s project,read:org,read:project` 手順を `docs/development/github-projects-setup.md`（新規）に記載 + `README.md` から参照
- [x] `[実装]` **`config/github-project-spec.yaml` 整備**（GATE-15 / GATE-5 内包）: Project の desired state（フィールド / ビュー / workflow / 命名 / Visibility / manual_action 監査キー / `cycle_map` セクション）を宣言（SoT 単一系統 / R2 指摘 #1）
- [x] `[実装]` **`bin/gh-project-cli.sh` 実装**（GATE-7）: サブコマンド `ensure-project` / `ensure-fields` / `ensure-views` / `sync-items` / `audit` + spec 駆動 + dry-run + strict/soft モード（apply はデフォルト strict / R2 指摘 #3）
- [x] `[実装]` **`bin/setup-github-project.sh` 実装**（薄い orchestrator）: `gh-project-cli.sh` の各サブコマンドを順次呼ぶ（apply 経路はデフォルト strict）
- [x] `[実装]` **`bin/migrate-issue-524.sh` 実装**: Issue #524 本文置換 + バックアップ + dry-run（apply はデフォルト strict）
- [x] `[実装]` **`bin/probe-github-project.sh` 実装**（GATE-6 / R2 指摘 #2）: write 副作用あり / sandbox Issue 作成・close・削除 / 結果を `audit-summary.json` の入力として書き出し（apply はデフォルト strict）
- [x] `[実装]` **`bin/audit-github-project.sh` 実装**（GATE-6 / GATE-15 / R2 指摘 #2）: read-only / probe 結果評価 + spec 整合監査 / `audit-summary.json` 出力（デフォルト soft、CI は strict 明示）
- [x] `[実装]` **`bin/lib/gh-scope-check.sh` 実装**（GATE-12）: `--strict` / `--soft` モード切替 + 構造化結果出力
- [x] `[実装]` **AI-DLC 運用ガイダンス更新**: `skills/aidlc/steps/inception/02-preparation.md` ステップ17 に Project 参照ステップ追加（`gh_status` + scope チェック + フォールバック）
- [x] `[実装]` **CHANGELOG / README 更新**: v2.6.0 セクションに GitHub Projects 移行を明示
- [x] `[実装]` **テスト整備**: bats テスト（`bin/gh-project-cli.sh` 各サブコマンド / `bin/migrate-issue-524.sh` / `bin/probe-github-project.sh` / `bin/audit-github-project.sh` / `bin/lib/gh-scope-check.sh` strict/soft）
- [ ] `[実行]` **ProjectsV2 作成**: `bin/setup-github-project.sh` または `bin/gh-project-cli.sh ensure-project` 実環境実行 + Project URL 記録
- [ ] `[実行]` **フィールド定義**: `Status` / `Priority` / `Cycle` の Project field 3 種を実環境で作成（`Type` は labels 派生軸として spec 上で宣言、Project field 化はしない / GATE-4）
- [ ] `[実行]` **ビュー定義**: Roadmap / Backlog Board / Priority Table / Feedback View の 4 ビュー実環境作成
- [ ] `[実行]` **自動化ワークフロー**: `Item closed` → `Status=Done` を実環境で有効化 + sandbox Issue で `bin/audit-github-project.sh` 監査 pass
- [ ] `[実行]` **Item 一括投入**: 対象 Open Issue 全件投入 + Priority / Cycle / Status 初期値セット
- [ ] `[実行]` **Issue #524 リダイレクト化**: `bin/migrate-issue-524.sh` 実環境実行 + 本文置換確認

### Issue #673 受け入れ基準由来

> 受け入れ基準は **`[実行]` 完了後に検証可能**になる項目を含む。Construction Phase Unit 完了時点では **「実装が受け入れ基準を充足する形で完成しているか」** を Phase 1 設計と Phase 2 実装ベースで担保する。実環境での充足確認は `[実行]` 工程 D で行う。

- [x] `[実装]` 完了済の手動削除運用を廃止する設計になっている（`bin/migrate-issue-524.sh` の本文テンプレートに完了済セクションが含まれていない / 実環境での廃止確認は `[実行]`）
- [x] `[実装]` Status / Priority / Cycle (Project field) + Type (labels 派生 / GATE-4) の組み合わせで動的フィルタ可能となるよう、`config/github-project-spec.yaml` の 4 ビュー定義（Roadmap / Backlog Board / Priority Table / Feedback View）が宣言されている
- [x] `[実装]` Roadmap / Board / Table の 3 ビューが spec 上で宣言されている（実環境での動作は `[実行]`）
- [x] `[実装]` Inception ステップ17 の改修により、Project URL が確定すれば次サイクル候補が決まる動線が組まれている（実 URL 反映と動作は `[実行]`）
- [x] `[実装]` Milestone（既存）と Project（新設）の役割分担が `docs/development/github-projects-setup.md` に明記されている

### 横断要件

- [x] `[実装]` 冪等性: `bin/gh-project-cli.sh ensure-* --dry-run` を 2 回実行して diff なし（dry-run レベル / モック含む）
- [ ] `[実行]` 冪等性: `bin/setup-github-project.sh` 実環境 2 回目実行で Project / フィールド / ビュー / Item の重複作成が発生しない
- [x] `[実装]` dry-run モードで全変更が事前確認可能（各サブコマンド + `bin/setup-github-project.sh` + `bin/migrate-issue-524.sh`）
- [x] `[実装]` gh CLI トークンスコープ拡張は **ユーザー手動作業**として `docs/development/github-projects-setup.md` 内で明確に区分されている
- [x] `[実装]` strict/soft モード分離（GATE-12）: AI-DLC スキル統合は `--soft`、CI / 監査系は `--strict`。bats テストで両モードの exit code を検証
- [ ] CLAUDE.md の「リスクの高いアクション」ポリシー準拠: `[実行]` 工程 D の各承認ポイントでユーザー確認（後段「工程 D 承認ポイント」表）
- [x] `[実装]` codex によるコード AI レビュー実施
- [x] `[実装]` codex review --base main による統合 AI レビュー実施

## 実装スコープ

### 含む

#### Phase 別工程

> **Phase 2 Done = 工程 A〜C + テスト整備（工程 E のうちモック検証分）**まで。**Execution Done = 工程 D + 実環境冪等性検証**は Operations Phase / 事後フォローアップで実施。

1. **工程 A: 宣言的仕様 + スクリプト実装**（〜3〜4 時間 / `[実装]`）
    - `config/github-project-spec.yaml`: Project desired state（フィールド / ビュー / workflow / 命名 / Visibility / manual_action 監査キー / `cycle_map` セクション内包 / R2 指摘 #1）宣言（GATE-15 / GATE-5）
    - `bin/gh-project-cli.sh`: サブコマンド分割（`ensure-project` / `ensure-fields` / `ensure-views` / `sync-items` / `audit`）+ spec 駆動 + dry-run + strict/soft（GATE-7 / 12 / 15）
    - `bin/setup-github-project.sh`: 薄い orchestrator（apply 経路はデフォルト strict / R2 指摘 #3）
    - `bin/migrate-issue-524.sh`: Issue #524 本文置換 + バックアップ + dry-run（apply はデフォルト strict）
    - `bin/probe-github-project.sh`: write 副作用あり / sandbox 操作（GATE-6 / R2 指摘 #2）
    - `bin/audit-github-project.sh`: read-only 監査（probe 結果評価 + spec 整合監査）（GATE-6 / 15 / R2 指摘 #2）
    - `bin/lib/gh-scope-check.sh`: strict/soft + 構造化結果出力（GATE-12）
    - `bin/lib/gh-project-state.sh`: 共通状態取得 / `gh project list` キャッシュ / 1 回限定 API 呼び出し
2. **工程 B: ドキュメント整備**（〜1 時間 / `[実装]`）
    - `docs/development/github-projects-setup.md`: スコープ拡張手順 + Project 構造説明 + ビュー一覧 + 運用ルール + UI 手動工程の手順 + 監査チェック方法
    - `README.md`: GitHub Projects への参照リンク追加
    - `CHANGELOG.md`: v2.6.0「Added」セクションに「GitHub Projects 移行」を追記
3. **工程 C: AI-DLC スキル統合**（〜30 分〜1 時間 / `[実装]`）
    - `skills/aidlc/steps/inception/02-preparation.md` ステップ17 に Project 参照ステップ追加
    - `gh_status` + scope (`--soft`) チェック + 不足時の既存挙動フォールバック明示
4. **工程 D: 実環境への移行実行**（〜1〜2 時間 / `[実行]` / Operations Phase 内 or 事後フォローアップ）
    - **D1**: ユーザー側で `gh auth refresh -s project,read:org,read:project` 実行確認
    - **D2**: `bin/gh-project-cli.sh ensure-project --dry-run` → ユーザー承認 → apply
    - **D3**: `bin/gh-project-cli.sh ensure-fields/ensure-views --dry-run` → ユーザー承認 → apply
    - **D4**: GitHub UI で `Item closed` → `Status=Done` workflow 有効化（ユーザー操作）
    - **D5**: `bin/probe-github-project.sh --probe workflow-item-closed`（sandbox Issue 操作 / write） → `bin/audit-github-project.sh --check workflow-item-closed`（read-only 評価）
    - **D6**: `bin/gh-project-cli.sh sync-items --dry-run` → ユーザー承認 → apply
    - **D7**: `bin/migrate-issue-524.sh --dry-run` → ユーザー承認 → apply
    - **D8**: `bin/audit-github-project.sh --check spec-conformance`（read-only）で spec 整合監査
5. **工程 E: 検証**（モック検証は `[実装]` / 実環境検証は `[実行]`）
    - **E1（`[実装]`）**: bats テスト全 pass + `bin/gh-project-cli.sh ensure-* --dry-run` 2 回実行 diff なし（モック / fixture）
    - **E2（`[実装]`）**: Inception ステップ17 の差分が `grep` 確認可能な状態（実 URL 反映なしで構造確認）
    - **E3（`[実行]`）**: 実 Project に対する `--dry-run` 2 回 diff なし（実 API 経由）
    - **E4（`[実行]`）**: `/aidlc i` 試行で Project 参照ステップが動作することを実機確認

### 含まない

- `priority:*` ラベルと Project `Priority` の双方向同期 workflow（別サイクル）
- 振り返り Issue / backlog Issue の分離（#664）
- Project の workflow 拡張（`Item closed` 以外の自動化、例: 自動 `Status=Next` 遷移）
- 既存 Milestone 機能との重複削除（並行運用方針）
- Closed Issue の Project 投入（移行コスト圧縮）
- Project の権限管理 / 共有設定の細分化（`public` 一択）

## レビュー指摘対応サマリ（Round 1）

| 指摘 # | 重要度 | 内容 | 対応 |
|--------|--------|------|------|
| #1 | 高 | Phase 2 完了条件と実環境反映条件の二重化 | GATE-14 を「Phase 2 Done / Execution Done」二段分離に改訂 + 完了条件チェックリストに `[実装]` / `[実行]` 属性付与 |
| #2 | 高 | `bin/setup-github-project.sh` の責務過密 | GATE-7 にサブコマンド分割（`bin/gh-project-cli.sh` + `ensure-project/fields/views/sync-items/audit`）を採用、GATE-13 で配置を更新 |
| #3 | 中 | `Type` フィールドの位置付け曖昧 | GATE-4 を「`Type` は Project field ではなく Issue labels 派生軸」と明記、ビュー要件を統一表現に修正 |
| #4 | 中 | CLI / GraphQL / UI の実行経路分散 | GATE-15 を新設し `config/github-project-spec.yaml` に desired state 一元化、UI 手動工程は `manual_action` + 監査チェックを必須化 |
| #5 | 中 | `exit 0` 一律で失敗見逃しリスク | GATE-12 に `--strict` / `--soft` モード分離 + 構造化結果出力を追加 |
| #6 | 低 | `Cycle` 値の Milestone 直結による安定性リスク | GATE-5 に正規化レイヤー + fallback 規則を追加（R2 指摘 #1 反映で spec 内包に変更） |

## レビュー指摘対応サマリ（Round 2）

| 指摘 # | 重要度 | 内容 | 対応 |
|--------|--------|------|------|
| R2 #1 | 中 | spec.yaml と cycle-map.json の SoT 二系統化 | GATE-5 を改訂し `cycle_map` セクションを `config/github-project-spec.yaml` に内包。外部 JSON ファイル（`github-project-cycle-map.json`）は廃止し SoT を 1 系統に統合 |
| R2 #2 | 中 | audit が write 副作用を持つ責務混在 | GATE-6 / GATE-13 を改訂し `bin/probe-github-project.sh`（sandbox 操作 / write） と `bin/audit-github-project.sh`（read-only / 評価） に 2 段分離。実行順は `probe → audit` |
| R2 #3 | 低 | apply 系のデフォルト `--soft` で fail-fast 境界が逆転 | GATE-12 を改訂し実環境 apply 系（`bin/setup-github-project.sh` / `gh-project-cli.sh ensure-* sync-items` apply / `migrate-issue-524.sh` apply / `probe-github-project.sh`）のデフォルトを `--strict` に固定。参照系（`audit` read-only / Inception 統合 / dry-run 単独）は `--soft` |

## レビュー指摘対応サマリ（Round 3）

| 指摘 # | 重要度 | 内容 | 対応 |
|--------|--------|------|------|
| R3 #1 | 高 | 設計考慮事項 §2 のモード割り当て表が GATE-12 と矛盾 | §2 の表を「apply 系=default strict / audit(read-only)=default soft（CI で strict 明示）」に整合改訂。表エントリも詳細化 |
| R3 #2 | 高 | 設計考慮事項 §6.5 が依然として audit 側で sandbox 操作する記述 | §6.5 を全面改訂。`probe-github-project.sh`（write 副作用 + sandbox cleanup）と `audit-github-project.sh`（read-only 評価のみ）の 2 段責務を明示。probe-evidence.json の受け渡し契約と障害切り分け表を追加 |

## レビュー指摘対応サマリ（Round 4）

> Round 4 領域分析: 全 3 件は同一ファイル `.aidlc/cycles/v2.6.0/plans/unit-006-plan.md`（領域キー `cycle-artifacts`）への反映漏れ整合性指摘。Round 1〜3 で指摘済みの領域 `K_old = {cycle-artifacts}`、Round 4 でも `K_new = {cycle-artifacts}`、`K_diff = {} `（新領域 0 件）。新領域指摘の自動 backlog 化フロー対象外（既存領域の継続反映漏れ）。

| 指摘 # | 重要度 | 内容 | 対応 |
|--------|--------|------|------|
| R4 #1 | 高 | 工程 D 承認ポイント表 D5 が旧記述（audit が sandbox 操作） | D5 を D5a (probe / 副作用) と D5b (audit / read-only) に分割。取り消し性も probe 側に cleanup 責務がある形で明示 |
| R4 #2 | 中 | 検証コマンドが廃止済 `config/github-project-cycle-map.json` を参照 | 検証コマンドを `yq` で `config/github-project-spec.yaml` の `cycle_map` セクションを検証する形に統一 |
| R4 #3 | 低 | 検証コマンドの bats 実行リストに `probe-github-project.bats` 欠落 | bats 実行リストに `tests/bin/probe-github-project.bats` を追加 |

## 設計考慮事項

### 1. 冪等性ロジック + サブコマンド分割（GATE-7 / GATE-15）

`bin/gh-project-cli.sh` は `config/github-project-spec.yaml`（desired state）を読み込み、サブコマンド単位で plan / apply を分離する:

```text
bin/gh-project-cli.sh ensure-project [--dry-run] [--strict|--soft]
  spec.project.{title, visibility, owner} を desired として
  current = gh project list --owner @me --format json | jq '.projects[] | select(.title==spec.title)'
  if current: return existing.number（idempotent）
  else if dry-run: print "would create project: ..."
  else: gh project create --owner @me --title "$title" + visibility 設定

bin/gh-project-cli.sh ensure-fields [--dry-run] [--strict|--soft]
  spec.fields[] を desired として
  for each field in spec.fields:
    current = gh project field-list --owner @me $project_number --format json | jq '.fields[] | select(.name==field.name)'
    if current: 既存 options との差分のみ追加（apply）/ diff 出力（dry-run）
    else: gh project field-create + options

bin/gh-project-cli.sh ensure-views [--dry-run] [--strict|--soft]
  spec.views[] を desired として
  for each view in spec.views:
    current = gh project view-list --owner @me $project_number --format json | jq '.views[] | select(.name==view.name)'
    if current: skip（idempotent）
    else: 新規作成（GraphQL `createProjectV2View` 経由 / 不安定時は UI 案内へ降格 + audit-summary.json に flag）

bin/gh-project-cli.sh sync-items [--dry-run] [--strict|--soft]
  対象 Open Issue 集合を抽出（Issue #524 本文 + backlog ラベル）
  for each issue:
    current = gh project item-list --owner @me $project_number --format json | jq '.items[] | select(.content.url==issue.url)'
    if current: Status/Priority/Cycle が spec から派生される値と差分があれば update（apply）/ diff 出力（dry-run）
    else: gh project item-add + 初期値セット

bin/gh-project-cli.sh audit [--check workflow-item-closed|spec-conformance|all]
  bin/audit-github-project.sh を委譲呼び出し
```

各サブコマンドは独立した exit code を返し、`bin/setup-github-project.sh` は orchestrator として順次呼び出す:

```text
bin/setup-github-project.sh [--dry-run] [--strict|--soft]
  bin/gh-project-cli.sh ensure-project ... || exit
  bin/gh-project-cli.sh ensure-fields ... || exit
  bin/gh-project-cli.sh ensure-views ... || exit
  bin/gh-project-cli.sh sync-items ... || exit
```

### 2. スコープ事前チェック + strict/soft モード（GATE-12）

```text
bin/lib/gh-scope-check.sh::check_required_scopes [--strict|--soft] scopes...:
  status = gh auth status 2>&1
  current_scopes = parse "Token scopes: '...'" line
  missing = required - current
  if missing:
    if mode == strict:
      printf '{"status":"scope_missing","missing":[%s]}' >&2 (JSON)
      echo "ERROR: missing scopes: $missing" >&2
      echo "Run: gh auth refresh -s ${missing// /,}" >&2
      return 2  # fatal
    else:  # soft
      echo "WARN: missing scopes: $missing" >&2
      echo "Run: gh auth refresh -s ${missing// /,}" >&2
      jq -n --argjson missing "[\"...\"]" '{status:"scope_missing",missing:$missing,mode:"soft"}' \
        > .aidlc/cache/gh-project-last-run.json
      return 0  # 続行（呼出側でスキップ判断）
  return 0
```

呼出側のモード割り当て（GATE-12 / R2 指摘 #3 / R3 指摘 #1 反映で apply 系を strict に統一）:

| 呼出側 | デフォルトモード | 理由 |
|--------|-----------------|------|
| `bin/setup-github-project.sh`（apply 経路） | `--strict` | 実環境 apply は失敗を即時検出（fail-fast） |
| `bin/gh-project-cli.sh ensure-* / sync-items`（apply 経路） | `--strict` | 同上 |
| `bin/migrate-issue-524.sh`（apply 経路） | `--strict` | Issue 編集は失敗を即時検出 |
| `bin/probe-github-project.sh`（write 副作用あり） | `--strict` | sandbox 操作は失敗を即時検出 |
| 上記 apply 系の `--dry-run` 単独経路 | `--soft` | 参照のみで非破壊 |
| `bin/audit-github-project.sh`（read-only） | `--soft` | 評価のみ。CI / リリース系では `--strict` を明示指定 |
| CI ワークフロー（audit 含む） | `--strict`（明示指定） | 失敗を即時検出 |
| `skills/aidlc/steps/inception/02-preparation.md` ステップ17 | `--soft` | 既存挙動フォールバックを優先 |

`bin/gh-project-cli.sh` および周辺スクリプトは `--strict` / `--soft` をユーザーが明示指定可能、未指定時は上記デフォルトを使用する。

### 3. ビュー作成の制約 + 宣言的仕様（GATE-15）

`gh project view-create` の現行 CLI サポートは限定的。`config/github-project-spec.yaml` に各ビューを宣言:

```yaml
views:
  - name: Roadmap
    layout: roadmap_layout
    fields: [Cycle, Status]
    apply_strategy: graphql  # CLI 不可なら graphql、それも不可なら manual
  - name: Backlog Board
    layout: board_layout
    group_by: Status
    apply_strategy: cli
  - name: Priority Table
    layout: table_layout
    fields: [Priority, Type, Status, Cycle]
    filter: "is:open"
    apply_strategy: graphql
  - name: Feedback View
    layout: table_layout
    filter: "label:type:feedback is:open"
    apply_strategy: graphql
```

`bin/gh-project-cli.sh ensure-views` は `apply_strategy` に従い CLI / GraphQL / UI 案内を切り替える。GraphQL 不安定時は UI 案内へ降格 + `audit-summary.json` に flag。Phase 1 論理設計で具体的な GraphQL クエリ・降格基準を確定。

### 4. Item 一括投入の対象抽出 + Cycle 正規化（GATE-5 / R2 指摘 #1 で spec 内包に変更）

```text
1. Issue #524 本文から URL 抽出: gh issue view 524 --json body | jq -r '.body' | grep -oE 'https://github.com/[^ )]+/(issues|pull)/[0-9]+'
2. backlog ラベル付き Open Issue: gh issue list --label backlog --state open --json url --limit 200
3. union を取り、Issue 番号昇順にソート
4. 各 Issue について:
   - gh project item-add
   - Status = Backlog（初期値）
   - Priority = label `priority:high|medium|low` から派生
   - Cycle = Milestone から spec 内 cycle_map 経由で派生（後述）
```

**Cycle 正規化マップ（`config/github-project-spec.yaml` 内 `cycle_map` セクション）**:

```yaml
cycle_map:
  patterns:
    - milestone_pattern: "^v\\d+\\.\\d+\\.\\d+$"
      cycle_label: "<milestone-title>"
  fallback: "Later"
  delete_handling: "Later"
```

評価ロジック:

1. Issue の milestone を取得（`gh issue view <N> --json milestone`）
2. `milestone.title` を `patterns[].milestone_pattern` に対して順次照合
3. マッチしたら `cycle_label`（`<milestone-title>` プレースホルダ展開）を返す
4. マッチなし / milestone なし / 削除済み → `fallback`（`Later`）を返す

これにより Milestone 命名変更（例: `v2.6.0` → `v2.6.0-stable`）時は spec 内 `cycle_map` セクションのパターンだけ改訂すれば追従可能。spec.yaml が SoT 単一系統となる（R2 指摘 #1）。

### 5. Issue #524 リダイレクト化の保護

```text
bin/migrate-issue-524.sh:
  1. 現本文を .aidlc/cycles/v2.6.0/operations/issue-524-backup.md にバックアップ
  2. 新本文テンプレート:
     # ロードマップ管理は GitHub Projects へ移行しました（v2.6.0〜）

     - Project: <Project URL>
     - 運用ルール: docs/development/github-projects-setup.md
     - Inception 開始時の Project 参照手順は AI-DLC `start inception` フローに統合済
  3. dry-run: diff 出力のみ
  4. 本実行: gh issue edit 524 --body-file <new-body>
```

### 6. AI-DLC 統合の最小侵襲

`skills/aidlc/steps/inception/02-preparation.md` ステップ17 への追記は以下の構造を維持:

```text
17. バックログ確認
    a. GitHub Projects 参照（gh_status=available + project スコープあり）:
       - Project URL: <Project URL>
       - gh project item-list --owner @me <number> --format json | jq '...' で次サイクル候補抽出
    b. フォールバック（gh_status != available または project スコープ不足）:
       - 既存挙動: gh issue list --label backlog --state open
```

### 6.5 probe / audit 2 段責務分離（GATE-6 / GATE-15 / R2 指摘 #2 / R3 指摘 #2 反映）

GATE-6（workflow 有効化検証）+ GATE-15（spec 整合監査）は **probe（write 副作用）** と **audit（read-only 評価）** の 2 段責務に分離する。`bin/probe-github-project.sh` が副作用操作、`bin/audit-github-project.sh` は probe が出力した evidence と現在の状態の評価のみを行う。

#### `bin/probe-github-project.sh`（write 副作用 / デフォルト strict）

```text
bin/probe-github-project.sh --probe workflow-item-closed [--strict|--soft]

probe workflow-item-closed:
  1. sandbox Issue を作成（label: audit-sandbox / タイトルはタイムスタンプ付）
  2. Project に追加し、close する
  3. 操作タイムスタンプ・sandbox Issue 番号・Project Item ID を probe-evidence.json に記録
     例: { probe: "workflow-item-closed", sandbox_issue: 999, project_item_id: "PI_xxx", closed_at: "2026-05-10T..." }
  4. probe 完了後の sandbox Issue cleanup は probe 自身が責任を持つ（成功/失敗に関わらず削除を試行）
  5. probe 自体は「副作用が完了したか」のみを判定（Status 遷移評価は audit 側）
```

#### `bin/audit-github-project.sh`（read-only / デフォルト soft、CI は strict 明示）

```text
bin/audit-github-project.sh [--check workflow-item-closed|spec-conformance|all] [--strict|--soft]

audit workflow-item-closed:
  1. probe-evidence.json を読み込む（不在なら fail / probe 未実行を要求）
  2. 記録された Project Item ID の Status を gh project item-list 経由で read-only 取得
  3. probe.closed_at から 30 秒以内に Status=Done に遷移したかを評価
  4. 結果を audit-summary.json に記録: { workflow_item_closed: pass|fail, evidence_ref: probe-evidence.json, ... }
  ※ sandbox Issue の作成・close・削除は一切行わない（probe の責務）

audit spec-conformance:
  1. config/github-project-spec.yaml を desired として読み込む
  2. 実 Project の current state を read-only で取得（gh project field-list / view-list / item-list）
  3. desired vs current で差分計算
  4. 差分を audit-summary.json に記録: { spec_conformance: pass|drift, drifts: [...] }
```

#### 実行順と障害切り分け

```text
正常系: probe → audit → 両方 pass
probe 失敗: probe-evidence.json 不完全 → audit は前提不満で fail（probe 失敗が原因と切り分け可能）
audit 失敗（probe 成功時）: workflow が期待通り動作していない（GitHub 側の問題と切り分け可能）
```

UI 手動工程は spec 内に `manual_action` として宣言され、本 2 段機構で必ず確認される（投げっぱなし禁止 / GATE-15）。

### 7. 既存ガイド照合（CLAUDE.md ルール準拠）

設計レビュー時に以下のガイドとの整合性を確認:

- `guides/exit-code-convention.md`: `bin/setup-github-project.sh` / `bin/migrate-issue-524.sh` の exit code 規約
- `guides/error-handling.md`: gh 失敗時のリトライ / エラーハンドリング
- `guides/backlog-management.md`: Project 化に伴う運用ルール変更の整合性

## レビュー戦略

- **設計レビュー**: codex で `reviewing-construction-design`（冪等性ロジック / 単方向同期方針 / Project workflow 有効化方法 / スコープ事前チェック設計）
- **コードレビュー**: codex で `reviewing-construction-code`（シェル安全性 / dry-run 完全性 / GraphQL クエリ正確性 / バックアップ機構）
- **統合レビュー**: `codex review --base main`（移行スクリプト網羅性 / Issue #524 リダイレクトの可逆性 / AI-DLC スキル統合の最小侵襲性）

## リスク・トレードオフ

| リスク | 軽減策 |
|------|------|
| Project 作成後の取り消し困難 | dry-run で事前確認 + 命名 / Visibility をユーザー承認 + Project は削除可能（`gh project delete` で取り消し可） |
| `gh project view-create` CLI 制限で Roadmap ビューが作れない | GraphQL `createProjectV2View` を直接呼ぶ。それも不安定なら GitHub UI 操作手順をドキュメント化 |
| Issue #524 本文編集が他コラボレーター運用に影響 | 旧本文を `operations/issue-524-backup.md` にバックアップ + Issue #524 内に「移行履歴」コメント追加 |
| `Item closed` workflow が GraphQL で安定しない | GitHub UI 操作で有効化 + sandbox Issue で実証手順をドキュメント化 |
| Item 一括投入で既存 Issue の Milestone / ラベルが上書きされる | Project への追加のみ実行、Issue 自体は変更しない（`gh project item-add` は Issue を変更しない） |
| Project URL を含む生成ファイルがコミット時に環境依存になる | Project URL は `.aidlc/config.toml` の `[github_projects].project_url` として管理、スクリプトは設定経由で参照 |
| スコープ不足検出時に AI-DLC フローが止まる | exit 0 (warn のみ) で続行、既存挙動にフォールバック |
| 冪等性チェックの API レート制限 | `gh project list` / `field-list` 等は実行回数を最小化（1 回キャッシュ） |
| ドキュメント大量更新で他 Unit と衝突 | 本 Unit が v2.6.0 最終 Unit のため衝突なし（cycle/v2.6.0 ブランチ単独編集） |

## 検証コマンド

### 工程 E1（`[実装]` / モック・fixture 検証）

```bash
# bats テスト（モック / fixture 経由）
bats tests/bin/gh-project-cli.bats \
     tests/bin/setup-github-project.bats \
     tests/bin/migrate-issue-524.bats \
     tests/bin/probe-github-project.bats \
     tests/bin/audit-github-project.bats \
     tests/bin/lib/gh-scope-check.bats

# スクリプト冪等性確認（モック経由 / 2回実行で diff なし）
bin/gh-project-cli.sh ensure-project --dry-run --strict | tee /tmp/run1.log
bin/gh-project-cli.sh ensure-project --dry-run --strict | tee /tmp/run2.log
diff /tmp/run1.log /tmp/run2.log

# strict / soft モード両方の exit code 検証
bin/lib/gh-scope-check.sh --strict project,read:org,read:project; echo "strict exit: $?"
bin/lib/gh-scope-check.sh --soft   project,read:org,read:project; echo "soft   exit: $?"

# spec / cycle_map 構造検証（cycle_map は spec 内包 / R2 指摘 #1）
yq eval '.project.title' config/github-project-spec.yaml
yq eval '.cycle_map.patterns' config/github-project-spec.yaml
yq eval '.cycle_map.fallback' config/github-project-spec.yaml

# AI-DLC ステップ17 の Project 参照確認
grep -nE "Projects|gh-project-cli" skills/aidlc/steps/inception/02-preparation.md

# README / CHANGELOG 反映確認
grep -nE "GitHub Projects" README.md CHANGELOG.md
```

### 工程 E3 / E4（`[実行]` / 実環境検証）

```bash
# 実環境 dry-run 冪等性
bin/setup-github-project.sh --dry-run --soft | tee /tmp/real-run1.log
bin/setup-github-project.sh --dry-run --soft | tee /tmp/real-run2.log
diff /tmp/real-run1.log /tmp/real-run2.log

# Project 構造確認
gh project view <number> --owner @me

# Issue #524 リダイレクト確認
gh issue view 524 --json body | jq -r '.body' | head -10

# 監査
bin/audit-github-project.sh --check all --strict
```

## 工程 D（実環境移行）の承認ポイント

CLAUDE.md「リスクの高いアクション」ポリシーに従い、以下の各ポイントで実行前にユーザー承認を取得する:

| 承認ポイント | 内容 | 取り消し性 |
|------------|------|----------|
| D1: スコープ拡張 | ユーザー手動作業（`gh auth refresh ...`）の完了確認 | - |
| D2: Project 作成 | `bin/gh-project-cli.sh ensure-project` 本実行 | `gh project delete` で取り消し可能 |
| D3: フィールド / ビュー定義 | `bin/gh-project-cli.sh ensure-fields/ensure-views` 本実行 | 個別削除可能 |
| D4: workflow 有効化 | GitHub UI 操作（ユーザー） | UI で無効化可能 |
| D5a: workflow probe 実行（副作用あり） | `bin/probe-github-project.sh --probe workflow-item-closed`（sandbox Issue を自動作成・close・削除し probe-evidence.json を出力） | probe 自身が sandbox cleanup を保証（成功/失敗どちらでも削除を試行） |
| D5b: workflow audit 実行（read-only） | `bin/audit-github-project.sh --check workflow-item-closed`（probe-evidence.json を入力に Status 遷移を read-only 評価） | 監査のみ（変更なし） |
| D6: Item 一括投入 | `bin/gh-project-cli.sh sync-items` 本実行 | Item 単位で削除可能 |
| D7: Issue #524 リダイレクト化 | `bin/migrate-issue-524.sh` 本実行 | バックアップから本文復元可能 |
| D8: spec 整合監査 | `bin/audit-github-project.sh --check spec-conformance`（read-only） | 監査のみ（変更なし） |

`automation_mode=semi_auto` でも本承認ポイントは AskUserQuestion を必須とする（CLAUDE.md ポリシー優先）。
