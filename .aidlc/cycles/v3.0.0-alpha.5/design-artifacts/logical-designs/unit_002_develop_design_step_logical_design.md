# 論理設計: Unit 002 develop Step 2（設計生成）+ design テンプレート

## 概要

develop.md Step 2（現行プレースホルダ 行 178-186）を実装し、Unit 001 の `MatrixDecision` を消費して `designs/<id>-<slug>.md` に design 成果物を生成する論理設計。`skills/aidlc-v3/templates/design.md` を新設し、`design_mode` と条件付きセクションフラグ（`risk_analysis` / `test_plan` / `rollback_note`）で design 構成を決める。Unit 001 の Step 1 末尾スコープ境界ガードを Step 2→Step 3 間へ移設し、design 必須セルは design 生成後 review 境界（Unit 003 未実装）で停止させる。

**重要**: 本設計では**コードは書かず**、develop.md（markdown 実行手順）の改訂構造・design テンプレート構造・既存テスト harness の拡張方針のみを定義する。具体的な手順本文・テンプレート本文・テストは Phase 2 で作成する。

## アーキテクチャパターン

- **パイプライン + 判定結果消費 + テンプレート充足**: develop フローは Step 直列実行のパイプライン。Unit 002 は Step 2 で MatrixDecision（Unit 001 が構築）を消費し、design テンプレート（`templates/design.md`）を起点に DesignComposition に従って条件付きセクションを充足/省略して `designs_path` に生成する。判定（§8 写像）は Unit 001、生成（テンプレート充足）は Unit 002 と責務分離する。
- **選定理由**: §8 の単一正本（data-model.md）を Unit 001 経由で消費し二重定義を避ける。design 生成を新規スクリプト化せず markdown 手順 + テンプレートで表現し、v3 の最小成果物・最小スクリプト方針に合致する。

## コンポーネント構成

### モジュール構成（develop.md 改訂後の Step 構造 / Unit 002 差分）

```text
develop フロー（skills/aidlc-v3/steps/develop.md）
├── Step 0  前提確認                                    … 不変
├── Step 1  Work Item 選定 + size×depth_level 判定       … Unit 001（末尾スコープ境界ガードを移設 + design preflight 追加）
│   ├── 1-1〜1-4 MatrixDecision 構築（designs_path 導出含む）  … 不変
│   │       ├─ design preflight（design_required=true のみ / status 遷移前）  … ★ 追加（Unit 002）
│   │       │     └─ design テンプレート不在 → rc=27 副作用なし停止（in_progress 化しない）
│   │       └─ 末尾スコープ境界ガード（design||review で停止）  … ★ Step 2→3 間へ移設（Unit 002）
│   └── 1-5 status 読取/遷移                              … 不変
├── Step 2  計画 + 設計      … ★ 本 Unit の主対象（プレースホルダ → 生成本体を実装）
│   ├── 2-1 design_required で分岐（false: スキップ / true: 生成）
│   ├── 2-2 design テンプレート読込（Step 1 preflight で存在保証済み）
│   ├── 2-3 DesignComposition 導出（design_mode + risk_analysis/test_plan/rollback_note）
│   ├── 2-4 designs_path に DesignArtifact 生成（条件付きセクション充足/省略）
│   ├── 2-5 Design 承認ゲート発火（automation_mode 準拠）
│   └── 2-6 ReviewBoundaryGuard（review_required ∧ Unit003 未実装 → Step 3 に進まず停止）  … ★ 移設先
├── Step 3  実装             … 常に実行（Unit 002 では design 必須セルは 2-6 で到達しない）
├── Step 4  検証             … 常に実行（同上）
├── Step 5  レビュー         … review_required で分岐（実行本体は Unit 003）
└── Step 6  完了             … status done + journal + commit 集約（design 必須セルは Unit 003 完了後に到達）
```

### コンポーネント詳細

#### Step 2 生成ブロック（DesignArtifact の生成点）

- **責務**: MatrixDecision を消費し DesignComposition を導出、design テンプレートを充足して `designs_path` に生成、Design 承認ゲートを発火
- **依存**: Unit 001 の MatrixDecision（`design_mode` / `risk_analysis` / `test_plan` / `rollback_note` / `designs_path` / `review_required`）/ `templates/design.md`
- **本 Unit のスコープ**: design 生成 + ゲート + review 境界停止。review 実行・実装・検証は範囲外

