# Unit: Operations Phase 7.12 PR レビュー反映コミットの squash 統合

## 概要

`skills/aidlc/steps/operations/operations-release.md` の 7.12（PR マージ前レビュー）と 7.13（PR マージ）の間に Squash サブステップを追加する。`squash_enabled=true` 設定下では 7.12 で発生した複数 round のレビュー反映コミットが 1 コミットに squash 統合される。Squash 対象範囲は `progress.md` の新規 slot `release_prep_commit` から起点 hash を取得して決定する。`merge_method=merge` 維持下でも main 履歴に細粒度のレビュー反映コミットが残らないようにする。

## 含まれるユーザーストーリー

- ストーリー 4: Operations Phase 7.12 PR レビュー反映コミットの squash 統合

## 責務

- `skills/aidlc/steps/operations/operations-release.md` の 7.12 と 7.13 の間に Squash サブステップを追加（**正本**）
- `skills/aidlc/steps/operations/02-deploy.md` への変更は参照リンクの更新のみに留める（非正本、Squash サブステップ本体の記述は重複させない）
- `skills/aidlc/steps/common/commit-flow.md` の Squash 統合フローを再利用する形での実装
- `.aidlc/cycles/<cycle>/operations/progress.md` の新規 slot `release_prep_commit` の追加
  - 7.7（最終コミット）完了時に commit hash を slot へ記録する処理を operations-release.md / 関連スクリプトに追加
- Squash 異常系の契約実装（**非対話前提**）:
  - 対象 0 件: `squash:skipped:reason=no_commits` で継続
  - `git reset --soft` / `git commit` 失敗: `squash:failed:reason=git_op_failed:<exit_code>` で block + `git reset --hard ORIG_HEAD` で rollback（`git rebase` を採用する場合は `git rebase --abort`）
  - コンフリクト: `git reset --soft` 方式では発生しない。`git rebase` 採用時のみ `squash:failed:reason=conflict` で block + `git rebase --abort` で rollback
  - `release_prep_commit` slot 未存在（既存サイクル再開時）: `squash:skipped:reason=release_prep_commit_missing` で継続
  - `squash_enabled=false`: `squash:skipped:reason=disabled` で継続
- CHANGELOG への Operations Phase squash 対応追加と `release_prep_commit` slot 追加の記載
- `templates/operations_progress_template.md` への `release_prep_commit` slot 追加（新規サイクルで自動的に slot が含まれる）

## 境界

- `merge_method` 設定値の変更は本 Unit のスコープ外（`merge_method=merge` 維持）
- Construction Phase Unit 単位の Squash は既存実装を流用するのみで、Construction 側の改修は行わない
- 既存 v2.5.1 以前のサイクル進行中の progress.md には `release_prep_commit` slot を retro-active に追加しない（未存在時は skip 動作で安全）
- 7.13 PR マージ自体（`gh pr merge` の呼び出し）は変更しない

## 依存関係

### 依存する Unit

- 001-review-flow-5r-and-defer-automation（**soft dependency / レビュー運用前提**: 実装着手は Unit 001 完了を待たずに開始可能。レビュー実施時点で Unit 001 が完了している必要がある）
- 002-construction-ci-structural-checks（**hard dependency / 実装依存**: 本 Unit 完了時の Unit 完了 hook で 3 種チェックが必須実行される）

### 外部依存

- `git`（**非対話前提**: `git reset --soft <base>` + `git commit -m` で単一再コミット方式を採用。`git rebase` を使う場合は `GIT_SEQUENCE_EDITOR=:` で非対話実行。失敗時の rollback は `git reset --hard ORIG_HEAD` または `git rebase --abort`）

## 非機能要件（NFR）

- **パフォーマンス**: 通常の Squash 操作（数コミット）で 1 秒以内
- **セキュリティ**: rollback 保証（**`git reset --soft` 方式を採用**: 失敗時は `git reset --hard ORIG_HEAD` で作業ツリーを Squash 開始前の状態に戻す。`git rebase` 方式を将来採用する場合のみ `git rebase --abort` で復旧する）
- **スケーラビリティ**: 対象外
- **可用性**: `git` 不可時は exit 1（事実上 git 必須環境のみ）

## 技術的考慮事項

- Construction Phase の `commit-flow.md` Squash 統合フローを再利用するため、共通関数化を検討する。ただし本 Unit のスコープは Operations 側のみなので、共通関数化が困難な場合は Operations 専用実装としてもよい
- **`release_prep_commit` slot の確定仕様**:
  - **記録媒体**: `.aidlc/cycles/<cycle>/operations/progress.md`（`progress.md` 一本化、別ファイル不採用）
  - **記録フォーマット**: 既存の固定スロット（spec §7.4 の `release_gate_ready` / `completion_gate_ready` / `pr_number`）と同一の HTML コメント形式で追加。例: `<!-- release_prep_commit: <40 桁 SHA> -->`
  - **書き込み位置**: 既存の固定スロット直後の専用セクション。1 行 1 slot で配置
  - **パース方法**: AI agent または bash スクリプトで `grep -E '^<!-- release_prep_commit: [0-9a-f]{40} -->$'` のパターンマッチで抽出
  - **未存在判定**: パターンに合致する行が 0 件の場合は未存在扱い（`squash:skipped:reason=release_prep_commit_missing` を返す）
  - **既存 progress.md の後方互換**: v2.5.1 以前のサイクルから引き継いだ progress.md は本 slot を含まないため、未存在判定で安全に skip される
- **rollback 保証のテスト方針（`reset --soft` 固定方式）**: BATS で以下の異常系フィクスチャを用意:
  - `git commit` 失敗（例: hook で人工的に exit 1）→ `ORIG_HEAD` 復旧後に作業ツリーが Squash 開始前と同一であることを検証
  - `release_prep_commit` slot 未存在 → `squash:skipped:reason=release_prep_commit_missing` で継続することを検証
  - `release_prep_commit` から HEAD まで対象 0 件 → `squash:skipped:reason=no_commits` で継続することを検証
  - `git rebase` 採用時のコンフリクト系テストは将来方式切替時の課題として分離（本 Unit のテスト対象外）
- 7.12 の `pre-merge-uncommitted-detected` ガード（v2.5.1 Unit 005 / #616）は既存維持。Squash サブステップ実行後に `validate-git.sh uncommitted` で `uncommitted=ok` を確認する

## 関連Issue

- #639（Operations Phase で 7.12 PR レビュー反映コミットが squash されずに merge される）

## 実装優先度

Medium（履歴の粒度問題で機能影響なし。ただし Construction との整合性として重要）

## 見積もり

中（Operations Phase ステップ改修 + progress.md slot 新設 + 異常系契約実装 + BATS テスト）。0.5 〜 1 日。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
