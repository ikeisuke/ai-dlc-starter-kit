# 実装記録: Unit 004 develop normal/risky 回帰テスト + 全マトリクス統合検証

## 実装日時
2026-06-27

## 作成ファイル

### テスト（拡張のみ / 本体非変更）
- `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` - 以下を末尾に増分追加:
  - `conformance_case` ヘルパー: `run_develop` を隔離 sandbox で実行し、観測 rc / status / design 生成有無 /
    reviews 生成有無（非生成は `reviews/` ディレクトリ不存在まで確認）/ perspective を §8 期待値ビューと照合
  - `CONFTABLE` データ駆動ループ（全 8 有効組合せ + risky_minimal）+ 行整合性 assert（7 列固定 + perspective enum）
  - poison PATH 回帰アンカー: `codex` / `claude` / `gemini` スタブを一時 bindir に設置し `PATH` 先頭へ差込、全
    conformance 行を実行後 `PATH` 復元、スタブ痕跡が空（実 CLI 未呼出）であることを assert

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/domain-models/unit_004_develop_regression_tests_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/logical-designs/unit_004_develop_regression_tests_logical_design.md`

## ビルド結果
N/A（Bash テストハーネス拡張。コンパイル対象なし）

## テスト結果
成功

- 実行テスト数: 191（test-develop-flow.sh）
- 成功: 191
- 失敗: 0

```text
test-develop-flow.sh: PASS=191 FAIL=0
shellcheck（work-item-status.sh / test-develop-flow.sh）: clean
bash -n: clean
check-test-isolation.sh: no violations, 85 files checked
check-bash-substitution.sh: no violations, 35 files checked
既存テスト群（activation/cycle-resolution/define/frontmatter/state/work-item-next）: 非回帰 All passed（全 7 スイート rc=0）
```

## コードレビュー結果
- [x] セキュリティ: OK（poison スタブ・PATH 変更は mktemp sandbox 内に閉じ実行後 PATH 復元 / trap で sandbox 削除 / 分離規約 no violations / ネットワーク・認証は N/A）
- [x] コーディング規約: OK（既存ヘルパー再利用 / 本体非変更 / SoT 二重定義回避 = conformance は §8/decide_matrix のビュー）
- [x] エラーハンドリング: OK（CONFTABLE 行整合性 7 列 + enum 検証でテーブル破損を即検出）
- [x] テストカバレッジ: OK（§8 全マトリクス conformance + tiny_* 全 depth reviews 非生成 + CLI 非依存）
- [x] ドキュメント: OK（設計 2 成果物 / レビューサマリ 4 Set）

## 技術的な決定事項
- conformance は run_develop の**観測結果**（成果物・rc・status・perspective）照合に集中し、decide_matrix 内部判定の
  再検証はしない（責務分離 / 二重検証回避）。§8 期待値は静的テーブル（人間可読ビュー）で保持
- CLI 非依存は poison PATH 回帰アンカーとして実装（run_develop は実 CLI 経路を持たないため、将来の混入検出が目的）
- reviews 非生成は `reviews/` ディレクトリ不存在まで assert し、空ディレクトリ副作用も検出

## 課題・改善点
- なし（本 Unit で Phase 4 develop の全 size×depth_level マトリクスの回帰アンカーが揃った）

## 状態
**完了**

## 備考
- AI レビュー: 計画 2R（中1/低2 resolved）/ 設計 2R（低1 resolved）/ コード 2R（低1 resolved）/ 統合 1R clean。defer 0 件。
- 実装中の知見: `set -u` 下で変数参照が全角約物（`）` 等）に隣接すると変数名解析が崩れるため `${var}` で明示区切りする。
  `assert_cond` は第 2 引数 `0` を pass とするため真偽フラグの初期値・反転に注意する。