#### DesignComposer（DesignComposition 写像）

- **責務**: `design_mode`（本体詳細度）+ 3 条件付きフラグ → 出力セクション集合
- **表現形式**: develop.md Step 2 内の明示規則 + design テンプレートのセクション構造（ドメインモデル「matrix_case → DesignComposition 写像表」と同一内容）
- **依存方向**: develop.md Step 2 → MatrixDecision（Unit 001）/ design テンプレート（参照のみ / 逆依存なし）

#### ReviewBoundaryGuard（移設された時限停止ガード）

- **責務**: design 生成後、`review_required=true` ∧ Unit 003 未実装で Step 3 に進ませず停止（status は in_progress 維持 / done 非遷移）
- **配置**: Step 2 末尾（旧 Step 1 末尾ガードの移設先）。Unit 003 実装時に解除

## テンプレート設計（templates/design.md / 新設）

既存テンプレート（`work-item.md` / `intent.md` / `journal.md`）のスタイルに合わせる。frontmatter は不要（成果物としての design 文書 / state 管理を持たない。work-item.md のみ frontmatter を持つのは status 管理のため）。プレースホルダは `{{ }}`、条件付きセクションは HTML コメントで「条件付き」を明示する。

### セクション構造

```text
# Design {{id}}: {{title}}

（trace: work item <id>-<slug> / matrix_case: {{matrix_case}}）

## Goal                        … 必須。work item の Goal に対応する設計目的
## Context                     … 必須。既存実装・制約・前提（design_mode=simple は要点のみ / full は詳細）
## Design                      … 必須。設計本体（design_mode=simple: 簡易 / full: 詳細 + 任意でシーケンス図）

<!-- 条件付き: risk_analysis=true（comprehensive 系）のときのみ -->
## Risk Analysis               … リスクと緩和策

<!-- 条件付き: test_plan=true（risky+comprehensive）のときのみ -->
## Test Plan                   … テスト方針・観点

<!-- 条件付き: rollback_note=true（risky 系）のときのみ。非空必須 -->
## Rollback Note               … ロールバック手順（risky は非空）
```

- **任意セクション**: comprehensive でのシーケンス図は `## Design` 内の任意要素として扱う（§3.2 / workflow.md / 別セクションを増やさない）
- **テンプレート不在ガード（Step 1 preflight に集約）**: design テンプレート不在の検出点は **Step 1（status 遷移前）の design preflight**（`rc=27` 副作用なし停止）に統一する。Step 2 はテンプレート存在が保証された状態で読み込む（万一の読込失敗は防御的エラーであり、通常の不在検出点ではない）。暗黙のデフォルト生成はしない（NFR 可用性）

## develop.md Step 2 実装設計（手順構造 / コードは書かない）

### Step 2 分岐手順（改訂後）

**前提（Step 1 で実施済み / design preflight）**: `design_required=true` セルは、Step 1 の MatrixDecision 構築時（status 遷移前）に design テンプレート（`templates/design.md`）の存在を preflight 済み。不在なら Step 1 で `rc=27` 副作用なし停止（in_progress 化しない / DesignArtifact 未生成 / 環境設定不備で work item 状態を進めない / 指摘 #1 対応）。したがって Step 2 到達時はテンプレート存在が保証される。

1. MatrixDecision の `design_required` を参照
   - `false`（`tiny_*` / `normal_minimal`）→ Step 2 をスキップ（**repo 追記なし** / 通知のみ）→ Step 3 へ（Unit 001 完走経路 / 不変）
   - `true`（design 必須セル）→ 2 へ
