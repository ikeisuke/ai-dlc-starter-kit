---
id: "002"
status: pending
size: risky
risk: high
assigned: null
dependencies: ["001"]
---

# Work Item 002: フル本流化置換

## Goal

`skills/aidlc-v3` を `skills/aidlc` に置換して `/aidlc` = v3 を実現し、旧 v2 実装を
main から撤去、marketplace を `3.0.0-rc.1` 化する（Epic #736 7-e の実体作業）。

## Scope

- 含むもの:
  - `skills/aidlc-v3` → `skills/aidlc` 置換（ディレクトリ名 / skill name / `/aidlc-v3` 表記の `/aidlc` への更新）
  - 旧 v2 専用スキル群（aidlc-retrospective / reviewing-\* / squash-unit / write-history / aidlc-setup 等）の
    扱い確定（v3 が委譲で利用するものの精査）と不要分の main からの撤去
  - marketplace.json 更新（`/aidlc` = v3 / `/aidlc-v3` エントリ整理 / version `3.0.0-rc.1`）
  - aidlc-migrate の参照整合（state-init.sh 2 候補解決の動作確認を含む）
  - CI workflows（skill-reference-check / migration-tests 等）の参照整合
  - v3 内部テスト（scripts/tests/）のパス・表記整合
- 含まないもの: README 刷新（003）/ v2-maintenance branch 作成（001）/ best-effort migration / GA 化

## Acceptance Criteria

- [ ] `/aidlc` 起動で v3 がルーティングされる（skills/aidlc = v3 実体 / 旧名エイリアス含め動作）
- [ ] 旧 v2 実装が main に残存しない（撤去対象の確定リストに基づく）
- [ ] marketplace.json が version `3.0.0-rc.1` で `/aidlc` = v3 を配布する
- [ ] aidlc-migrate の v2→v3 migration 経路が置換後も機能する
- [ ] CI（bats / shellcheck / markdownlint / parse-guard / skill-reference-check / migration-tests）全 green

## Traceability

- Intent refs: scope:mainline-replacement, scope:marketplace-rc1, scope:reference-consistency
- Acceptance refs: AC-001（/aidlc = v3）, AC-003（migration 経路維持）, AC-004（marketplace rc.1）, AC-005（CI green）
- Verification: 全 CI green / skills/aidlc-v3 の不存在 + skills/aidlc = v3 実体の確認 / aidlc-migrate テスト pass
- Release note required: yes

## Size / Risk

- Size: risky
- Risk: high
- Reason: リポジトリ構造の大規模置換で、参照が aidlc-migrate・CI 2 workflow・v3 内部テスト 6 ファイル・
  marketplace.json に及ぶ。v2 撤去は 001 の保全がなければ復元不能。design: full + Rollback Note +
  code_security review の厚いフローを適用する

## Dependencies

- 001（v2-maintenance 保全が撤去に先行すること）

## Implementation Notes

- 旧 v2 専用スキル群のうち v3 が委譲利用する可能性があるもの（reflect の retrospective 委譲等）は
  design 段階で確定リスト化してから撤去する
- aidlc-migrate の state-init.sh 解決は aidlc-v3 → aidlc の 2 候補解決で置換耐性あり（beta.3 003 で整備済み）
