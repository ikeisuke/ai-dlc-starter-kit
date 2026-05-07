# Unit: worktree 環境立ち上げ時のメインリポジトリ health check 追加

## 概要

worktree 環境で AI-DLC を運用する際、Operations Phase 開始時にメインリポジトリの状態異常（unmerged paths / コンフリクト残骸 / マージ進行中状態）を早期検出する health check helper を新設する。Operations Phase 終盤の `post-merge-cleanup.sh` 失敗ではなくサイクル開始時点で対処できるようにする。

## 含まれるユーザーストーリー

- ストーリー 2: worktree 環境立ち上げ時のメインリポジトリ health check（#657）

## 責務

- `skills/aidlc/scripts/main-repo-health-check.sh`（新設）を作成し、以下 3 項目を実施:
  1. **unmerged paths 検出**: メインリポジトリの `git status --porcelain` 出力で `^UU ` / `^AA ` / `^DD ` 等のマージコンフリクト行を検出
  2. **マージ進行中状態の検出**: メインリポジトリの `.git/MERGE_HEAD` / `.git/CHERRY_PICK_HEAD` / `.git/REBASE_HEAD` ファイルの存在確認
  3. **コンフリクトマーカー scan**: メインリポジトリの worktree 配下の tracked ファイルに `<<<<<<< ` / `>>>>>>> ` / `^=======$` パターンが残存していないか scan（**主経路: `git grep -I`** による tracked + バイナリ自動除外。`git ls-files` 経由は代替経路として記載するが、BSD/GNU 差異吸収のため `git grep` 中心に統一する）
- 終了コード規約（`skills/aidlc/guides/exit-code-convention.md` 準拠）:
  - `0`: 正常完了（健全 + 警告検出を含む。警告は stdout の `status:warning` および `health-check:<項目>:warning:<detail>` で通知）
  - `1`: バリデーションエラー（引数不正等。本 helper は引数を取らないため通常発生しない）
  - `2`: システムエラー（メインリポジトリパス解決失敗、git コマンド失敗等）
- stdout 出力:
  - 全体ステータス: `status:ok` / `status:warning` / `error:<code>:<message>`（システムエラー時）
  - 各項目: `health-check:<項目>:<status>:<detail>` 形式で機械可読出力
- `skills/aidlc/steps/operations/01-setup.md` から health check の **必須呼び出し**を追加（**step:3a** に確定: プリフライト直後 / セッションタイトル設定前。詳細は計画ファイル「挿入位置の決定」参照）。呼び出し側は **stdout の `status:warning` を判定**して警告表示・続行可否を決定する（exit code 1 を warning として扱わない）
- `tests/main-repo-health-check.bats`（新設）に 4 ケース以上の自動テスト:
  - 健全シナリオ → exit 0 + stdout `status:ok`
  - unmerged paths あり → exit 0 + stdout `status:warning` + 該当項目の `health-check` 行
  - MERGE_HEAD ありシナリオ → exit 0 + stdout `status:warning` + `health-check:merge-in-progress:warning:<detail>`
  - コンフリクトマーカー残骸シナリオ（v2.5.3 再現） → exit 0 + stdout `status:warning` + `health-check:conflict-marker:warning:<detail>`

## 境界

- メインリポジトリの状態異常を **検出するのみ**で、自動修復は行わない（ユーザーへの復旧手順案内のみ）
- 通常リポジトリ（worktree 環境ではない）での動作は best-effort（worktree 環境を主対象とする）
- post-merge-cleanup.sh 自体の改修は本 Unit のスコープ外
- Inception Phase / Construction Phase での health check 呼び出しは本 Unit のスコープ外（Operations Phase 限定）
- メインリポジトリの未コミット差分（コンフリクトを含まないもの）の警告は本 Unit のスコープ外（誤検知を防ぐため）

## 依存関係

### 依存する Unit

- なし（論理依存なし、独立した新設 helper）

### 外部依存

- bash 4+
- `git` CLI（`status --porcelain` / `ls-files` / `rev-parse --git-dir` 等）
- なし（新規外部ライブラリ追加なし）

## 非機能要件（NFR）

- **パフォーマンス**: コンフリクトマーカー scan は **主経路 `git grep -I`** で tracked ファイル + バイナリ自動除外。中規模リポジトリ（数千ファイル）で 1 秒以下を目標
- **セキュリティ**: メインリポジトリのパスは `git rev-parse --git-common-dir` で動的解決し、ハードコード禁止
- **スケーラビリティ**: 影響なし（運用ツール）
- **可用性**: 影響なし
- **後方互換**: 既存の `01-setup.md` のステップ番号体系を維持（step:0 等の追加挿入位置を慎重に選ぶ）

## 技術的考慮事項

- メインリポジトリのパス解決: `git rev-parse --git-common-dir`（worktree 配下からでも親 .git を解決可能）
- worktree 配下ファイルのコンフリクトマーカー scan は **tracked ファイルのみ**対象（`.gitignore` 配下のファイルは無視）
- バイナリファイル除外: `git grep -I` または `file --mime-type` で text/* に限定
- メインリポジトリと worktree の判別: `git rev-parse --is-inside-git-dir` / `git rev-parse --show-toplevel` の組み合わせ
- macOS / Linux 互換性（BSD vs GNU の `grep` / `find` 差異）に注意（`tools:cross-platform-review` 観点）

## 関連Issue

- #657（[Backlog] worktree 環境立ち上げ時のメインリポジトリ health check を追加）
- 関連: v2.5.3 Operations Phase post-merge-cleanup.sh 失敗事例

## 実装優先度

Medium（Should-have / 運用診断時間短縮 / v2.5.3 で 1 度の実害発生）

## 見積もり

- 設計フェーズ: 1 日（domain model / 検出ロジック / cross-platform 互換性 / fixture 設計）
- 実装フェーズ: 2 日（helper 新設 + 01-setup.md への組み込み + bats テスト 4 ケース以上 + fixture 整備 + cross-platform 検証）
- 合計: **3 日**

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-07
- **完了日**: 2026-05-07
- **担当**: Claude Code (AI-DLC) / codex external review
- **エクスプレス適格性**: -
- **適格性理由**: -

> **完了ノート (2026-05-07)**: Unit 005（review-flow `last_round_clean` 化）完了後に再開し、新ルール下でレビューを継続して完了。計画レビュー Round 1〜4（最終 Round 4 で 0 件、last_round_clean）/ 設計レビュー Round 1〜5（Round 5 残指摘 1 件低をユーザー判断で resolve）/ コードレビュー Round 1-2（Round 2 で 0 件、last_round_clean）/ 統合レビュー Round 1-2（Round 1 残指摘を完了処理で resolve）。