2. design テンプレート（`templates/design.md`）を読み込む（Step 1 preflight で存在保証済み）
3. DesignComposition を導出（`design_mode` + `risk_analysis` / `test_plan` / `rollback_note`）
4. `designs_path`（Unit 001 配線済み）に DesignArtifact を生成（条件付きセクションをフラグ通り充足/省略 / `rollback_note=true` は非空）
5. Design 承認ゲート発火（`automation_mode` 準拠 / 結果は下記「Design 承認ゲートの結果と接続」参照）
6. ゲート結果が `approved`（または `semi_auto` で auto 承認）の場合に限り、ReviewBoundaryGuard: `review_required=true`（design 必須セルは全て該当）∧ Unit 003 未実装 → Step 3 に進まず停止（status は `done` に遷移させず `in_progress` 維持）。以下を案内して終了:

   ```text
   work item <id>（matrix_case: <matrix_case>）の design を生成・承認しました: <designs_path>
   review（Step 5 / Unit 003）は未実装のため、ここで停止します（status: in_progress）。
   ```

### Design 承認ゲートの結果と接続（指摘 #2 対応）

Design 承認ゲートは Step 2-5 で発火し、結果状態を持つ:

| ゲート結果 | 発生条件 | 後続 |
|-----------|---------|------|
| `approved` | `manual` でユーザー承認 / `semi_auto` でフォールバック非該当の auto 承認 | ReviewBoundaryGuard へ進み rc=26 停止 |
| `needs_changes` | `manual` でユーザーが修正要求 / `semi_auto` でフォールバック該当 | design を修正して 4（再生成）→ 5（再ゲート）を反復 |
| `pending` | `manual` で承認待ち（対話中） | ユーザー応答を待つ（停止しない / 対話継続） |

- **rc=26 の成立条件**: 「design 生成済み **かつ Design ゲート approved** かつ review 境界停止（Unit 003 未実装）」。`needs_changes` / `pending` では rc=26 に到達しない。
- **テスト harness（`run_develop`）の扱い**: harness は AI 承認ゲート（対話判断）を模擬しない（Unit 001 と同方針）。したがって harness 上の rc=26 は「**承認ゲートを模擬しない design 生成済み + review 境界停止**」を表す制御コードであり、ゲート approved は実フローの AI 対話レイヤで成立する前提とする。harness は design ファイル生成と status 非遷移のみを検証する。

### Step 1 末尾スコープ境界ガードの移設

- **現行（Unit 001）**: 行 148-154 で `design_required=true || review_required=true` を status 遷移前に副作用なし停止
- **改訂（Unit 002）**: 上記ガードを Step 1 から除去し、Step 2 末尾（ReviewBoundaryGuard）へ移設。これにより design 必須セルは Step 1-5 で in_progress 化 → Step 2 で design 生成 → review 境界で停止する
- **design preflight を Step 1 に追加（status 遷移前 / 指摘 #1 対応）**: `design_required=true` セルは、designs_path 導出（`invalid_artifact_path` ガード）と並んで design テンプレート（`templates/design.md`）の存在を Step 1（status 遷移前）に preflight する。不在 → `rc=27` 副作用なし停止（in_progress 化しない / 環境設定不備で work item 状態を進めない）。これにより「テンプレート不在で status だけ進む部分状態」を構造的に排除する。`invalid_artifact_path`（パス導出ガード）と同じ「Step 1 で Step 2 前提条件を status 遷移前に検証」する配置に統合する
- **エラー停止系は Step 1 に残置**: `risky_minimal` / `invalid_size` / `invalid_artifact_path` は引き続き Step 1 で status 遷移前に副作用なし停止（移設対象外）。`design テンプレート不在`（rc=27）も同じ Step 1 副作用なし停止系に加わる
- **develop.md 散文の表記是正（指摘 #1）**: 行 183 付近の `risk_analysis_required` / `test_plan_required` / `rollback_note_required` を materialized 契約名 `risk_analysis` / `test_plan` / `rollback_note` に統一（行 116 の表が正本 / エイリアス非導入）

## SoT 整合（workflow.md）

| 対象 | 現状 | 改訂 |
|------|------|------|
| `docs/v3/workflow.md` §3.2 Step 2 行 | Unit 001 が既に「実際の design 要否・含むセクションは depth_level により異なる（正本は data-model.md §8）。`risky+standard` は risk analysis / test plan を含まない」と注記済み（行 95） | **大半が充足済み**。Unit 002 は整合を確認し、必要なら design 生成本体の実装に合わせ文言を最小補強する。新たな SoT 重複を作らない |
| `docs/v3/workflow.md` §6.3 マトリクス表 | Unit 001 が「非正本ビュー（正本は §8）」と明記済み（行 277） | 変更なし（維持） |
| `docs/v3/data-model.md` §8 | 唯一の正本（宣言済み） | 変更なし |

