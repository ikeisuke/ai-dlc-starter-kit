# ユーザーストーリー

## Epic: Operations / Construction レビュー周辺の運用ノイズ統合解消（v2.5.5）

v2.5.4 リリース後にバックログへ蓄積された 5 件の高優先度 Issue を統合解消する。Operations Phase 自動化フローのカバレッジ拡大、AI エージェント実行環境互換性の担保、Construction Phase の履歴コミット分裂予防の 3 領域を同時に進める。

---

### ストーリー 1: pr-ops.sh の auto-merge エラー判別精度向上（#665）

**優先順位**: Must-have

As a Operations Phase で `operations-release.sh merge-pr` を AI auto mode で実行している開発者
I want to auto-merge 無効リポジトリ + CI pending 状態でも具体的なエラー種別が返ることを期待する
So that `operations-release.md §7.13` のエラー対処案内が起動し、原因特定のための複数ステップデバッグを回避できる

**受け入れ基準**:

- [ ] `pr-ops.sh` の `auto_error` grep パターンが `auto[- ]merge is not allowed` / `enablePullRequestAutoMerge` を含む（grep でパターン拡張を確認）
- [ ] GitHub CLI 実エラー文言 `GraphQL: Auto merge is not allowed for this repository (enablePullRequestAutoMerge)` を fixture として与えた場合に `pr:<N>:error:auto-merge-not-enabled` を返す（追加 bats テスト 1 件以上）
- [ ] 既存の `auto-merge is not allowed`（ハイフン付き）パターンが引き続き合格する後方互換テストが残っている
- [ ] fixture 更新トリガーの明文化（DR-001）: 「`gh` バージョン更新で実エラー文言が変わった場合に bats fixture が失敗することで気付ける」運用ルールが Unit 001 完了履歴 `history/construction_unit01.md` に 1 行以上記録される（Unit 005 と保守方針を統一）

**技術的考慮事項**:

- 修正対象は `pr-ops.sh:449` 付近の `auto_error` grep ブロックに限定（他エラーパターンの再設計は OUT_OF_SCOPE）
- 既存パターン後方互換を必ず維持

---

### ストーリー 2: retrospective-issue.sh の zsh source 互換性復元（#661）

**優先順位**: Must-have

As a AI エージェント（Claude Code 含む）で zsh interactive shell から AI-DLC helper を `source && 関数呼び出し` する開発者
I want to `retrospective-issue.sh` も `predecessor-issue.sh` と同じ shell 判定分岐方式で動作することを期待する
So that 振り返り Issue 解決経路（v2.5.0+ Issue 一本化方針）が AI エージェント実行環境で確実に動作し、v2.5.4 で skip マーカーを残した bats テストを通常実行に戻せる

**受け入れ基準**:

- [ ] `bash` / `zsh -c` 両方で `source skills/aidlc/scripts/lib/retrospective-issue.sh && retrospective_resolve_issue v2.5.4` が exit 0 で動作（v2.5.4 Unit 004 の predecessor-issue.sh と同等の動作確認）
- [ ] `__RETRO_ISSUE_SCRIPT_DIR` の SCRIPT_DIR 解決が `if [[ -n "${ZSH_VERSION:-}" ]]; then ${(%):-%N}; else ${BASH_SOURCE[0]}; fi` パターンに置換されている（grep で確認）
- [ ] `tests/aidlc-helpers-zsh-source.bats` の `retrospective-issue.sh` テストから `skip "OUT_OF_SCOPE: see backlog #..."` マーカーが削除され、bash/zsh 両 source 検証 + SCRIPT_DIR 検証が通常実行される

**技術的考慮事項**:

- 修正対象は `retrospective-issue.sh` 1 ファイルに限定（他 helper の追加 refactor は OUT_OF_SCOPE）
- `predecessor-issue.sh` の修正パターン（v2.5.4 Unit 004）を踏襲し、独自実装は避ける

---

### ストーリー 3: Construction Unit 完了処理 step5↔step8 分裂の構造的予防（#654）

**優先順位**: Must-have

As a Construction Phase で複数 Unit を一気通貫で完走する開発者
I want to `write-history` 後の履歴ファイルを Unit 完了 commit と同じコミットに統合する手順が文書・スクリプト・チェックリストの三層で保証されていることを期待する
So that v1.15.1 cycle のような 5 Unit × 2 commit = 10 commit 分裂 + rebase fixup（破壊的操作）の再発を構造的に予防できる

**受け入れ基準**:

