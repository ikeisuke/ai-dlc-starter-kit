# Unit 001 実装計画: release フロー骨格 + リリース準備ゲート

## 対象 Unit

`001-release-flow-skeleton-and-readiness-gate` — `skills/aidlc-v3/steps/release.md` を新規作成し、release フェーズの骨格（Step 1–4 の章立て・パス解決・スクリプト契約の書式）と Step 1「リリース準備」を実装する。後続 Unit（PR 整備・merge・統合）の土台。

- **サイクル**: v3.0.0-alpha.6
- **depth_level**: standard
- **automation_mode**: semi_auto / **review_mode**: required
- **関連 Issue**: #736（部分対応 / Relates）

## スコープ

### 含まれるもの（本 Unit で実装）

1. **`skills/aidlc-v3/steps/release.md` の新規作成**
   - `steps/define.md` / `steps/develop.md` の「Step + ゲート(★) + 成果物 + スクリプト usage/exit code 契約」書式を踏襲。
   - 位置づけ注記・目的・フロー全体表（Step 1–4）・パス解決セクションを置く。
   - Step 0「前提確認（clean-worktree + cycle 解決）」を develop.md Step 0 に準じて記述。
   - Step 1–4 の章立て骨格を配置。**Step 1 のみ実装、Step 2–4 は「Unit 002/003 で実装」のプレースホルダ見出しに留める**。
2. **Step 1「リリース準備」の実装**
   - 全 work item の frontmatter `status` が `done` / `withdrawn` であることを検出。未完了（`pending` / `in_progress` / `blocked`）が残る場合は一覧提示して停止（mutation なし）。
   - `define_completed: false` / state.json 不在時は release に入らず define/develop へ案内。
   - git status 確認（dirty=停止）/ test・CI 状態確認（test失敗・CI失敗=停止、CI未実行=警告継続）を明記。
   - **read-only**: state.json への書き込みは行わない。既存 `state-read.sh` / `work-item-validate.sh` を read-only 利用。

### 含まれないもの（境界 / 後続 Unit）

- `SKILL.md` の `release` コマンドの「予約→実装済み」公開フリップ・express 整合（Unit 004）。**本 Unit では `release` を「予約」のまま据え置く**。
- PR 作成・ready 化・release.md 成果物作成・review ルーティング（Unit 002）。
- merge 承認・実行・post-merge cleanup（Unit 003）。
- 新規テストファイルの追加・回帰検証の本格実施（Unit 004 が担当）。本 Unit では `scripts/tests/` に新規テストを追加せず、既存 v3 テストを実行して green（回帰なし）であることの sanity 確認に留める（※下記「テスト方針」参照）。
- フェーズ導出規則・state.json schema の定義（`docs/v3/data-model.md §3 / §5` を参照するのみ、再定義しない）。

## 設計 SoT（再定義せず参照）

- `docs/v3/workflow.md §3.3`（release フェーズ Step 1–4 / Step 1 規定）
- `docs/v3/workflow.md §6`（review perspective — 骨格の表記参照のみ）
- `docs/v3/data-model.md §3`（state.json schema / `release.*`）, `§5.1`（complete 判定）, `§8`（review 集約方針）

## 実装アプローチ

