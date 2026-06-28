# 実装記録: Unit 003 doctor v1 実装

## 実装日時
2026-06-29（Construction Phase / v3.0.0-alpha.7）

## 作成ファイル

### ソースコード
- `skills/aidlc-v3/scripts/doctor.sh` - 新規。9 領域診断（config / state / cycle / work-items / git / gh / pr / scripts / parse-guard）+ 総合 exit code 導出（2>1>0）。診断のみ・state 非変更。既存スクリプト wrap + exit code 写像（[state] stdout prefix 分岐 / [work-items] 前提ゲート / [config] dasel 依存不足区別 / cycle 識別子パス安全検証 / parse-guard 不在 SKIP = opt-in シグナル）。
- `skills/aidlc-v3/steps/doctor.md` - 新規。出力仕様 / severity 写像表 / 診断のみ宣言 / [phase]・[trace] の alpha.8 defer 明記。

### テスト
- `skills/aidlc-v3/scripts/tests/test-doctor.sh` - 新規（80 件 / 自己完結 fixture / jq 前提 / ネットワーク非依存 / test-isolation cd-guard 遵守）。9 領域・exit code 2>1>0・前提ゲート・cycle パス安全・gh 不在・parse-guard 不在 SKIP を検証。

### ドキュメント（SoT 段階反映）
- `skills/aidlc-v3/SKILL.md` - doctor を予約→実装済み（description / 位置づけ / 補助コマンド表 / scripts・steps 列挙同期 = state-init.sh / lib/frontmatter.sh / doctor.sh / doctor.md 追加）。
- `docs/v3/workflow.md §3.6` - チェック項目表に段階列（alpha.7 / alpha.8）+ [parse-guard] 追記、出力例を alpha.7/alpha.8 分離・実装整合。
- `docs/v3-renewal-plan.md` - doctor チェック項目 + Phase 6 完了条件を段階化、出力例是正。
- `bin/check-skill-references.sh` - doctor.md の公開 API スクリプト層参照（read-config.sh wrap）を allowlist 追加（develop.md と同パターン）。

### 設計ドキュメント
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/domain-models/unit_003_doctor_v1_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.7/design-artifacts/logical-designs/unit_003_doctor_v1_logical_design.md`

## ビルド結果
成功（bash -n / shellcheck クリーン）

## テスト結果
成功

- 実行テスト数: test-doctor.sh 80 件 + 既存 v3 テスト 9 スイート（回帰）
- 成功: 全件（test-doctor.sh 80/80、test-develop-flow.sh 191/191 等）
- 失敗: 0

```text
test-doctor.sh → PASS=80 FAIL=0
全 v3 テスト → All tests passed（回帰なし）
CI ガード（skill-references / bash-substitution / frontmatter-parse-guard / test-isolation）→ no violations
markdownlint（workflow.md / renewal-plan / doctor.md / SKILL.md）→ 0 errors
doctor.sh 実リポジトリスモーク → exit 0（9 領域診断）
```

## コードレビュー結果
- [x] セキュリティ: OK（cycle 識別子パス安全検証 / doctor は read-only / 診断出力に機密情報なし）
- [x] コーディング規約: OK（bash 互換 / set -uo pipefail で wrap exit 捕捉 / コマンド置換禁止遵守）
- [x] エラーハンドリング: OK（領域別 OK/WARN/ERROR/SKIP / 総合 exit 2>1>0 / gh 不可用 WARN/skip）
- [x] テストカバレッジ: OK（80 件 / exit code 全系統 / 前提ゲート / opt-in 不在）
- [x] ドキュメント: OK（SoT 段階注記が設計整合 / 設計乖離なし）

## 技術的な決定事項
- doctor は診断のみ（自動修正・state 変更なし）。既存安全境界スクリプト wrap で新規パースロジックを書かない（parse-guard 違反回避）。
- 総合 exit code 2>1>0（診断不能 > ERROR > 完了）。警告付き完了は exit 0（exit-code-convention 整合）。
- No active cycle（state 不在）は WARN/exit0 の通常分岐。gh 不可用は WARN/skip（exit 非影響）。
- cycle 識別子を state-init.sh 同等 `^[A-Za-z0-9][A-Za-z0-9._-]*$` + `..` 禁止で検証（パストラバーサル対策）。
- parse-guard スクリプト不在は SKIP（opt-in シグナル / consumer 想定 / ドッグフーディング特殊処理禁止に整合）。
- alpha.8 defer: [phase] / [trace]（SoT に段階注記、実装は #741 へ）。

## 課題・改善点
- なし（OUT_OF_SCOPE defer なし）。alpha.8 follow-up は #741 として起票済み。

## 状態
**完了**

## 備考
- 関連: Relates to #736（Phase 6 / コメントで段階反映）/ Closes #733（alpha.4 完了証跡 + doctor [parse-guard] T4 充足でクローズ済み）
- alpha.8 follow-up: #741（doctor [phase]/[trace]）
