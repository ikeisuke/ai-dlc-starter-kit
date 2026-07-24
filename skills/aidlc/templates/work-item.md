---
id: "{{id}}"
status: pending        # pending | in_progress | blocked | done | withdrawn
size: normal           # tiny | normal | risky
risk: medium           # low | medium | high
assigned: null         # 担当者名 / 未割当は null
dependencies: []       # 依存 work item ID のリスト（例: ["001", "002"]）/ 空配列可
---

# Work Item {{id}}: {{title}}

## Goal

{{この work item で何を達成するか}}

## Scope

- 含むもの: {{この work item の対象範囲}}
- 含まないもの: {{明示的に除外する範囲}}

## Acceptance Criteria

- [ ] {{検証可能な条件 1}}
- [ ] {{検証可能な条件 2}}

## Traceability

- Intent refs: {{scope:example}}
- Acceptance refs: {{AC-001, AC-002}}
- Verification: {{test command or manual check}}
- Release note required: {{no}}

## Size / Risk

- Size: normal
- Risk: medium
- Reason: {{この size / risk と判断した理由}}

## Dependencies

- {{none もしくは 依存する work item ID}}

## Implementation Notes

{{必要な場合のみ記録（任意セクション）}}