> Unit 002 の workflow.md 変更は「§3.2 の design 記述が design 生成本体の実装と矛盾しないかの確認 + 最小補強」に留め、Unit 001 が確立した SoT 構造（§8 正本 / §3.2・§6.3 非正本ビュー）を踏襲する。

## 処理フロー概要

### Step 2 生成フロー（design 必須セル）

1. Step 1 で MatrixDecision 構築 + status を in_progress 化（pending 開始時 `pending→in_progress` / resume は維持）
2. `design_required=true` を確認 → design テンプレート読込（Step 1 preflight で存在保証済み / 不在検出は Step 1 で実施済み）
3. DesignComposition 導出 → `designs_path` に DesignArtifact 生成（条件付きセクション充足/省略）
4. Design 承認ゲート発火
5. ReviewBoundaryGuard で Step 2 完了直後に停止（status: in_progress / done 非遷移 / Step 3/4 副作用なし）

### 分岐挙動まとめ

| matrix_case | Step 2 | 生成物 | 停止点 | status |
|-------------|--------|--------|--------|--------|
| `tiny_*` / `normal_minimal` | スキップ | なし | （Unit 001 完走 / Step 6 で done） | done |
| `normal_standard` | 簡易 design 生成 | `designs/<id>-<slug>.md`（Goal/Context/Design） | Step 2 後 review 境界 | in_progress |
| `normal_comprehensive` | design + risk analysis | + `## Risk Analysis` | Step 2 後 review 境界 | in_progress |
| `risky_standard` | design + rollback note | + `## Rollback Note`（非空） | Step 2 後 review 境界 | in_progress |
| `risky_comprehensive` | design + risk + test + rollback | + 3 条件付きセクション | Step 2 後 review 境界 | in_progress |

## テスト設計（test-develop-flow.sh 拡張 / 詳細は Phase 2）

`run_develop` ドライバを Unit 002 の Step 2 挙動に対応させる。`decide_matrix`（§8 9 セル）は不変。

### run_develop の rc 規約拡張

- **新 rc 追加**:
  - `26 = design 生成済み + review 境界で停止（Unit 003 未実装）/ status=in_progress`（harness 上は承認ゲート非模擬の生成済み境界 / 指摘 #2）
  - `27 = design テンプレート不在（Step 1 preflight / 副作用なし停止 / status 未遷移）`（指摘 #1）
- **rc=21 の扱い**: 現行 21（design/review 必須で副作用なし停止）は、design 必須セルが Step 2 で design 生成するようになるため、design 必須セルでは 26 に置き換わる（21 は design without review / review without design セルでのみ理論上発生するが §8 上そのセルは存在しないため、design 必須セルでは 26 が新しい正規 rc）
- **rc=25（invalid_artifact_path）/ 23 / 24 / 22 は不変**（Step 1 のエラー停止系は移設対象外）。rc=27 も Step 1 副作用なし停止系

### run_develop の Step 2 模擬

design 必須セル（`d_req==1`）で:
1. 成果物パス導出 + `invalid_artifact_path`（25）検証（Step 1 / 不変）
2. **design preflight**: design テンプレート（harness は fixture でテンプレート存在を制御）不在 → rc=27 副作用なし停止（status 読取・遷移より前 / status 未遷移）
3. status 読取 → `pending` なら in_progress 遷移 / `in_progress` は維持
4. `designs_path` に design ファイルを生成（decide_matrix の `risk_analysis` / `test_plan` / `rollback_note` フラグに従い該当セクション見出しを含める / harness は最小内容で生成）
5. Step 3（実装 = `src/<id>.txt` 生成）に**進まず** rc=26 で停止（status は in_progress のまま / done 非遷移）

### 追加テストケース（最小動作確認 / 全マトリクス回帰は Unit 004）

