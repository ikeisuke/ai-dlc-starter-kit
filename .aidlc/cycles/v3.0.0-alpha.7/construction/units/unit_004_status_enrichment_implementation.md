# 実装記録: Unit 004 status 出力拡充

## 実装日時
2026-06-29（Construction Phase / v3.0.0-alpha.7）

## 作成ファイル

### 手順 / 仕様
- `skills/aidlc-v3/steps/status.md` - 変更。skeleton→実行手順に拡充。位置づけを実装済み（v3.0.0-alpha.7 / Phase 6）に更新、Step 0 前提確認（state.json 不在=No active cycle / schema 不正・未対応 schema・読取失敗・current_cycle 不正・cycle dir 不在=state read error doctor 案内 / current_cycle パス安全検証）、各フィールド導出手順（work-item-status.sh status:<value> から <value> のみ / lib/frontmatter.sh fm_extract_block + fm_scalar で size/risk）、§3.5 フィールド構造・順序一致、launch prefix /aidlc-v3 統一。

### テスト
- `skills/aidlc-v3/scripts/tests/test-status.sh` - 新規（35 件 / 自己完結 / jq 前提 / ネットワーク非依存）。§3.5 出力例ブロックのフィールドラベル列 exact 比較・順序、No active cycle exact string、launch prefix /aidlc-v3 統一、frontmatter 委譲契約（status:<value> から <value> のみ / 生パース禁止 / fm_size/fm_risk 非実在注意）、状態非変更（state-write.sh / state-init.sh / work-item-status write mode 禁止）、Step 0 分離、data-model §5 SoT 参照、stale 注記なしを静的検証。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_004_status_enrichment_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_004_status_enrichment_logical_design.md`

## ビルド結果
成功（bash -n / shellcheck クリーン / markdownlint 0 errors）

## テスト結果
成功

- 実行テスト数: test-status.sh 35 件 + 既存 v3 テスト 10 スイート（回帰）
- 成功: 全件（test-status.sh 35/35、test-develop-flow.sh 191/191 等）
- 失敗: 0

```text
test-status.sh → PASS=35 FAIL=0
全 v3 テスト → All tests passed（回帰なし）
CI ガード（test-isolation / skill-references / bash-substitution / frontmatter-parse-guard）→ no violations
markdownlint（status.md）→ 0 errors
```

## コードレビュー結果
- [x] セキュリティ: OK（current_cycle パス安全検証 / status は read-only）
- [x] コーディング規約: OK（既存 step 記法整合 / コマンド置換禁止遵守）
- [x] エラーハンドリング: OK（Step 0 分離 / No active cycle と state read error の区別）
- [x] テストカバレッジ: OK（35 件 / §3.5 ブロック exact 比較 / 委譲契約 / 状態非変更）
- [x] ドキュメント: OK（§3.5 整合 / 設計乖離なし / stale 除去）

## 技術的な決定事項
- status はスクリプトを持たず手順ベース（status.sh 新設せず）。
- launch prefix は `/aidlc-v3`（skeleton 統一 / SKILL.md「コマンド表記について」/ 既存 step と整合 / Phase 7 で `/aidlc` 統一）。§3.5 の `/aidlc` との prefix 差は documented skeleton↔end-state 差。
- Step 0: state.json 不在のみ No active cycle、schema 不正・未対応 schema・読取失敗・current_cycle 不正・cycle dir 不在は state read error（doctor 案内）に分離。
- frontmatter 生パース禁止: status は `work-item-status.sh --read`（status:<value> から <value>）/ `lib/frontmatter.sh`（fm_extract_block + fm_scalar）委譲。
- current_cycle パス安全検証（doctor 同基準 `^[A-Za-z0-9][A-Za-z0-9._-]*$` + `..` 禁止）。

## 課題・改善点
- なし（OUT_OF_SCOPE defer なし）。doctor `[phase]` 導出 code 化は alpha.8 / #741。

## 状態
**完了**

## 備考
- 関連: Relates to #736（Phase 6）
