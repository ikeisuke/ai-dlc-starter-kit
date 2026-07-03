# 実装記録: Unit 002 reflect フロー実装

## 実装日時
2026-06-28〜2026-06-29（Construction Phase / v3.0.0-alpha.7）

## 作成ファイル

### ソースコード / 手順
- `skills/aidlc-v3/steps/reflect.md` - 新規。reflect フロー Step 0–4（前提確認 / 材料収集 / KPT 抽出 / 行動化 / 完了）。release.md 記法準拠。state 非変更・gh 可用性判定・機密マスク手順含む。
- `skills/aidlc-v3/templates/reflect.md` - 新規。Keep / Problem / Try / Issue リンク章立て。
- `skills/aidlc-v3/SKILL.md` - 変更。reflect を予約→実装済み（description / 位置づけ / コマンド表 / templates・steps 列挙）、フェーズコマンド見出し中立化、doctor 予約維持・express 非包含維持。

### テスト
- `skills/aidlc-v3/scripts/tests/test-reflect-flow.sh` - 新規。静的構造・契約検証（44 件 / jq 前提 / ネットワーク非依存）。Step 0–4 見出し・complete 前提・材料収集・Try Issue 化 3 分岐・state 非変更・journal 追記・core から外す 4 項目・テンプレ章立て・SKILL.md alias/express を検証。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_002_reflect_flow_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_002_reflect_flow_logical_design.md`

## ビルド結果
成功（bash -n / shellcheck クリーン）

## テスト結果
成功

- 実行テスト数: test-reflect-flow.sh 44 件 + 既存 v3 テスト 8 スイート（回帰）
- 成功: 全件（test-reflect-flow.sh 44/44、test-develop-flow.sh 191/191 等）
- 失敗: 0

```text
test-reflect-flow.sh → PASS=44 FAIL=0
全 v3 テスト（test-activation / cycle-resolution / define / develop / frontmatter / release / state / work-item-next）→ All tests passed
CI ガード（skill-references / bash-substitution / frontmatter-parse-guard / test-isolation）→ no violations
```

## コードレビュー結果
- [x] セキュリティ: OK（Issue body マスク手順を具体化 / reflect は read + 成果物生成のみ）
- [x] コーディング規約: OK（既存 v3 ステップ記法 release.md 準拠 / コマンド置換禁止遵守）
- [x] エラーハンドリング: OK（各 Step に停止/skip 分岐 / complete 前提 vs Issue 化 gh の扱い区別）
- [x] テストカバレッジ: OK（44 件の静的契約検証）
- [x] ドキュメント: OK（SoT 参照 / 設計と実装一致）

## 技術的な決定事項
- reflect は state 非変更・承認ゲートなし（Step 2 人間編集 / Step 3 Issue 化確認が人間関与点）。
- complete 前提（release.merge_approved + PR merged）の gh 不可用時は停止/手動確認、Issue 化（任意成果物）の gh 不可用は skip-continue と区別。
- frontmatter 生パース禁止 → work item status は `work-item-status.sh --read` 委譲、理由は非構造抽出（unknown フォールバック）。
- core から外す: workflow.md §3.4 の 4 項目（upstream mirror / cap 管理 / dialog token / aggregate retrospective issue）+ Unit 境界の推定値検出ガード（帰属分離）。
- SKILL.md フェーズコマンド見出しを中立化（reflect の state 非変更・ゲートなしを例外として明記）。

## 課題・改善点
- なし（OUT_OF_SCOPE defer なし）。doctor / status は別 Unit（003 / 004）。

## 状態
**完了**

## 備考
- 関連: Relates to #736（v3 リニューアル Epic / Phase 6）
