---
id: "001"
status: done
size: normal
risk: medium
assigned: null
dependencies: []
---

# Work Item 001: v3 config.toml キー終端設計（SoT ギャップ解消）

## Goal

RFC §6.4 と data-model.md §8 が相互委譲して未確定のままになっている v3 config.toml の終端キー集合を確定文書化し、002（フォールバック opt-in フラグの要否判断）と 003（migration の config 変換先 schema）の前提を確立する。migration.md §8 の SoT ギャップ注記を解消する。

## Scope

- 含むもの: v3 config.toml のキー集合・命名・既定値の確定と確定文書（data-model.md §8 または RFC §6）への記載、migration.md §8 の SoT ギャップ注記の解消（確定文書への参照に置換）、002 のフォールバック opt-in フラグをキー集合に含めるか否かの判断、v2 キー → v3 キーの対応表（migration.md §3 config 行の具体化）
- 含まないもの: config ローダー実装の変更（必要が生じた場合は該当 work item 側で扱う）、defaults.toml の値変更を伴う挙動変更

## Acceptance Criteria

- [ ] v3 config.toml の終端キー集合（キー名 / 型 / 既定値 / 用途）が確定文書 1 箇所に記載され、SoT が一意である
- [ ] migration.md §8 の「終端 schema 未確定」注記が解消され、確定文書への参照に置換されている
- [ ] RFC §6.4 / data-model.md §8 / migration.md §3 の相互参照が循環なく整合している
- [ ] 002 のフォールバック opt-in の発動形態（config フラグ or 明示ユーザー確認手順）が判断・記録されている

## Traceability

- Intent refs: scope:v3 config.toml キー終端設計の確定
- Acceptance refs: AC-2, AC-6
- Verification: 該当 3 文書の整合の目視レビュー + ドキュメント系 CI（markdownlint 等）pass
- Release note required: no（設計文書の確定 / consumer 向け挙動変更なし）

## Size / Risk

- Size: normal
- Risk: medium
- Reason: ドキュメント中心だが、SoT 3 文書（RFC / data-model / migration）にまたがる整合修正と、後続 2 work item の前提となる設計判断（キー集合の確定）を含むため

## Dependencies

- none