| 観点 | ケース | assert |
|------|--------|--------|
| design 生成 | `normal_standard` 新規（pending 開始） | rc=26 / `designs/<id>-<slug>.md` 存在 / status=in_progress（done 非遷移）/ `src/<id>.txt` 非存在（Step 3 副作用なし） |
| 条件付きセクション | `normal_comprehensive` | design に `## Risk Analysis` 含む / `## Test Plan` 含まない / `## Rollback Note` 含まない |
| 条件付きセクション | `risky_standard` | `## Rollback Note` 含む（非空）/ `## Risk Analysis` 含まない |
| 条件付きセクション | `risky_comprehensive` | `## Risk Analysis` / `## Test Plan` / `## Rollback Note` すべて含む |
| status 区別 | `normal_standard` resume（in_progress 開始） | rc=26 / status=in_progress 維持（二重遷移なし）/ design 生成済み |
| invalid_artifact_path | design 必須セルでファイル名 prefix 不一致 | rc=25（副作用なし / design 未生成） |
| テンプレート不在 | design 必須セルで design テンプレート不在（fixture 制御） | rc=27（副作用なし / status 未遷移 = in_progress でない / design 未生成） |
| 非回帰 | `normal_minimal` 完走 / `tiny_*` 完走 / `risky_minimal` 停止（24）/ `invalid_size`（23） | 既存 assert 不変（Unit 001 経路） |

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 該当なし（Unit 定義 NFR）
- **対応策**: design 生成はテンプレート読込 1 回 + 文章生成のみ。tiny / normal+minimal 経路は不変

### セキュリティ
- **要件**: design 文書に機密情報を含めない
- **対応策**: review-flow.md のマスク方針を準用（秘密鍵・トークン・認証情報をマスク）。design 生成時に AI エージェントがマスク責務を負う

### 可用性
- **要件**: テンプレート不在時は副作用なし停止（暗黙のデフォルト生成をしない）
- **対応策**: **Step 1（status 遷移前）の design preflight** でテンプレート不在を検出し `rc=27` 副作用なし停止（status を遷移させない）。Step 2 は存在保証済みで読み込む

## 実装上の注意事項

- develop.md 内に frontmatter / config の局所 grep/sed パースを足さない（#733 P1/P2 再発防止）。MatrixDecision フィールドは Unit 001 構築結果をそのまま消費
- 「ドッグフーディング特殊処理を本体に埋めない」: 自リポジトリ判定を develop.md / テンプレート / テストに埋め込まない
- Bash ツール経由実行時のコマンド置換禁止（リポジトリ規約）— develop.md は手順記述であり実行例は既存記法（リダイレクト・パイプ）を踏襲
- design 必須セルの停止は status を done に遷移させない（in_progress 維持）。Step 3/4 の副作用（src 生成等）を起こさない
- 条件付きセクションは MatrixDecision のフラグと厳密一致（過剰生成・欠落をしない）

## 技術選定

- **言語**: Markdown（実行手順 + design テンプレート）+ Bash（既存テスト harness 拡張 / 新規スクリプトなし）
- **正本**: `docs/v3/data-model.md` §8（消費は Unit 001 の MatrixDecision 経由）
- **テスト**: `skills/aidlc-v3/scripts/tests/test-develop-flow.sh`（最小の動作確認 / 全マトリクス回帰は Unit 004）

## 設計レビュー時のガイド照合（プロジェクトルール準拠）

- **終了コード規約**: 新 rc=26 は「design 生成済み + review 境界停止」を表す正常境界（エラーではない増分境界）。新 rc=27 は「design テンプレート不在（Step 1 preflight）」の副作用なし停止であり、環境設定不備系（エラー停止系 23/24/25 と同列）として区別する。いずれもテスト harness 内部の制御コードであって CLI のユーザー向け終了コードではない（`guides/exit-code-convention.md` の「警告付き完了を異常終了にしない」方針と整合）
- **エラーハンドリング**: design テンプレート不在は **Step 1（status 遷移前）の preflight で rc=27 副作用なし停止**（暗黙生成しない / status を遷移させない）

## 不明点と質問（設計中に記録）

[Question] なし（計画 AI レビュー 3R で増分境界・フィールド名・副作用様式を確定済み）
[Answer] -
