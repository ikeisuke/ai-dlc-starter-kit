---
id: "001"
status: pending
size: normal
risk: low
assigned: null
dependencies: []
---

# Work Item 001: doctor `[trace]` 後段検証拡充

## Goal

`doctor.sh` の `diagnose_trace` に trace chain 後段検証（intent 存在・Traceability 健全性・journal 整合）を追加し、read-only 診断の網羅性を高める。alpha.8 で design ファイル存在確認まで実装済みの `[trace]` を、後段の trace 整合まで深化させる。

## Scope

- 含むもの: `diagnose_trace` への 3 後段検証追加、`test-doctor.sh` の後段ケース拡張、`report()` 出力契約・11 領域構成の維持
- 含まないもの: reviews / release / reflect の完全意味検証、doctor 自動修正、新規 frontmatter パーサ

## Acceptance Criteria

- [ ] intent.md 不在時に `[trace]` が WARN を出す（exit 0 維持）
- [ ] work item の Traceability 各フィールド（Intent refs / Acceptance refs / Verification）が空 / プレースホルダ残存時に WARN
- [ ] `status: done` work item が journal.md 未記録時に WARN、journal.md 不在時に WARN
- [ ] 全後段検証充足時は既存同様 OK、`test-doctor.sh` 後段ケース全パス

## Traceability

- Intent refs: scope:doctor-trace-後段検証, scope:dogfooding測定
- Acceptance refs: AC-1, AC-2, AC-3
- Verification: bash skills/aidlc-v3/scripts/tests/test-doctor.sh
- Release note required: no

## Size / Risk

- Size: normal
- Risk: low
- Reason: 既存のテスト済み `diagnose_trace` への additive・read-only 拡張で state / data を書き換えず、契約テストで担保されるため risk は low。ただし 3 サブ検証 + テスト拡張で単一関数の変更範囲を超えるため size は tiny ではなく normal。

## Dependencies

- none

## Implementation Notes

- 入力取得は既存スクリプト（`state-read.sh` / `work-item-status.sh`）と共有パーサ（`lib/frontmatter.sh` の `fm_scalar`）を再利用する（新規パース禁止規約）。
- `report trace <severity> <detail>` の出力契約（`printf '%-14s%-6s%s'`）を厳守する。
- WARN は exit 0、診断不能のみ exit 2 の総合 exit code 集約規約を踏襲する。
