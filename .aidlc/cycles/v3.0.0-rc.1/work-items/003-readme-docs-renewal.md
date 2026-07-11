---
id: "003"
status: pending
size: normal
risk: low
assigned: null
dependencies: ["002"]
---

# Work Item 003: README・ドキュメント刷新

## Goal

README を v3 前提に刷新し、v2-maintenance への参照案内と docs の表記整合を完了して、
consumer が v3 を導入・移行できる導線を整える。

## Scope

- 含むもの:
  - README の v3 前提への刷新（インストール / コマンド体系 / サイクルフロー説明）
  - v2 利用者向けの v2-maintenance branch 参照案内と v2→v3 migration 導線（aidlc-migrate）の記載
  - docs 内の残存 `/aidlc-v3` 表記・v2 前提記述の整合（設計正本 docs/v3/ の履歴的記述は除く）
- 含まないもの: skills 実体の変更（002 で完了済み前提）/ v2 EOL 宣言 / GA 告知

## Acceptance Criteria

- [ ] README が v3 のコマンド体系（define / develop / release / reflect / status / doctor）で記述されている
- [ ] v2-maintenance branch への参照案内と migration 導線が README にある
- [ ] markdownlint 0 errors / skill-reference-check green

## Traceability

- Intent refs: scope:readme-renewal
- Acceptance refs: AC-006（README・docs が v3 表記で整合 / v2-maintenance 参照案内）
- Verification: markdownlint / skill-reference-check / README の目視レビュー
- Release note required: yes

## Size / Risk

- Size: normal
- Risk: low
- Reason: ドキュメントのみの変更で実行系に影響しないが、consumer 向け導線の品質が RC の
  評価に直結するため normal とする。002 完了後の最終構造を反映する必要がある

## Dependencies

- 002（本流化置換後の最終構造を反映するため）
