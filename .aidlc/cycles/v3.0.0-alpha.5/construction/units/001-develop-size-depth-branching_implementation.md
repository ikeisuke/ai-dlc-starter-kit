# 実装記録: Unit 001 develop size×depth_level 分岐基盤

## 実装日時
2026-06-25（計画 → 設計 → 実装 → 完了処理を 1 セッションで実施）

## 作成ファイル

### ソースコード（実行手順 markdown / 既存スクリプト利用配線）
- `skills/aidlc-v3/steps/develop.md` - Step 1 の `size != tiny` 停止ブロックを size×depth_level 分岐（MatrixDecision 構築）に置換。depth_level 解決（read-config.sh / standard 正規化）・size enum 検証・§8 写像表・エラー停止（risky_minimal / invalid_size / invalid_artifact_path）・Unit 001 スコープ境界ガード（design/review 必須は status 遷移前に副作用なし停止）・成果物パス導出・Step 2/5 分岐配線・Step 6 理由記録を追記。新規スクリプトは追加せず既存安全境界（work-item-next / work-item-status / read-config）へ委譲。
- `docs/v3/workflow.md` - SoT 整合: §3.2 Step 2/5 に「正本は data-model.md §8」注記、§6.3 マトリクス表を「非正本ビュー」と明記。

### テスト
- `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` - size×depth_level 分岐に対応。純粋関数 `decide_matrix`（§8 materialized view）導入で 9 有効セル + risky_minimal + invalid_size を全フィールド assert。`run_develop`（depth_level 引数化 / decide_matrix 参照）。normal+minimal end-to-end 完走 / risky+minimal 停止 / tiny+comprehensive 理由記録 / tiny+minimal 非回帰 / invalid_size / invalid_artifact_path（001.md fixture, rc25）の各テストを追加。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/domain-models/unit_001_develop_size_depth_branching_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/logical-designs/unit_001_develop_size_depth_branching_logical_design.md`

## ビルド結果
N/A（markdown + bash。ビルド工程なし）

## テスト結果
成功

- 実行テスト数: 73（test-develop-flow.sh）
- 成功: 73
- 失敗: 0

```text
test-develop-flow.sh: PASS=73 FAIL=0（bash -n / shellcheck clean）
非回帰（既存テスト群）: activation 19 / cycle-resolution 12 / define 79 / frontmatter 67 / state 88 / work-item-next 33 = 計 298 PASS / 0 FAIL
markdownlint（develop.md / workflow.md）: 0 error
```

## コードレビュー結果
- [x] セキュリティ: OK（外部入力は work item frontmatter size / config depth_level のみ。injection リスクなし。focus=security 指摘 0 件）
- [x] コーディング規約: OK（局所 grep/sed パース不追加 / #733 P1/P2 / ドッグフーディング特殊処理なし / Bash ツール置換禁止遵守）
- [x] エラーハンドリング: OK（risky_minimal / invalid_size / invalid_artifact_path を status 遷移前に副作用なし停止 / depth_level 読取失敗は standard 正規化で継続）
- [x] テストカバレッジ: OK（§8 9 セル + エラー系 + 非回帰）
- [x] ドキュメント: OK（設計-実装-テストで MatrixDecision 契約整合 / SoT は data-model.md §8）

## 技術的な決定事項
- 判定の正本は `docs/v3/data-model.md` §8。develop.md / decide_matrix はその materialized view（二重定義回避）。
- 新規スクリプトを作らず既存安全境界スクリプトへ委譲（v3 の最小成果物方針 / extend 採用）。
- design/review 生成本体は Unit 002/003 の責務。Unit 001 は分岐配線まで確立し、design/review 必須セルは Unit 001 スコープ境界ガードで status 遷移前に副作用なし停止（Unit 002/003 実装時に解除）。
- error_reason は 2 系統（§8 写像由来: risky_minimal/invalid_size、path guard 由来: invalid_artifact_path）に分類。

## 課題・改善点
- design 生成本体（Unit 002）/ review 実行本体（Unit 003）/ 全 size×depth_level 組合せ回帰テスト（Unit 004）は後続 Unit で実装。
- `invalid_artifact_path` は work-item-next が id をファイル名から導出するため通常到達しない防御的チェック（ハイフン無しファイル名でのみ到達 / テスト済み）。

## 状態
**完了**

## 備考
AI レビュー（codex / review_mode=required）: 計画 3R / 設計 2R / コード 3R / 統合 3R、全 11 指摘 resolved、defer 0 件、全ゲート auto_approved（semi_auto / unresolved_count=0）。
