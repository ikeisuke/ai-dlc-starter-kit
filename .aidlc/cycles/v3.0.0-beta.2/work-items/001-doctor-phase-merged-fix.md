---
id: "001"
status: done
size: tiny
risk: low
assigned: null
dependencies: []
---

# Work Item 001: doctor [phase] merged 判定修正 + gh stub 忠実化

## Goal

doctor `[phase]` の complete 判定が gh に存在しない `--json merged` フィールドを使い常に失敗するバグ（#744）を修正し、PR merged 確認を `--json state`（`.state == "MERGED"`）ベースに変更する。併せて `test-doctor.sh` の gh stub を実 gh の JSON フィールドに忠実化し、フィールド名不正を検出できなかったテスト忠実性ギャップを解消する。

## Scope

- 含むもの: `skills/aidlc-v3/scripts/doctor.sh` の `diagnose_phase`（merged 確認箇所）の修正、`test-doctor.sh` の `install_gh_stub_full`（および関連ケース）の `state` / `mergedAt` ベースへの忠実化、回帰テスト
- 含まないもの: doctor の他領域（`[trace]` 等）の変更、自動修正機能、`reflect.md` Step 0 側（既に `--json state,mergedAt` 使用で正しい）

## Acceptance Criteria

- [ ] merge 済みサイクル（例: alpha.9 / PR #743）に対し `doctor.sh` の `[phase]` が `complete` を OK で導出する（実環境 gh で確認）
- [ ] `doctor.sh` / `test-doctor.sh` に `--json merged` への依存が残存しない
- [ ] gh stub が実 gh の応答形式（`state` / `mergedAt`）を模し、`test-doctor.sh` 全ケース pass
- [ ] shellcheck / parse-guard clean

## Traceability

- Intent refs: scope:#744（doctor complete 判定修正 / gh stub 忠実化）
- Acceptance refs: AC-1, AC-2, AC-5
- Verification: `bash skills/aidlc-v3/scripts/tests/test-doctor.sh` + 実サイクルへの `doctor.sh` 実行
- Release note required: yes（既知制約 #744 の解消）

## Size / Risk

- Size: tiny
- Risk: low
- Reason: 修正方法が Issue #744 で確定済みで変更が局所的。既存回帰テストスイート（161 ケース）で保護されている

## Dependencies

- none
