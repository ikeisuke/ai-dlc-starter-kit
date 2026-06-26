# ドメインモデル: Unit 004 develop normal/risky 回帰テスト + 全マトリクス統合検証

## 概要

`test-develop-flow.sh` の §8 全マトリクス回帰検証ドメインを定義する。`docs/v3/data-model.md` §8 の全有効
size×depth_level 組合せに対する develop フローの観測可能結果（rc / status / design・reviews 生成有無 /
perspective）を期待値テーブル（§8 のビュー）と照合する conformance 検証と、外部レビュー CLI 非依存を保証する
poison PATH 回帰アンカーの構造を定義する。

**重要**: 本ユニットは**テスト専用**であり、本体スクリプト（develop.md / run_develop）は変更しない。コードは書かず
構造と責務のみを定義する。

## 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | 既存テスト構造・`decide_matrix` / `decide_review_routing` / `run_develop` / `assert_*` ヘルパー・既存 §8 per-combo テストの把握（重複回避 / 増分境界） |
| `docs/v3/data-model.md` §8 | conformance 期待値テーブルの正本（size×depth_level → design/review 要否） |
| `skills/aidlc-v3/steps/develop.md` Step 1/5 | run_develop の rc・status・成果物生成の挙動契約（期待値の根拠） |
| `bin/check-test-isolation.sh` | テスト分離規約（sandbox / PATH 操作が違反しないことの確認） |

### (b) 設計時に意識すべき挙動

- `run_develop <repo> <cycle> <depth>` は sandbox 内で develop フローを模擬し rc を返す。design は `designs/<id>-<slug>.md`、
  reviews は `reviews/<id>-<slug>.md` に生成。status は `work-item-status.sh --read` で確認
- §8 期待値: tiny_*=design/review なし（tiny_comprehensive は journal 理由記録）/ normal_standard・comprehensive=design+review(code) /
  risky_standard=design+review(code_security) / risky_comprehensive=design+review(code_security_design = Code+Design) /
  risky_minimal=rc24 副作用なし
- `run_develop` は実 CLI を一切呼ばない（review は `upsert_review_section` で模擬）。poison PATH ガードはこの非依存を
  回帰アンカーとして固定する（将来の混入検出）
- 既存テストは §8 を per-combo で散在検証済み。conformance テストはこれを単一ループへ集約する補完であり重複新規作成しない

### (c) 既存実装に基づく代替案検討

| 方針候補 | 既存実装との適合性 | 採否 |
|---------|------------------|------|
| **extend（データ駆動 conformance + poison PATH）**: 既存ヘルパー（run_develop / decide_matrix / assert_*）を再利用し、§8 全組合せをテーブルループで照合 + poison PATH でループ実行 | 既存資産を最大活用し増分最小。SoT（§8/decide_matrix）をビューとして参照 | **採用** |
| per-combo テストを更に追加 | 既に散在カバー済みで重複。単一 conformance アンカーに劣る | 却下 |
| 実 CLI モック（codex を実際に呼ぶスタブ応答） | run_develop は CLI を呼ばないため不要。過剰 | 却下 |

## エンティティ（Entity）

### MatrixConformanceCase（§8 conformance 検証ケース）

- **ID**: `(size, depth_level)`
- **属性**:
  - `size`: enum（tiny / normal / risky）
  - `depth_level`: enum（minimal / standard / comprehensive）
  - `expected_rc`: Integer（0 = 完走 / 24 = risky_minimal エラー停止）
  - `expected_status`: String（done / 遷移なし）
  - `expected_design`: bool（design ファイル生成有無）
  - `expected_reviews`: bool（reviews ファイル生成有無）
  - `expected_perspectives`: Set（Code / Design / 空）
- **振る舞い**:
  - `verify()`: sandbox で `run_develop` を実行し、観測 rc・status・成果物が期待値と一致するか assert

## 値オブジェクト（Value Object）

### MatrixExpectation（§8 期待値 / decide_matrix のビュー）

- **属性**: 上記 expected_* フィールド群
- **不変性**: `docs/v3/data-model.md` §8 / `decide_matrix` 出力に由来し、テスト内で §8 を再判定しない（SoT 二重定義回避）
- **等価性**: (size, depth_level) で一意

### PoisonStubTrace（CLI 非依存痕跡）

- **属性**: `invoked_clis`: List<String>（poison スタブ codex/claude/gemini が呼ばれた痕跡）
- **不変性**: 模擬 develop 実行後に**空であるべき**（実 CLI 非依存の不変条件）

## 集約（Aggregate）

### MatrixConformanceSuite（§8 全マトリクス回帰スイート）

- **集約ルート**: MatrixConformanceSuite
- **含まれる要素**: List<MatrixConformanceCase>（全 8 有効組合せ + risky_minimal）, PoisonStubTrace
- **境界**: §8 全マトリクスの conformance 検証 + CLI 非依存保証を 1 まとまりとして管理
- **不変条件**:
  - 全 MatrixConformanceCase が `verify()` で期待値一致
  - スイート全体を poison PATH 下で実行し、PoisonStubTrace が空（CLI 未呼出）

## ドメインサービス

### PoisonPathGuard（CLI 非依存回帰アンカー）

- **責務**: 一時 bindir に codex/claude/gemini の poison スタブを設置し `PATH` 先頭へ差し込み、conformance ループ実行後に
  スタブ未呼出を検証。実行後 `PATH` を復元（テスト分離）
- **操作**:
  - `with_poison_path(thunk)`: poison PATH 下で thunk（conformance ループ）を実行し、痕跡が空であることを保証

## ユビキタス言語

- **conformance テスト**: §8 期待値テーブルに対する develop フロー観測結果の網羅照合
- **poison PATH 回帰アンカー**: 実 CLI を擬似コマンドで置換し、テスト実行が実 CLI を呼ばないことを検出する仕掛け
- **増分境界**: 既存 per-combo テストを重複再実装せず、単一 conformance アンカー + CLI 非依存ガードのみ追加する範囲

## 不明点と質問（設計中に記録）

[Question] conformance テストは既存 per-combo テストを置換するか、追加するか。
[Answer] 追加（既存は非回帰として残す）。conformance は §8 全マトリクスを単一ループで照合する回帰アンカーであり、
既存の個別ケース（resume / 副作用なし停止の詳細等）を置換しない。重複する単純 assert は新規作成しない。

[Question] poison スタブが呼ばれた場合の挙動（痕跡記録 vs 即 fail）。
[Answer] 痕跡ファイルへ記録方式とする（呼ばれたら追記）。ループ後に痕跡ファイルが空であることを assert することで、
どの CLI がいつ呼ばれたかを診断可能にする（即 fail より回帰原因の特定が容易）。
