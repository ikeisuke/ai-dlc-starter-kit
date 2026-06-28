# Unit: Merge 承認・実行 + Post-merge cleanup

## 概要

release フェーズ Step 3「Merge 承認 + 実行」と Step 4「Post-merge」を実装する。PR ready 化と `release.ready` 書き込み、merge 前の `release.merge_approved` 記録、merge 実行、merge 後の branch cleanup・journal 追記・tag/changelog（opt-in）を担う。

## 含まれるユーザーストーリー

- ストーリー 4: Merge 承認記録と merge 実行
- ストーリー 5: Post-merge cleanup

## 責務

- Step 3「Merge 承認 + 実行」を実装:
  - PR を ready 化し `release.ready: true` を `state-write.sh` で書き込む（`data-model.md §3.3`「ready 化時に書き込み」）。
  - CI パス確認。
  - `release.merge_approved: true` を **merge 前の最終コミット**で書き込み、commit + push してから `gh pr merge`（`merge_method` 設定に従う）。
  - merge 承認ゲート: `manual`=明示確認必須 / `semi_auto`=承認前提（CI green・高重要度未解決指摘なし・未 merged）充足で自動、未充足はユーザー確認へ。**「高重要度未解決指摘なし」の判定入力は Unit 002 が release.md に記録する review 結果サマリセクション（perspective ごとの未解決指摘数・最高重要度・merge blocker 有無）を読み取る**（Unit 002→003 データ契約）。
  - complete 判定が `merge_approved` + PR 実態（merged）の両方を要する旨を手順に明記（導出規則は再定義せず `data-model.md §5.1` を参照）。
- Step 4「Post-merge」を実装: 統合先ブランチへ switch・merge 済み feature branch 削除 / `journal.md` に release 完了追記 / tag（`version_tag` 真）・changelog（`changelog` 真）を opt-in 実行。opt-out でも正常完了。

## 境界

- PR 作成・release.md 作成・review ルーティング（Unit 002）は扱わない。
- state.json schema 変更は行わない（既存 `release.ready` / `release.merge_approved` のみ使用）。
- フェーズ導出規則の定義は行わない（参照のみ）。

## 依存関係

### 依存する Unit

- 002 PR 整備 + release.md テンプレート + review ルーティング（依存理由: PR 作成・`release.pr_number` 記録・release-level review 完了後に ready 化〜merge へ進むため）

### 外部依存

- 既存 `state-write.sh` / `state-read.sh` / `state-validate.sh`
- `gh`（pr ready / pr merge / pr view）、git（switch / branch -d / tag）
- 設計 SoT: `docs/v3/workflow.md §3.3`（Step 3・4）/ `docs/v3/data-model.md §3.3`（書き込みタイミング）/ `§5.1`（complete 判定）

## 非機能要件（NFR）

- **監査性**: `release.merge_approved` を merge 前に記録し、merge 後にブランチが消えても承認記録が残る。
- **互換性**: state.json schema 不変。
- **安全性**: merge は承認ゲート通過後のみ。push を伴うため、未コミット・remote 同期の事前確認を含める。

## 技術的考慮事項

- `release.merge_approved` 単独では complete としない（`data-model.md §5.1` 評価順 1）。
- post-merge の branch 操作は本リポジトリの git 運用規約（カレントディレクトリ実行・force push 確認）に整合させる。

## 関連Issue

- #736（部分対応 / Relates）

## 実装優先度

High

## 見積もり

1 日（Step 3 merge + Step 4 post-merge）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-27
- **完了日**: 2026-06-27
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
