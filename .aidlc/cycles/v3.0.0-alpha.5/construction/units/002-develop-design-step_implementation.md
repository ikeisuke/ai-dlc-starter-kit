# 実装記録: Unit 002 develop Step 2（設計生成）+ design テンプレート

## 実装日時
2026-06-26（計画 → 設計 → 実装 → 完了処理を 1 セッションで実施）

## 作成ファイル

### ソースコード（実行手順 markdown + テンプレート / 既存スクリプト利用配線）
- `skills/aidlc-v3/templates/design.md`（新設） - design テンプレート。frontmatter なし / 必須セクション（Goal/Context/Design）+ 条件付きセクション（Risk Analysis / Test Plan / Rollback Note）。プレースホルダ `{{ }}` と HTML コメントで条件付きを明示（既存 work-item.md スタイル踏襲）。
- `skills/aidlc-v3/steps/develop.md` - Step 2（プレースホルダ）を design 生成本体に実装: MatrixDecision の `design_mode` / `risk_analysis` / `test_plan` / `rollback_note` を消費し条件付きセクションを充足/省略して `designs_path` に生成（2.1）、Design 承認ゲート発火（2.2 / automation_mode 準拠 / approved・needs_changes・pending）、review 境界ガード（2.3 / review_required かつ Unit 003 未実装で Step 3 に進まず停止 / status in_progress 維持）。Step 1 に design preflight（design_required=true セルは status 遷移前に design テンプレート存在を検証 / 不在は副作用なし停止）を追加し、Unit 001 のスコープ境界ガードを Step 1 から Step 2.3 へ移設。散文のフィールド名を decide_matrix 契約名（risk_analysis/test_plan/rollback_note サフィックスなし）に統一。ヘッダ・フロー全体表・Step 5 注記を Unit 002 実装後の状態に更新。
- `docs/v3/workflow.md` - 変更なし（§3.2 の design depth_level/§8 注記・§6.3 非正本ビューは Unit 001 で整備済みで充足。SoT 二重定義回避を維持）。

### テスト
- `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` - `run_develop` を Step 2 対応に書き換え（rc=26 design 生成 + review 境界停止 / rc=27 design テンプレート不在 preflight）。design テンプレート fixture（`DESIGN_TMPL` / 第 4 引数で差し替え）、`section_nonempty` awk ヘルパー（条件付きセクション非空検証）追加。Unit 002 テスト群: normal/risky × standard/comprehensive の rc=26 / 条件付きセクション有無（Risk Analysis / Test Plan / Rollback Note を §8 フラグと厳密一致）/ Rollback Note 非空 / status pending→in_progress・resume in_progress 維持・done 非遷移 / src 非生成（Step 3 未到達）/ design テンプレート不在 rc=27 副作用なし。旧 rc=21 停止テスト（design/review 必須で副作用なし停止）を Unit 002 の design 生成テストへ置換。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/domain-models/unit_002_develop_design_step_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/logical-designs/unit_002_develop_design_step_logical_design.md`

## ビルド結果
N/A（markdown + bash。ビルド工程なし）

## テスト結果
成功

- 実行テスト数: 99（test-develop-flow.sh）
- 成功: 99
- 失敗: 0

```text
test-develop-flow.sh: PASS=99 FAIL=0（bash -n / shellcheck clean）
非回帰（既存テスト群）: activation / cycle-resolution / define / frontmatter / state / work-item-next = All tests passed
markdownlint（develop.md / design.md）: 0 error
```

## コードレビュー結果
- [x] セキュリティ: OK（外部入力は work item frontmatter size / config depth_level / design テンプレートのみ。design 文書への機密情報混入防止を develop.md Step 2.1 に明記。ローカル CLI / markdown のため OWASP HTTP 系・認証・NW は N/A）
- [x] コーディング規約: OK（局所 grep/sed パース不追加 / #733 P1/P2 / ドッグフーディング特殊処理なし / フィールド名は decide_matrix 契約名で統一 / エイリアス非導入）
- [x] エラーハンドリング: OK（design テンプレート不在は Step 1 status 遷移前に rc=27 副作用なし停止 / review 境界は in_progress 維持で done 非遷移 / 実装・検証の副作用なし）
- [x] テストカバレッジ: OK（design 必須 4 セル × 条件付きセクション + status 区別 + テンプレート不在 + 非回帰）
- [x] ドキュメント: OK（設計-実装-テストで MatrixDecision 消費契約・増分境界が整合 / SoT は data-model.md §8）

## 技術的な決定事項
- 増分境界は案A（Step 2 完了直後で停止 / Step 3 実装に進まない）。全 design 必須セルは review 必須のため Unit 002 単体で完走するセルはなく、Unit 003 完了で review 境界ガードを解除し Step 3-6 完走となる。
- design テンプレート不在検証は status 遷移前（Step 1 preflight / rc=27）に配置し、設定不備で status だけ進む部分状態を排除（invalid_artifact_path と同じ「Step 2 前提条件を status 遷移前に検証」配置に統合）。
- Design 承認ゲートは AI 対話イベントのためテスト harness では模擬せず、rc=26 は「承認非模擬の design 生成済み + review 境界停止」を表す制御コードとして扱う。
- rollback note は別ファイルを作らず designs/*.md 内の必須条件付きセクション（v3 の成果物数を増やさない方針）。

## 課題・改善点
- review 実行本体（Unit 003）/ 全 size×depth_level 組合せ回帰テスト（Unit 004）は後続 Unit で実装。
- `design_required=true ∧ review_required=false` のセルは §8 上現状存在しない（将来拡張用に Step 3 fall-through を残置）。

## 状態
**完了**

## 備考
AI レビュー（codex / review_mode=required）: 計画 3R / 設計 3R / コード 2R、全 8 指摘 resolved、defer 0 件、全ゲート auto_approved（semi_auto / unresolved_count=0）。統合レビューは本記録後に実施。
