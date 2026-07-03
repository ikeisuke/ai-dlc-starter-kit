# 実装記録: Unit 003 develop Step 5（レビュー）+ review routing

## 実装日時
2026-06-26 〜 2026-06-27

## 作成ファイル

### ソースコード（skill steps / SoT）
- `skills/aidlc-v3/steps/develop.md` - Step 5（レビュー）実装。5.0 用語区別（matrix_review_mode vs routing_review_mode）/ 5.1 matrix_review_mode → perspective・focus 写像 / 5.2 review-flow.md 委譲をサブ手順粒度に限定（commit・review-summary・history は使わず Step 6 単一 commit と reviews_path を正本）/ 5.3 reviews_path への perspective 別セクション冪等 upsert（status= マーカー / injection 無害化）/ 5.4 セミオートゲート。Step 2.3 review 境界ガード解除（design 必須セルを Step 3-6 完走化）。冒頭位置づけ注記・フロー全体表・Step 1 分岐注記を Unit 003 実装済みに更新
- `docs/v3/workflow.md` - §6.1 に plan perspective が develop の §8 review 実行マトリクスに materialized されない旨を注記（SoT 不整合を §6.2/§8 正本で確定 / capability ≠ execution）

### テスト
- `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` - `decide_review_routing` 純粋関数（matrix_review_mode → perspective:focus:section 写像）/ `upsert_review_section` ヘルパー（Step 5.3 upsert 規則の materialized 実装 / complete skip・incomplete replace・区間なし追加）/ `run_develop` の境界ガード解除（旧 rc=26 撤去 + Step 5 模擬を upsert 経由化 + fname を d_req||r_req 共通導出）/ Unit 002 旧 rc=26 テストの完走化（rc=0 + done + reviews 生成 + src 生成）/ reviews perspective 別セクション・行頭マーカー構造検証 / tiny_*・normal_minimal の reviews 非生成検証

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/domain-models/unit_003_develop_review_routing_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/logical-designs/unit_003_develop_review_routing_logical_design.md`

## ビルド結果
N/A（Markdown skill steps + Bash テストハーネス。コンパイル対象なし）

## テスト結果
成功

- 実行テスト数: 132（test-develop-flow.sh）
- 成功: 132
- 失敗: 0

```text
test-develop-flow.sh: PASS=132 FAIL=0
shellcheck（work-item-status.sh / test-develop-flow.sh）: clean
bash -n: clean
markdownlint-cli2（develop.md / workflow.md）: 0 error
既存テスト群（activation/cycle-resolution/define/frontmatter/state/work-item-next）: 非回帰 All passed（全 7 スイート rc=0）
```

## コードレビュー結果
- [x] セキュリティ: OK（reviews への機密マスク方針準用を Step 5.2/5.3 に明記 / マーカー injection 無害化規則追加 / ローカル CLI・markdown・mktemp 隔離 harness で OWASP HTTP 系・認証・NW は N/A）
- [x] コーディング規約: OK（局所パース不追加 / ドッグフーディング特殊処理なし / SoT 二重定義回避）
- [x] エラーハンドリング: OK（decide_review_routing 未知値は unknown で停止しない / fname 共通導出で set -u 安全）
- [x] テストカバレッジ: OK（routing 写像 / upsert 冪等 / 境界解除完走 / reviews 構造 / 非生成 / 非回帰）
- [x] ドキュメント: OK（develop.md Step 5 手順 / 設計 2 成果物 / レビューサマリ 4 Set）

## 技術的な決定事項
- `matrix_review_mode`（§8 / 実行対象決定）と `routing_review_mode`（config / 処理パス選択）を用語分離し、routing には config 値のみ渡す（不正 enum 混入防止）
- `code_security` を security-only に縮約せず `code, security`（security 重点）とし、reviewing-construction-code の複合 focus を維持
- review-flow.md からの委譲を「5R/完了判定/Defer/マスク/パス選択」に限定し、commit（Step 6 単一）と成果物保存（reviews/<id>-<slug>.md）は v3 develop が上書き
- reviews 記録はセクション単位 upsert（status= マーカー区間 / 行頭完全一致検出 / 本文混入マーカー無害化）で冪等化
- SoT §6.1 不整合は §6.2/§8 正本で確定（plan review は develop で materialized されない / capability ≠ execution）

## 課題・改善点
- 実 CLI 依存の review 反復・Defer 自動 Issue 起票の end-to-end 検証は Unit 004（モック/スタブ化）に委譲。本 Unit はルーティング決定 + reviews 構造 + upsert 冪等の決定的検証に限定
- `aidlc-review`（9→1 統合スキル）の新規作成は別サイクル。本 Unit は既存 reviewing-construction-* への暫定ルーティング

## 状態
**完了**

## 備考
AI レビュー: 計画 2R（高2/中2/低1 resolved）/ 設計 2R（中3/低1 resolved）/ コード 2R（中1/低1 resolved）/ 統合 2R（中3 resolved）。全 defer/未対応 0 件。