- [ ] `steps/construction/04-completion.md` ステップ 5/8 の関係に「履歴ファイルを必ず Unit 完了 commit に含める」旨の注記が 1 箇所以上（grep で確認）
- [ ] `steps/common/commit-flow.md` のコミット前チェックリストに「履歴ファイル staged 確認」項目が 1 項目以上追加されている（grep で確認）
- [ ] `scripts/write-history.sh` 実行後に履歴ファイルが unstaged の場合に `warning: history file unstaged` 等の警告を stdout/stderr に出力する（exit code 0 維持、bats テスト 1 件以上で動作確認）
- [ ] ドライラン手順を必須記載項目 3 点固定で文書化: (d-1) `write-history` 実行手順の参照、(d-2) `git status` または `git diff --cached --name-only` で履歴ファイル staged 確認、(d-3) 履歴ファイル `git add` 確認（grep で 3 項目すべての出現を検証）

**技術的考慮事項**:

- 提案 A（文書整合）+ B（チェックリスト追加）+ C（write-history 警告）の 3 層化。提案 D（ステップ 8 への `git add` 明示手順）は提案 A の自然な帰結として吸収（OUT_OF_SCOPE）
- write-history 警告は exit code 0 維持で stdout/stderr 出力のみ（破壊的変更を避ける）

---

### ストーリー 4: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加（#650）

**優先順位**: Must-have

As a Operations Phase の release tag 付与時に GitHub Actions 等の CI で自動 tag 作成ワークフローを併用しているプロジェクト開発者
I want to ローカル `git tag → push` 前にリモート tag 状態を確認し、衝突時の判定マトリクスと fallback 手順が明示されていることを期待する
So that Visitory v1.15.0 cycle のように tag push が reject されて初見では「force push が必要？」と誤判断するリスクを排除できる

**受け入れ基準**:

- [ ] `steps/operations/04-completion.md` ステップ 3 に `git ls-remote --tags origin vX.X.X` による事前確認手順が追加されている（grep で確認）
- [ ] リモート tag 状態の判定マトリクス（3 ケース必須: 不在 / 同 SHA 衝突 / 異 SHA 衝突）が表形式（markdown table）で記載され、各ケースに (b-1) 実行コマンド 1 つ以上、(b-2) 期待結果 1 つ以上、(b-3) 次アクション 1 つ以上、を必須カラムとして含む
- [ ] 同 SHA 衝突時の fallback 手順として (c-1) ローカル tag 削除コマンド、(c-2) `git fetch origin tag vX.X.X` または等価の同期コマンド、(c-3) 同期後検証手順、の 3 項目を文書化
- [ ] 異 SHA 衝突時の手順として (d-1) AI が自動 push を中止する判断保留ルール、(d-2) ユーザーへの差分提示（両 tag のコミット SHA 表示）、(d-3) ユーザー選択肢提示（リモート優先 / ローカル優先 / 中断）、の 3 項目を文書化

**技術的考慮事項**:

- 文書追加が主作業のため bats テスト追加は不要（成功基準を grep / markdown 構造検証で機械的にチェックする検証手段で充足）
- 既存の `version_tag = false`/`true` 設定とは独立した運用補強として位置付け

---

### ストーリー 5: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加（#626）

**優先順位**: Must-have

As a AI エージェントが auto mode で Operations 7.8 `pr-ready` を実行する開発者（特にトークンスコープが制限されているエンタープライズ環境利用者）
I want to `gh pr edit --body-file` がスコープ不足で失敗した場合に `gh api -X PATCH` で REST 直叩きする fallback が `operations-release.sh pr-ready` に組み込まれていることを期待する
So that Operations 自動化フローが手動 fallback なしで完走でき、Visitory v1.14.2 cycle のような中断を回避できる

**受け入れ基準**:

- [ ] `scripts/operations-release.sh pr-ready` で `gh pr edit --body-file` 実行時にスコープ不足エラー（`read:org` / `read:discussion` / GraphQL field error 等）を grep 検出する分岐が追加されている（grep で確認）
- [ ] 検出時に `gh api -X PATCH /repos/{owner}/{repo}/pulls/{number} -F body=@<file>` で REST PATCH fallback を実行する経路が追加されている
- [ ] bats テスト追加: `gh pr edit --body-file` がスコープ不足エラーを返す fixture を与えた場合に REST PATCH fallback が呼ばれ exit 0 で完了する（追加テスト 1 件以上）
- [ ] スコープ不足以外のエラーは従来通り上位に伝播し、無関係な失敗を fallback で握り潰さない（後方互換テスト）

**技術的考慮事項**:

- fallback の grep 検出キーワードは `read:org` / `read:discussion` / GraphQL field error 系を網羅するが、判別パターンが将来の `gh` バージョンで変わる可能性は fixture-based bats テストで現行 `gh` 出力を固定化することで気付けるようにする
