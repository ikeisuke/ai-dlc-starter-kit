# Intent: v3.0.0-rc.1

## 目的

`/aidlc` を打つと v3 が起動する状態（フル本流化 = Epic #736 7-e）を RC として main に反映する。

Epic #736 の残タスクは 7-e のみ（7-a〜7-d は beta.3 までに完了済み）。Epic の
「marketplace を v3.0.0（GA）化 → RC → GA」の順序に従い、本サイクルで本流化の実体作業
（skills 置換 / v2 保全 / README 刷新 / marketplace rc.1 化）を完了し、GA（v3.0.0）は
RC 検証後の軽量な後続サイクルとする。

Relates to #736

## スコープ

### 含むもの

- 旧 v2 一式の `v2-maintenance` branch への保全（撤去後も取得可能にする）
- `skills/aidlc-v3` → `skills/aidlc` 置換（SKILL.md 等の `/aidlc-v3` 表記の `/aidlc` への更新を含む）
- 旧 v2 専用スキル群（aidlc-retrospective / reviewing-\* / squash-unit / write-history 等）の
  扱い確定（v3 委譲利用の精査）と main からの撤去
- marketplace version の `3.0.0-rc.1` 化（`/aidlc` = v3）
- aidlc-migrate・CI workflows の参照整合
- README の v3 前提への刷新（v2-maintenance への参照案内を含む）
- 付随: #745 の close（解消済み根拠コメント付き / define 時に実施済み）

### 含まないもの

- best-effort migration（progress / units / history の実データ変換 / beta.3 で後続サイクルへ defer 済み）
- v2 EOL 宣言（best-effort migration + 2 consumer プロジェクトでのテストとセットで後続）
- GA 化（v3.0.0 最終 / RC 検証後の後続サイクル）

## 受け入れ基準

- [ ] `/aidlc` 起動で v3 がルーティングされる（skills/aidlc = v3 実体）
- [ ] v2 実装一式が `v2-maintenance` branch から取得可能である
- [ ] aidlc-migrate の世代ルーティング（v2→v3 migration 経路）が本流化後も機能する
- [ ] marketplace.json が version `3.0.0-rc.1` で `/aidlc` = v3 を配布する
- [ ] CI（bats / shellcheck / markdownlint / parse-guard / skill-reference-check / migration-tests 等）全 green
- [ ] README・docs が v3 表記で整合し、v2-maintenance への参照案内がある

## 制約・前提

- 002（本流化置換）は risky として design: full + Rollback Note + code_security review の厚いフローで扱う
- v2 保全（001）は撤去（002）に必ず先行する（依存関係で順序強制）
- aidlc-migrate の state-init.sh 解決は aidlc-v3 → aidlc の 2 候補解決で置換耐性あり（beta.3 で整備済み）
