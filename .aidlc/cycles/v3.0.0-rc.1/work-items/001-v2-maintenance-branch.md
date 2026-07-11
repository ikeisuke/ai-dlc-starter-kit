---
id: "001"
status: done
size: tiny
risk: low
assigned: null
dependencies: []
---

# Work Item 001: v2-maintenance 保全

## Goal

旧 v2 一式（skills/aidlc ほか v2 専用スキル群）を `v2-maintenance` branch に保全し、
main からの撤去（002）後も取得・修正可能な状態を作る。

## Scope

- 含むもの: main（beta.3 merge 後の最新）から `v2-maintenance` branch を作成し remote へ push する
- 含まないもの: v2 実装の main からの撤去（002 の責務）/ README での参照案内（003 の責務）

## Acceptance Criteria

- [ ] `v2-maintenance` branch が remote に存在し、v2 実装一式（skills/aidlc / reviewing-\* 等）を含む
- [ ] branch 作成元が本流化置換（002）開始前の main である

## Traceability

- Intent refs: scope:v2-maintenance-branch
- Acceptance refs: AC-002（v2 実装一式が v2-maintenance branch から取得可能）
- Verification: git ls-remote --heads origin v2-maintenance で branch 存在を確認 / branch 上で skills/aidlc の存在を確認
- Release note required: no

## Size / Risk

- Size: tiny
- Risk: low
- Reason: branch 作成 + push のみの決定的操作で、main に変更を加えない。ただし 002 の前提条件であり
  忘れると v2 が復元不能になるため、独立 work item として順序を強制する

## Dependencies

- none
