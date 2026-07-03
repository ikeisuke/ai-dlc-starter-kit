# Intent: v3.0.0-alpha.9

## 目的

v3 スキルの Phase 7-a セルフドッグフーディングとして、doctor `[trace]` 領域の後段検証（intent 存在・Traceability 健全性・journal 整合）を v3 フロー（define→develop→release→reflect）で 1 サイクル完走して実装し、v2 比の読込量・成果物数・確認回数の削減を測定して本流化条件の充足を確認する。

## スコープ

### 含むもの

- `doctor.sh` の `diagnose_trace` 後段拡充（read-only 厳守）:
  1. **intent.md 存在検証** — cycle に `intent.md` が存在するか（不在は WARN）
  2. **Traceability 健全性検証** — 各 work item 本文 `## Traceability` の Intent refs / Acceptance refs / Verification が非空・プレースホルダ未置換でないか
  3. **journal 整合検証** — `journal.md` 存在確認 + `status: done` work item が journal に記録されているか
- `test-doctor.sh` の後段ケース拡張（各検証の OK / WARN 分岐）
- ドッグフーディング測定記録（読込ファイル数・成果物数・確認回数の v2 比）を `journal.md` / `reflect.md` に収集

### 含まないもの

- Phase 7-b（`aidlc-v3 → aidlc` 置換・README 刷新・marketplace v3.0.0 化・v2→v3 migration） → 後続サイクル
- reviews / release / reflect 相互の完全な意味的整合検証（今回は intent / Traceability / journal に限定）
- doctor の自動修正機能（read-only 厳守を維持）

## 受け入れ基準

- [ ] AC-1: `diagnose_trace` に 3 後段検証が追加され、`[trace]` 領域として OK / WARN を出力（exit 0 維持 / read-only）
- [ ] AC-2: `test-doctor.sh` が後段各ケース（正常 / intent 欠落 / プレースホルダ残存 / journal 未記録 / journal 不在）を検証しパス
- [ ] AC-3: doctor が引き続き 11 領域構成（領域追加ではなく `[trace]` 内の検証深化）
- [ ] AC-4: `reflect.md` に v2 比ドッグフーディング測定結果が記録される

## 制約・前提

- 実行経路 B（v3 ステップ手動駆動）。`/aidlc-v3` は現プラグインキャッシュ（commit `80c4fe62` = v2.6.6）に未含のため Skill 起動不可
- 新規 frontmatter パース禁止（`lib/frontmatter.sh` 再利用）、`report()` 出力契約厳守
- Epic #736（v3 リニューアル / Phase 7-a）に紐付く
