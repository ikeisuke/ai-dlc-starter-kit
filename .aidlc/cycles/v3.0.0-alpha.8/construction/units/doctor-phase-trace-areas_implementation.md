# 実装記録: Unit 001 doctor `[phase]` / `[trace]` 領域

## 実装日時

2026-07-01（設計 → 実装 → テスト → 3 レビュー完了）

## 作成ファイル

### ソースコード

- `skills/aidlc-v3/scripts/doctor.sh` - `diagnose_phase`（§5.1 first-match フェーズ導出）/ `diagnose_trace`（§8 size×depth_level design 要否）の 2 領域を追加。`WORK_ITEMS_INVALID` グローバル伝播、`lib/frontmatter.sh` の conditional source、順序実行ブロック（`diagnose_pr` 直後挿入）、ヘッダコメント（9→11 領域）・wrap 契約コメント更新。

### テスト

- `skills/aidlc-v3/scripts/tests/test-doctor.sh` - `[phase]` 各導出（define フォールバック / define / develop / release 可能 / complete）+ 根拠検証、異常系 WARN（merge_approved × 未 merged / pr_number=null / pr_number=0 / gh 不可 / define_completed 矛盾）、`[trace]` 各ケース（design 必須×存在/欠落、tiny 不要、normal×comprehensive、risky×minimal、depth_level 未設定/enum 外）、領域間ゲート（work item invalid / size enum 不正）、「全領域 OK 正常系」11 領域化を追加。ハーネス拡張: read-config stub の depth_level 可変化、`make_valid_work_item` の size/status 引数化、`install_gh_stub_full`（pr view merged 制御）、`assert_area_detail`。

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.8/design-artifacts/domain-models/unit_001_doctor_phase_trace_areas_domain_model.md`
- `.aidlc/cycles/v3.0.0-alpha.8/design-artifacts/logical-designs/unit_001_doctor_phase_trace_areas_logical_design.md`

## ビルド結果

成功（shell script のため bash -n / shellcheck -x でクリーン）

```text
bash -n doctor.sh: OK
shellcheck -x doctor.sh / test-doctor.sh: clean
doctor.sh スモーク実行（現リポジトリ）: 11 領域出力 / exit 0
```

## テスト結果

成功

- 実行テスト数: 131
- 成功: 131
- 失敗: 0

```text
bash skills/aidlc-v3/scripts/tests/test-doctor.sh → PASS: 131 FAIL: 0 / All tests passed. (exit 0)
```

## コードレビュー結果

- [x] セキュリティ: OK（read-only 厳守 / pr_number 正整数検証で gh 引数注入余地排除）
- [x] コーディング規約: OK（既存 doctor wrap パターン踏襲 / 新規 frontmatter パース禁止規約遵守 / fm_scalar 利用）
- [x] エラーハンドリング: OK（WARN 止まり = exit 0 維持 / 矛盾・確認不能は安全側に倒す §6）
- [x] テストカバレッジ: OK（phase 全導出 + 異常系 + trace 全ケース + 領域間ゲート + 11 領域正常系）
- [x] ドキュメント: OK（ヘッダ 9→11 / wrap 契約コメント / SoT ドキュメントは Unit 002）

3 レビューすべて codex で実施し 2R で resolve:

- 計画レビュー（計画承認前 / サマリ非生成）: 3 件 resolve
- 設計レビュー（Set 1）: 3 件 resolve
- コードレビュー（Set 2）: 2 件 resolve
- 統合レビュー（Set 3）: 2 件 resolve

## 技術的な決定事項

- `WORK_ITEMS_INVALID`（invalidity フラグ / ERROR 経路でのみ 1）を導入し、work item 未作成の define 前正常状態と invalid（破損）を区別（レビュー#3）。
- complete 導出は `merge_approved=true` + `pr_number` 正整数（`^[1-9][0-9]*$`）+ gh `pr view` merged 確認成功の三条件（レビュー#1 / 統合#1）。確認不能は安全側 WARN + 実フェーズ導出（§6）。
- `define_completed=true` × work item 0 件/未解決を release 可能扱いしない `wi_count` ガード（コードレビュー#1）。
- size enum 不正の責務は `[work-items]` gate に集約（trace 個別検証は二重責務・到達不能のため排除 / 設計#3）。
- 全角括弧に隣接する変数は `${var}` で明示区切り（`set -u` の unbound 誤判定回避）。

## 課題・改善点

- SoT ドキュメント（`skills/aidlc-v3/steps/doctor.md` / `docs/v3/workflow.md` / `docs/v3-renewal-plan.md`）の「alpha.8 defer → 実装済み」反映と 11 領域表記統一は **Unit 002** の責務（本 Unit 境界外）。

## 状態

**完了**

## 備考

- doctor は read-only 診断のみ（自動修正なし）を厳守。
- 総合 exit code は既存 2 フラグ（`HAS_UNDIAGNOSABLE` > `HAS_ERROR` > OK）を流用し、`[phase]`/`[trace]` は WARN 止まり（exit 0 維持）。
