# 論理設計: Unit 004 develop normal/risky 回帰テスト + 全マトリクス統合検証

## 概要

`test-develop-flow.sh` に追加する「§8 データ駆動 conformance テスト」と「外部レビュー CLI 非依存の poison PATH
回帰アンカー」のコンポーネント構成・テーブル構造・実行フローを定義する。本体スクリプトは変更しない（テスト専用）。

**重要**: コードは書かず、テスト構造とインターフェースのみを定義する。

## アーキテクチャパターン

**データ駆動テスト（Table-Driven Test）+ 既存ヘルパー再利用**: §8 期待値を行データのテーブルで表現し、単一ループで
反復照合する。`run_develop` / `decide_matrix` / `assert_cond` / `make_sandbox` / `put_work_item` 等の既存ヘルパーを
再利用し、新規ロジックを最小化する。SoT（§8 / decide_matrix）はビューとして参照し再判定しない。

## コンポーネント構成

### レイヤー / モジュール構成

```text
test-develop-flow.sh（既存 / 末尾に増分追加）
├── 既存ヘルパー（再利用）: run_develop / decide_matrix / decide_review_routing / upsert_review_section /
│                            make_sandbox / put_work_item / assert_cond / assert_out / snapshot
├── [新規] §8 conformance テストブロック
│   ├── conformance テーブル（size, depth, 期待 rc/status/design/reviews/perspective の行データ）
│   └── conformance ループ（各行で run_develop → 観測値 assert）
└── [新規] poison PATH 回帰アンカーブロック
    ├── poison スタブ設置（codex/claude/gemini → 痕跡記録）
    └── poison PATH 下で conformance ループ相当を実行 → 痕跡空を assert
```

### コンポーネント詳細

#### §8 conformance テストブロック

- **責務**: §8 全有効組合せ + risky_minimal を単一テーブルループで照合
- **依存**: `run_develop`（観測値生成）、`decide_matrix`（期待値の SoT ビュー / テーブルは §8 と一致）
- **公開インターフェース**: なし（トップレベルテストブロック）

#### poison PATH 回帰アンカーブロック

- **責務**: conformance ループ相当を poison PATH 下で実行し、実 CLI 未呼出を検証
- **依存**: `run_develop`、一時 bindir スタブ
- **公開インターフェース**: なし

## スクリプトインターフェース設計

### conformance テーブル（行データ構造）

各行を `|` 区切り文字列（既存 decide_matrix 様式に倣う）または bash 配列で表現する:

```text
# size|depth|expected_rc|expected_status|expected_design|expected_reviews|expected_perspectives
tiny|minimal|0|done|0|0|-
tiny|standard|0|done|0|0|-
tiny|comprehensive|0|done|0|0|-
normal|minimal|0|done|0|0|-
normal|standard|0|done|1|1|Code
normal|comprehensive|0|done|1|1|Code
risky|standard|0|done|1|1|Code
risky|comprehensive|0|done|1|1|Code+Design
risky|minimal|24|pending|0|0|-
```

- `expected_status`: rc=24（risky_minimal）は status 遷移なし（put_work_item の初期 `pending` のまま / 副作用なし）
- `expected_perspectives`: `reviews/<id>-<slug>.md` 内に存在すべき `## Code Review` / `## Design Review` の集合
  （`-` = reviews 非生成 / `Code` = Code のみ / `Code+Design` = 両方）
- 期待値は §8 / `decide_matrix` と厳密一致（テーブルは §8 のビュー / 再判定しない）

### conformance ループの処理フロー

**ステップ**:
1. テーブル各行をパース（size / depth / expected_*）
2. `make_sandbox` で隔離 repo を作成し `put_work_item` で `001` work item（当該 size / pending）を配置・初期 commit
3. `run_develop <repo> <cycle> <depth>` を実行し rc を取得
4. **rc 照合**: `assert_cond` で `rc == expected_rc`
5. **status 照合**: `work-item-status.sh --read` で `expected_status` と一致
6. **design 照合**: `designs/001-<slug>.md` の存在が `expected_design` と一致
7. **reviews 照合**:
   - `expected_reviews=1`: `reviews/001-<slug>.md` が存在
   - `expected_reviews=0`: 対象ファイル不存在に加えて **`reviews/` ディレクトリ自体が非生成**であることを assert
     （既存テストの慣例に合わせ、空の `reviews/` を作る副作用も検出する / 設計レビュー #1）
