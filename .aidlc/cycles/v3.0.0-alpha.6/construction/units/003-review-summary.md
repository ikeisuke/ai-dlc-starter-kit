# レビューサマリ: Unit 003 Merge 承認・実行 + Post-merge cleanup

## 基本情報

- **サイクル**: v3.0.0-alpha.6
- **フェーズ**: Construction
- **対象**: Unit 003（ドメインモデル + 論理設計）

<!-- 以下、AIレビュー完了時に Set が追記される -->

---

## Set 1: 設計レビュー（design）

- **レビュー種別**: 設計レビュー（reviewing-construction-design / focus=architecture）
- **使用ツール**: codex
- **反復回数**: 3
- **結論**: 指摘0件（Round 3 で全 resolve 確認）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `unit_003_..._domain_model.md` / `_logical_design.md` - merge_approved 記録後の hard gate 停止 → 再実行で 3-3 再実行 → updated_at 再 push で head 変化 → CI 再 stale ループ + 承認 head 復元不能 | 修正済み（merge_approved 既存 true は再開経路: 承認 commit と PR head 一致なら 3-3 再実行せず hard gate へ） | - |
| 2 | 中 | `_logical_design.md` - hard gate の CI 判定が exact head SHA に固定されておらず `gh run list --branch` で別 commit/一部 workflow 誤認の余地 | 修正済み（headRefOid と同一 SHA の statusCheckRollup が必要 check すべて success を必須化、SHA 非固定参照を禁止） | - |
| 3 | 中 | `_domain_model.md` / `_logical_design.md`（R2 検出）- stale approval 再承認モデルの不整合（承認 commit を false→true と定義 / merge_approved を false に戻す運用が監査記録と衝突） | 修正済み（承認 commit を「merge_approved:true を保持する最新 state.json commit」に拡張、再承認は false に戻さず新 head に再アンカー） | - |

---

## Set 2: コードレビュー（code, security）

- **レビュー種別**: コードレビュー（reviewing-construction-code / focus=code, security）
- **使用ツール**: codex
- **反復回数**: 5
- **結論**: 指摘0件（Round 5 で全 resolve 確認 / merge ロジックの安全性を網羅）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc-v3/steps/release.md` - 3-4→3-5 間の TOCTOU（hard gate 後に PR head が進む） | 修正済み（merge を `gh pr merge --match-head-commit <final_head_sha>` にし、不一致は停止→再アンカー） | - |
| 2 | 高 | `skills/aidlc-v3/steps/release.md` - 3-3 の push 先が「統合先」で base 直 push = merge ゲート迂回 | 修正済み（PR head branch（feature branch）の remote へ push に修正） | - |
| 3 | 高 | `skills/aidlc-v3/steps/release.md` - required check 判定が OR で required 0 件を検出できず無検証 merge の余地 | 修正済み（`gh pr checks <N> --required` を必須化、count>0 かつ全 pass、required 0 件は fail-closed） | - |
| 4 | 中 | `skills/aidlc-v3/steps/release.md` - hard gate の CI 判定の required check 抽出が未定義 | 修正済み（mergeStateStatus=CLEAN + statusCheckRollup を補強、`gh pr checks --required` を主判定に） | - |
| 5 | 中 | `skills/aidlc-v3/steps/release.md` - Step 4 が remote merge commit を取り込まず stale（branch 削除失敗・tag/changelog stale） | 修正済み（Step 4 冒頭で git fetch→switch→pull --ff-only で同期後に削除/tag/changelog） | - |
| 6 | 中 | `skills/aidlc-v3/steps/release.md` - Step 4 の journal/changelog/tag の commit/push 方針未定義 | 修正済み（統合先 commit+push、保護ブランチ時 follow-up PR、直接 push でゲート迂回しない旨を明文化） | - |
| 7 | 中 | `skills/aidlc-v3/steps/release.md` - tag が HEAD（journal bookkeeping commit）を指す可能性 | 修正済み（merge commit SHA を `gh pr view --json mergeCommit` で取得し明示指定して tag 作成） | - |

---

## Set 3: 統合レビュー（integration / code）

- **レビュー種別**: 統合レビュー（reviewing-construction-integration / focus=code）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘0件（1R clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| - | - | 指摘なし。設計-実装整合（二層ゲート / 再開経路 / required check / `--match-head-commit` / Step 4 同期・commit/push 方針 / merge commit tag）・完了条件充足・Unit 境界（`skills/aidlc-v3/SKILL.md` の `release` 予約のまま / state schema 不変）・既存 v3 テスト 7 スイート green を確認 | - | - |
