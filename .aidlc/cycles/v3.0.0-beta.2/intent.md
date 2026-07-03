# Intent: v3.0.0-beta.2

## 目的

v3 ベータの既知バグと CI 非互換を解消し、v3 サイクルが `cycle/*` 命名の main 宛て PR で自走できる状態にする（#744 / #747）。

## スコープ

### 含むもの

- #744: doctor `[phase]` の complete 判定を `gh pr view --json state`（`.state == "MERGED"`）ベースに修正（`skills/aidlc-v3/scripts/doctor.sh` の `diagnose_phase`）
- #744: `test-doctor.sh` の gh stub（`install_gh_stub_full`）を実 gh の JSON フィールド（`state` / `mergedAt`）に忠実化し、テスト忠実性ギャップを解消
- #747: `bin/check-cycle-phase-completion.sh` の v3-flat 構造対応（v2 サイクルの既存判定は非影響で維持）

### 含まないもの

- #745（release hard gate の required CI 0 件時フォールバック方針）→ Phase 7 前の後続サイクルへ defer
- v2 → v3 migration / 本流化（Phase 7）そのもの
- doctor の自動修正機能（read-only 維持）

## 受け入れ基準

- [ ] AC-1: merge 済みサイクルに対し doctor `[phase]` が `complete` を正しく導出する（実環境 gh で確認）
- [ ] AC-2: gh stub が実 gh の JSON フィールドに忠実で、`test-doctor.sh` 全ケース pass（`--json merged` 依存の残存なし）
- [ ] AC-3: `check-cycle-phase-completion.sh` が v3-flat サイクルの完了判定を行え、v2 サイクル向け既存判定・既存テストに非影響
- [ ] AC-4: 本サイクル自身の PR（`cycle/v3.0.0-beta.2` → main）で cycle-phase-completion-check job が成功する
- [ ] AC-5: 全テストスイート / shellcheck / parse-guard が green

## 制約・前提

- 「ドッグフーディング特殊処理を本体に埋めない」原則に従い、#747 の構造判別は opt-in シグナル方式（成果物の存在に基づく汎用分岐）を優先する
- doctor / チェックスクリプトは自動修正しない（診断・判定のみ）