8. **perspective 照合**: reviews 生成時、`## Code Review` / `## Design Review` の有無が `expected_perspectives` と一致
9. **tiny_* reviews 非生成**: tiny の全 depth（minimal/standard/comprehensive）で `reviews/` ディレクトリ非生成を
   明示確認（§2.1 ギャップ補完 / 特に未 assert だった tiny_minimal・tiny_comprehensive を固定）

**関与するコンポーネント**: §8 conformance テストブロック, run_develop（既存）

### poison PATH 回帰アンカーの処理フロー

**ステップ**:
1. sandbox 内に一時 bindir（`$TMPROOT/poison-bin`）を作成
2. `codex` / `claude` / `gemini` の poison スタブを設置（実行されたら `$TMPROOT/poison-trace` に自名を追記して exit 0）
   スタブは実行ビット付与（`chmod +x`）
3. `PATH` を退避し、先頭に poison bindir を差し込む（`PATH="$poison_bin:$PATH"`）
4. poison PATH 下で代表的な develop フロー（少なくとも review を伴う risky_comprehensive 等 + 全 conformance 行）を実行
5. `PATH` を復元する
6. **痕跡照合**: `$TMPROOT/poison-trace` が**存在しない or 空**であることを `assert_cond` で確認（= 実 CLI 未呼出）

**関与するコンポーネント**: poison PATH 回帰アンカーブロック, run_develop（既存）

## データモデル概要

### ファイル形式（テスト内一時ファイル）

- poison スタブ: `$TMPROOT/poison-bin/{codex,claude,gemini}`（実行可能なシェルスクリプト / 呼ばれたら痕跡追記）
- 痕跡: `$TMPROOT/poison-trace`（呼ばれた CLI 名の追記先 / 空であるべき）
- すべて `mktemp -d` 配下の sandbox に閉じる（`trap 'rm -rf "$TMPROOT"' EXIT` で既存クリーンアップに乗る）

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: テストは実 CLI 非依存で短時間に完了する
- **対応策**: run_develop は CLI を呼ばず決定的に模擬。poison PATH ガードがこの非依存を保証

### セキュリティ
- **要件**: 該当なし（Unit NFR）
- **対応策**: -

### 可用性
- **要件**: 該当なし（Unit NFR）。ただし「実 CLI 非依存で完了」が poison PATH で担保される
- **対応策**: poison PATH 回帰アンカー

## 実装上の注意事項
- **テスト分離（`bin/check-test-isolation.sh`）**: poison スタブ・PATH 変更は `mktemp -d` sandbox に閉じ、実環境の
  PATH/CLI を汚さない。`PATH` は退避・復元する。実行後 `trap` で sandbox 削除
- **SoT 二重定義回避**: conformance テーブルは §8 / decide_matrix のビュー。テスト内で §8 を再判定しない
- **増分境界**: 既存 per-combo テストを置換せず追加。重複する単純 assert は新規作成しない
- **本体非変更**: develop.md / run_develop / decide_matrix は変更しない（テスト専用ユニット）
- **shellcheck / bash -n clean**: 既存ハーネスの assert/間接呼び出しの `# shellcheck disable=SC2329` 慣例に倣う
- **ガイド照合（v1.27.3）**: 終了コード規約（`guides/exit-code-convention.md`）と整合（テスト本体は 0/1 で集計）

## 不明点と質問（設計中に記録）

[Question] poison PATH 下で全 conformance 行を実行するか、代表ケースのみか。
[Answer] 全 conformance 行を poison PATH 下で実行する（計画レビュー #1 の推奨 = ループ全体を poison PATH 下で実行）。
これにより review を伴う組合せ（normal/risky）も含めて実 CLI 未呼出を網羅的に保証する。

[Question] conformance テーブルの期待値は decide_matrix を呼んで動的生成するか、静的テーブルで持つか。
[Answer] 静的テーブルで持つ（§8 の人間可読なビューとして固定）。ただし decide_matrix の既存 assert（§8 マトリクス写像）が
別途存在するため、conformance は run_develop の**観測結果**（成果物・rc・status）の照合に集中し、decide_matrix 内部判定の
再検証はしない（責務分離 / 二重検証回避）。
