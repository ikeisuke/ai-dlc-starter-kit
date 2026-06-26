# Unit 004 実装計画: develop normal/risky 回帰テスト + 全マトリクス統合検証

- **サイクル**: v3.0.0-alpha.5（Phase 4 = develop normal/risky 分岐）
- **Unit**: 004-develop-regression-tests
- **depth_level**: standard（Phase 1 設計あり / テスト専用ユニットのため軽量）
- **automation_mode**: semi_auto / review_mode: required
- **関連 Issue**: #736（部分対応 / Phase 4）
- **依存 Unit**: 001 / 002 / 003（すべて完了）

## 1. 目的

`skills/aidlc-v3/scripts/tests/test-develop-flow.sh` を拡張し、`docs/v3/data-model.md` §8 の全有効
size×depth_level 組合せが design / review 成果物の生成有無・rc・status とともに**データ駆動で網羅検証**される
ことを保証する。あわせて develop フローのテストが**実外部レビュー CLI（codex / claude / gemini）に依存しない**
ことを明示的なガードで保証する。tiny 非回帰と既存テスト群（define / state / next / activation / frontmatter /
cycle-resolution）の緑を確認する。

## 2. 既存カバレッジの精査【重要 / 増分境界】

Unit 001〜003 の実装過程（特に Unit 003 の統合レビュー指摘対応）で、§8 の検証は**既に大部分が実装済み**である。
本 Unit は未カバーのギャップのみを増分追加し、重複テストを新規作成しない。

### 2.1 既にカバー済み（再実装しない）

| 検証対象 | 既存テスト箇所 |
|---------|--------------|
| §8 decide_matrix 全セル（design_required / review_required / review_mode 等の全フィールド） | `== §8 マトリクス写像 ==`（3×3 グリッド = 有効 8 + risky_minimal エラー + enum 外 invalid_size） |
| decide_review_routing 写像（matrix_review_mode → perspective/focus/section） | `== review routing 写像 ==` |
| tiny×{minimal,standard,comprehensive} 完走 + 理由記録有無 | tiny+comprehensive/tiny+minimal / tiny+standard e2e |
| normal×{minimal,standard,comprehensive} 完走 + design/review 生成有無 | Unit 003 normal+standard/comprehensive / Unit 001 normal+minimal |
| risky×{standard,comprehensive} 完走 + design/rollback/review 生成有無 | Unit 003 risky+standard/comprehensive |
| risky+minimal エラー停止（副作用なし） | `== Unit 001 エラー停止: risky+minimal ==` |
| review_required=false の reviews 非生成（**一部のみ**: `normal+minimal` と `tiny+standard` は明示 assert 済み。`tiny+minimal` / `tiny+comprehensive` は未 assert → §2.2 conformance で補完） | `== Unit 003: review_required=false ... reviews 非生成 ==` / normal+minimal e2e |
| reviews セクション冪等 upsert / マーカー行頭契約 | `== Unit 003: reviews セクション冪等 upsert ==` |
| エラー停止系（invalid_size 23 / invalid_artifact_path 25 / テンプレート不在 27 / read 異常 22） | 各 Unit 001/002 テスト |

### 2.2 本 Unit で増分追加するギャップ

1. **§8 データ駆動 conformance テスト**: 全 8 有効組合せ（+ risky_minimal エラー）を**単一のテーブルループ**で
   反復し、各組合せについて (rc / status / design ファイル生成有無 / reviews ファイル生成有無 / reviews 内
   perspective セクション) が §8 期待値と一致することを検証する。散在する per-combo テストを補完する
   「§8 全マトリクス回帰アンカー」を 1 箇所に集約する（Unit 定義「全有効組合せの検証」の直接実装）。
   **tiny_* 全件（minimal/standard/comprehensive）の reviews 非生成も本ループで明示 assert し §2.1 のギャップを埋める**
2. **外部レビュー CLI 非依存の poison PATH 回帰アンカー**: 現状の `run_develop` は実 CLI 呼び出し経路を持たず
   review も `upsert_review_section` で模擬するため、本ガードは「フローが実 CLI を呼ばない」ことの直接検証ではなく、
   **「test-develop-flow.sh の模擬 run_develop 実行が実 CLI に依存しない（将来 codex/claude/gemini 呼び出しが
   ハーネスに混入したら検出する）」ことを保証する poison PATH 回帰アンカー**である。codex/claude/gemini の poison
   スタブ（呼ばれたら痕跡を残す）を一時 bindir に置き `PATH` 先頭へ差し込んだ状態で **§8 conformance ループ全体を実行**し、
   実行後にスタブが**一度も呼ばれていない**ことを assert する（Unit 定義「外部レビュー CLI 呼び出しのモック/スタブ化」
   の実装 / NFR 可用性・パフォーマンス = 実 CLI 非依存で短時間完了）

## 3. 実装アプローチ

### 3.1 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | (1) §8 データ駆動 conformance テストブロックを追加（全 8 有効組合せ + risky_minimal を 1 テーブルで反復し rc/status/design 生成有無/reviews 生成有無/perspective セクションを assert）。(2) CLI 非依存ガード（PATH スタブ codex/claude/gemini を一時 bindir に設置し、develop フロー実行後にスタブ呼び出し痕跡が 0 であることを assert）。既存テストの非回帰を維持し重複を作らない |

