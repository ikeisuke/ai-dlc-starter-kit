---
id: "002"
status: pending
size: normal
risk: medium
assigned: null
dependencies: []
---

# Work Item 002: cycle-phase-completion-check の v3-flat 構造対応

## Goal

`bin/check-cycle-phase-completion.sh`（CI: `cycle-phase-completion-check.yml`）を v3-flat 構造（`intent.md` / `work-items/` + リポジトリ直下 `state.json`）で完了判定できるようにし、`cycle/*` 命名の v3 サイクル main 宛て PR が CI を通過できるようにする（#747）。v2 サイクル向けの既存判定は非影響で維持する。

## Scope

- 含むもの: v3-flat サイクルの完了判定ロジック追加（`state.json` + work item frontmatter ベース / doctor `[phase]` の導出規則 data-model.md §5 と整合）、v2 / v3 の構造判別（opt-in シグナル方式 = 成果物の存在に基づく汎用分岐）、テスト追加
- 含まないもの: v2 判定ロジックの変更、CI workflow のトリガー条件変更（`cycle/*` ガードは維持）、#745（hard gate 方針）

## Acceptance Criteria

- [ ] v3-flat サイクル（全 work item done/withdrawn + release 記録あり）に対し complete 判定が exit 0 で通る
- [ ] v3-flat サイクルの未完了状態（pending/in_progress の work item あり等)で incomplete 判定（exit 1）と理由が出力される
- [ ] v2 サイクルに対する既存判定の挙動・既存テストが非影響（全 pass）
- [ ] 構造判別に「starter kit 自身か」の判定を埋め込まない（opt-in シグナル方式 / リポジトリ設計原則準拠）
- [ ] 本サイクル自身の PR（`cycle/v3.0.0-beta.2` → main）で cycle-phase-completion-check job が成功する

## Traceability

- Intent refs: scope:#747（check-cycle-phase-completion の v3-flat 対応）
- Acceptance refs: AC-3, AC-4, AC-5
- Verification: 既存テスト + v3-flat ケース追加分の実行、`bash bin/check-cycle-phase-completion.sh v3.0.0-beta.2` のローカル実行、本サイクル PR での実 CI
- Release note required: yes（既知制約 #747 の解消）

## Size / Risk

- Size: normal
- Risk: medium
- Reason: 対応案（v3 判定の追加方式 / 判別シグナル設計）の設計選択を伴い、CI マージゲートに関わるため。簡易 design 経由で実装する

## Dependencies

- none