1. **書式の踏襲**: `define.md` Step 4 / `develop.md` Step 0–1 の記述書式（番号付き手順 + `bash` ブロック + exit code 契約の箇条書き）をお手本にする。
2. **Step 1 のゲート構成**:
   - 前提: `state-read.sh current_cycle` / `state-read.sh define_completed` で state を read。state.json 不在（exit 1）→ define/develop 案内で停止。
   - work item 完了確認: `.aidlc/cycles/<cycle>/work-items/*.md` の frontmatter `status` を走査。`done` / `withdrawn` 以外が残れば一覧提示して停止。実装は `work-item-validate.sh`（read-only）+ `lib/frontmatter.sh` の構造解釈を参考にし、**enum 検証ロジックを本体に重複定義しない**。
   - git status: `git status --porcelain` で dirty 検出 → 停止。
   - test 確認: 既存 v3 テスト入口（`scripts/tests/` のテストランナー）を**その場で実行**し、exit 0=継続 / non-zero=停止。
   - CI 確認: `gh_status=available` 時のみ `gh`（`gh run list` 系）で対象ブランチ/コミットの最新 CI conclusion を参照。success=継続 / failure=停止 / pending・未実行・取得不能（`gh` 不在含む）=警告して継続。CI ワークフローが存在しない環境でも警告継続（停止しない）。
   - 上記の判定セマンティクス（test の exit / CI の conclusion → 継続・停止・警告）は本計画で確定する。release.md に記す具体的なコマンド文字列の最終整形のみ実装時に行う（`docs/v3/workflow.md §3.3` と整合）。
3. **mutation なし**: Step 1 は読み取りと案内のみ。state 書き込み・status 遷移は行わない。
4. **Bash ツール安全規約**: 手順内コマンド例にも `$(...)` / backtick 禁止を適用。
5. **クロスプラットフォーム**: コマンド例は macOS / Linux 両対応。

## 変更ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `skills/aidlc-v3/steps/release.md` | 新規作成 | Step 1–4 骨格 + Step 0 + Step 1 実装 |

- `SKILL.md` は **変更しない**（公開フリップは Unit 004）。
- `scripts/tests/` への新規テスト追加は行わない（テスト追加は Unit 004）。

## テスト方針

- 本 Unit では新規テストファイルを追加しない（テスト追加は Unit 004 の責務）。`steps/release.md` は手順（markdown）であり実行コードを増やさず、依存する既存スクリプト（`state-read.sh` / `work-item-validate.sh`）の挙動も変更しないため、新規テストの追加対象が無い。
- 変更後に既存 v3 テスト（`scripts/tests/`）を実行し、green（回帰ゼロ）であることを sanity 確認する（新規テストの作成・回帰検証の本格実施は Unit 004）。
- gh 依存部分は Step 1 のテスト対象には無い（PR 操作は Unit 002 以降）。

## NFR

- **保守性**: release.md は SoT（data-model / workflow）を再定義せず参照する。
- **互換性**: 既存 v3 テストを壊さない。state.json への書き込みを行わない（read-only）。
- **クロスプラットフォーム**: macOS / Linux 両対応。

## 完了条件チェックリスト

- [ ] `skills/aidlc-v3/steps/release.md` が新規作成され、Step 1–4 の章立て骨格（ゲート・成果物・スクリプト契約の書式）を持つ
- [ ] パス解決セクション（`scripts` はスキルベース相対 / cycle 成果物は `.aidlc/` 配下 / フェーズ導出 SoT は `docs/v3`）が記述されている
- [ ] Step 0「前提確認」で current_cycle 解決・state.json 不在時の扱い・clean-worktree 前提が明記されている
- [ ] Step 1「リリース準備」が実装され、全 work item の `done`/`withdrawn` 完了検出を行う
- [ ] 未完了 work item（`pending`/`in_progress`/`blocked`）残存時に一覧提示して停止する手順がある
- [ ] `define_completed: false` / state.json 不在時に release に入らず define/develop へ案内する手順がある
- [ ] git status（dirty=停止）/ test・CI 状態（失敗=停止・未実行=警告継続）の確認手順が Step 1 に明記されている
- [ ] Step 1 が read-only（state.json への書き込みなし）である
- [ ] `SKILL.md` の `release` コマンドの公開フリップ・PR 整備・merge は本 Unit で扱っていない（境界遵守）
- [ ] 設計 SoT（docs/v3）を再定義していない（参照のみ）
- [ ] Bash ツール安全規約（`$(...)` / backtick 禁止）を手順内コマンド例にも適用している
- [ ] 既存 v3 テストが green を維持している（回帰ゼロ）

## 見積もり

0.5〜1 日（release.md 骨格 + Step 1）