> 本体スクリプト（develop.md / run_develop）の変更は**行わない**（テスト専用ユニット / 機能本体は Unit 001-003 完了）。

### 3.2 §8 データ駆動 conformance テストの設計

`decide_matrix` 出力を期待値の単一の真実として、各組合せのテーブル行 `(size, depth, 期待 rc, 期待 status, design 有無, reviews 有無, reviews perspective)` を反復する。run_develop を sandbox で実行し、実 rc・status・成果物存在を期待値と照合する:

| size | depth | 期待 rc | 期待 status | design | reviews | reviews perspective |
|------|-------|--------|------------|--------|---------|---------------------|
| tiny | minimal | 0 | done | なし | なし | - |
| tiny | standard | 0 | done | なし | なし | - |
| tiny | comprehensive | 0 | done | なし | なし | -（理由記録は journal） |
| normal | minimal | 0 | done | なし | なし | - |
| normal | standard | 0 | done | あり | あり | Code |
| normal | comprehensive | 0 | done | あり | あり | Code |
| risky | standard | 0 | done | あり | あり | Code |
| risky | comprehensive | 0 | done | あり | あり | Code + Design |
| risky | minimal | 24 | （遷移なし）| なし | なし | -（副作用なし） |

> 期待値は §8 / decide_matrix と厳密一致させる（テーブルは decide_matrix のビューであり再判定しない）。
> tiny+comprehensive の理由記録は journal 側のため reviews perspective には現れない。

### 3.3 CLI 非依存ガードの設計（poison PATH 回帰アンカー）

> **位置づけの明確化（計画レビュー #1）**: 現状 `run_develop` は実 CLI 呼び出し経路を持たず review も模擬のため、本ガードは
> 「フローが CLI を呼ばない」直接検証ではなく、**「模擬 run_develop 実行が実 CLI に依存しない（将来の混入を検出する）」
> ことを保証する poison PATH 回帰アンカー**である（過大表現にしない）。

- テスト用の一時 bindir に `codex` / `claude` / `gemini` の poison スタブを設置（呼ばれたら痕跡ファイルに記録）
- `PATH` の先頭にこの bindir を差し込んだ状態で **§8 conformance ループ全体（全有効組合せ + risky_minimal）を実行**する
- 実行後にスタブ痕跡が**空**（= 一度も呼ばれていない）ことを assert
- これにより「テストの模擬 develop 実行は実レビュー CLI を起動しない（将来混入したら検出する）」ことを構造的に保証する
- スタブと PATH 変更は sandbox（`mktemp -d` 配下）に閉じ、実行後に `PATH` を復元する。`bin/check-test-isolation.sh` の
  テスト分離規約に違反しない

## 4. 完了条件チェックリスト

Unit 定義「責務」セクションから抽出:

- [ ] §8 全有効組合せ（tiny×{minimal,standard,comprehensive} / normal×{minimal,standard,comprehensive} /
      risky×{standard,comprehensive}）をデータ駆動で検証し、各組合せの rc / status / design 生成有無 /
      reviews 生成有無 / reviews perspective が §8 期待値と一致する
- [ ] `tiny + comprehensive` は理由記録追加、`tiny + {minimal,standard}` は Phase 3 挙動から不変であることを検証
- [ ] `risky + minimal` のエラー停止（rc=24 / 副作用なし）を検証
- [ ] design（Unit 002）/ review（Unit 003）の成果物が size×depth_level に従って生成/スキップされることを検証
      （tiny_* 全件の reviews 非生成を含む）
- [ ] §8 conformance ループを poison PATH（codex/claude/gemini スタブ）下で実行し、模擬 run_develop が実 CLI を
      呼ばない（スタブ未呼出）ことを assert する。これにより「テストが実 CLI に依存しない」を回帰アンカーとして保証する（NFR）
- [ ] 既存テスト（define / develop tiny / state / next / activation / frontmatter / cycle-resolution）が全て緑
- [ ] テスト分離規約（`bin/check-test-isolation.sh`）に違反しない。shellcheck clean / bash -n clean
- [ ] 重複テストを新規作成せず、既存カバレッジ（§2.1）と整合する増分のみ追加する

## 5. 境界（本 Unit に含まないもの）

- 機能本体の実装（Unit 001 / 002 / 003 完了済み。develop.md / run_develop の挙動変更は行わない）
- CI ワークフローへのジョブ追加（本 Unit はローカルテストハーネス拡張に限定）
- 実外部 CLI を起動する統合テスト（本 Unit は CLI 非依存を保証する方向）

## 6. リスク・考慮事項

- **重複リスク**: §8 検証は Unit 003 で大部分実装済み。本 Unit はデータ駆動 conformance アンカーへ集約し、
  per-combo の冗長な再実装をしない（§2.1 と照合）
- **CLI スタブの分離**: PATH スタブは sandbox 内に閉じ、テスト終了後に PATH を復元する。実環境の CLI を汚さない。
  `check-test-isolation.sh` 規約を遵守する
- **期待値の SoT**: conformance テーブルは §8 / decide_matrix のビューであり、テスト内で §8 を再判定しない
  （二重定義回避）
- **可用性 NFR**: テストは実 CLI 非依存で短時間完了する（CLI スタブガードがこれを構造的に担保）
