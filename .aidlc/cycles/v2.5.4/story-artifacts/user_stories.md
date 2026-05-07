# ユーザーストーリー

## ストーリー 1: Operations §7 ステップ7「完了」更新タイミングの明確化（#656）

**As a** AI-DLC を auto mode で実行する AI エージェント
**I want** Operations §7 のステップ7「完了」更新タイミングが手順書で明示的に確定されること
**So that** PR マージ前完結契約に違反することなく自律実行できる

### 背景

v2.5.3 サイクルで、AI が PR マージ後に `progress.md` のステップ7状態を「PR準備完了」→「完了」に更新し、`04-completion.md` のマージ前完結ルール（`cycles/{{CYCLE}}/**` 改変禁止）違反を起こした。`02-deploy.md` §7 の「ステップ完了時 progress.md を「完了」に更新」記述が §7.13 マージ前後どちらとも解釈できる曖昧さが原因。

### 受け入れ基準

- `steps/operations/02-deploy.md` §7 のステップ7「完了」更新記述に、サブステップ番号（**§7.7 Git コミット時**）が **明示**されている（grep で「§7.7」と「ステップ7」が同一行または隣接段落に出現）
- `steps/operations/04-completion.md` のマージ前完結ルール（DR-001 / Unit 002 / #583）の禁止記述と矛盾しない（同じく §7.7 を指す記述で整合）
- `steps/operations/operations-release.md` §7 サブステップ列挙にも反映されており、「ステップ7『完了』状態確定タイミング」が一意に定まる
- ドライラン: v2.5.4 自身の Operations Phase で AI が §7.7 Git コミット時に「完了」更新し、§7.13 マージ後に追加編集を **0 回** で完走できる

---

## ストーリー 2: worktree 環境立ち上げ時のメインリポジトリ health check（#657）

**As a** worktree 環境で AI-DLC を運用する開発者
**I want** Operations Phase 開始時にメインリポジトリの状態異常（unmerged paths / コンフリクト残骸 / マージ進行中状態）が早期検出されること
**So that** Operations 終盤の `post-merge-cleanup.sh` 失敗ではなくサイクル開始時点で対処でき、診断時間を短縮できる

### 背景

v2.5.3 サイクルで `post-merge-cleanup.sh` がメインリポジトリの `git checkout main` で `error:pull-failed` で失敗。原因は過去の `git stash pop` 残骸（`<<<<<<< Updated upstream` / `>>>>>>> Stashed changes` のペア）が `review-flow.md` 等 2 ファイルに放置されていたこと。worktree 環境からはメインリポジトリの状態を直接確認しづらく、診断に複数往復が必要だった。

### 受け入れ基準

- `scripts/main-repo-health-check.sh`（または同等の新設 helper）が以下 3 項目を実施:
  1. メインリポジトリの `git status --porcelain` で unmerged paths を検出
  2. `MERGE_HEAD` / `CHERRY_PICK_HEAD` / `REBASE_HEAD` の有無を確認
  3. worktree のファイルにコンフリクトマーカー（`<<<<<<<` / `>>>>>>>` / `=======`）が残存していないか scan
- 健全時 exit code `0`、警告検出時 exit code `1`、致命的エラー時 exit code `2`
- `steps/operations/01-setup.md` から本 health check が **必須呼び出し**として組み込まれている
- ドライラン: v2.5.3 の stash pop 残骸シナリオ（review-flow.md にコンフリクトマーカー 6 件）を fixture で再現し、health check が **exit 1 + WARNING 出力 1 件以上**で検出
- 健全状態（コンフリクトマーカーなし / unmerged なし / MERGE_HEAD なし）では exit 0 で続行

---

## ストーリー 3: 設計レビュー 5R 到達時の千日手・議論密度ガード強化（#658）

**As a** AI-DLC で Construction Phase の設計レビューを実行する AI エージェント
**I want** 設計レビューが 5R に到達する前に千日手の予兆（議論密度過多 / Round 4 以降の新規仮説追加 / 個別点漸進パターン）を早期検出できること
**So that** Construction Phase の停滞を防ぎ、適切なタイミングで OUT_OF_SCOPE 化判断を促せる

### 背景

v2.5.3 Unit 004 で設計レビューが 5R（最大ラウンド）に到達した。現状の `review-flow.md` の千日手検出は「過去 5R 中 3R 連続同種」だが、設計レビュー特有の議論密度・後半での仮説追加・個別点漸進パターンは早期検出できない。Round 3 終了時点で defer 判断のアラートが出れば、5R 到達を回避できる可能性が高い。

### 受け入れ基準

- `steps/common/review-flow.md` に設計レビュー特化の早期 defer ガイドラインが追記される（grep で「Round 3」「defer」「議論密度」のいずれかが該当セクションに **1 箇所以上**ヒット、かつ追記セクションに「Construction Phase 設計レビュー限定」の **明示的な適用条件記述**を含む）
- Round 別指摘件数の閾値が **数値で明示**（例: Round 3 で指摘 ≥ 5 件 → 警告 / Round 4 で指摘 ≥ 3 件 → 警告）かつ警告検出時の **具体的なアクション文言**（例: 「`AskUserQuestion` で『修正続行 / OUT_OF_SCOPE 化』を選択させる」）が文書化されている
- Round 4 以降の **新規仮説追加検出ロジック**（同 Unit 内の設計仮説が Round 4 以降で追加されたら千日手予兆としてユーザー判断を促す）が文書化、かつ判定アルゴリズムの手順（Round 1〜3 と Round 4 以降の review-summary 指摘対象を比較する手順）が **手順番号付きで列挙**されている
- 議論個別点漸進パターン（指摘の対象パスが連続 round で重複し、修正範囲が拡大していくパターン）の検出ガイドが文書化、かつ「個別点漸進」とみなす連続 round 数（例: 3 round 連続）が **数値で明示**
- ドライラン: v2.5.4 自身の Construction Phase 設計レビュー（または擬似 fixture）で、Round 3 終了時に閾値 5 件超過アラートが review-summary に記録されることを確認

---

## ストーリー 4: helper の zsh source 互換性保証

**As a** AI-DLC を zsh シェル環境で運用する開発者 / AI エージェント
**I want** AI エージェントが手順記述に従って `source skills/aidlc/scripts/lib/<helper>.sh && <function>` を zsh から実行しても動作すること
**So that** Claude Code の zsh デフォルトシェル環境でも AI-DLC の helper 群が確実に動作する

### 背景

v2.5.3 リリース直後、`predecessor-issue.sh` を zsh interactive shell で `source && predecessor_resolve_issue v2.5.3` のように実行すると `__PRED_SCRIPT_DIR` 解決に失敗し、helper の source path がカレントディレクトリ起点になって exit 2 になる事象が発生。bash で実行すれば動作するが、AI エージェントがデフォルトシェル（zsh）から手順記述通りに source 呼び出しした場合に壊れる。

### 受け入れ基準

- `bash -c` / `zsh -c` 両方で `source skills/aidlc/scripts/lib/predecessor-issue.sh` 後に **`__PRED_SCRIPT_DIR` 変数が空でない正しいファイルパス**（`skills/aidlc/scripts/lib` を末尾に持つ）として解決されることを確認（**source 互換性のみ**を検証し、`predecessor_resolve_issue` 関数の実行結果（ネットワーク・GitHub 依存）は対象外）
- 同じく `bash -c` / `zsh -c` 両方で `__PRED_SCRIPT_DIR` 解決後の `source "${__PRED_SCRIPT_DIR}/aidlc-paths.sh"` が **exit 0**（`no such file or directory` エラーが発生しない）
- `__PRED_SCRIPT_DIR` の解決が `BASH_SOURCE` 単独依存ではなく、zsh でも動作する代替経路（例: `${(%):-%N}` などの zsh 互換構文 fallback）を持つ
- 全 helper 6 ファイル（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `predecessor-issue.sh` / `retrospective-issue.sh`）に zsh source 動作確認テスト（**6 件以上**、source による SCRIPT_DIR 解決成否を確認するテスト）が追加される
- patch スコープ保護: 修正対象は `predecessor-issue.sh` の 1 ファイル限定。他 5 ファイルはテスト追加のみで構造変更しない

---

## ストーリー 5: AI レビュー完了条件の `last_round_clean` 化（v2.5.4 内部 hotfix）

**As a** AI-DLC で Construction Phase の AI レビューを実行する AI エージェント / 開発者
**I want** Round 1 で指摘 → Round 2 で全 resolve した場合に、追加の Round 3 を強制されず 2R で完了できること
**So that** 修正が完了したレビューに不要なラウンドを重ねず、Construction Phase の所要時間を 1〜2 round 分短縮できる

### 背景

v2.5.2 Unit 001（#635）で導入された 5R 化の「完了条件の判定単一仕様」に `last_two_rounds_clean`（最後 2 round 連続 clean）規則が含まれている。これにより:

- Round 1 で指摘あり → Round 2 で全部修正して clean → Round 3 を強制（修正の妥当性検証目的）

しかし実運用上は以下の不都合がある:

- 1 round 余分にかかる（Codex セッション継続のため指摘 0 になっても通信・処理コストが残る）
- 同一エージェントが同一文脈で再評価するだけのため、独立した検証としての意義が弱い
- 修正自体は指摘内容に応じて行われるため、re-review なしでも修正の妥当性は担保される

v2.5.4 Unit 002 計画レビュー時にユーザーから「2 round clean 要求がよろしくない」との指摘があり、本サイクル内のホットフィックスとして対応する（Issue 起票なし、内部運用改善）。

### 受け入れ基準

- `steps/common/review-flow.md` の「完了条件の判定単一仕様」セクションが `last_round_clean`（直近 round が clean なら完了）ベースに書き換えられている
- `last_two_rounds_clean` の文字列が `steps/common/review-flow.md` から **完全に消える**（`grep -c "last_two_rounds_clean" steps/common/review-flow.md` が **0**）
- 完了条件の規則表現が以下のいずれかの形式で表現されている（実装者の選択）:
  - 形式 A: `last_round_clean` を主規則とし、`1R clean 特例`は自然な帰結として一行記述に縮約
  - 形式 B: `1R clean 特例`を独立規則として残し、`2R 以上 + last_round_clean` を別規則として明記（既存スタイル踏襲）
- どちらの形式でも、**同一 round が二重に判定される矛盾がない**こと（テスト: Round 1 clean / Round 2 clean / Round 5 unresolved の 3 ケースで判定結果が一意）
- `5R 上限`・`defer 自動 Issue 起票`・`千日手検出（5R 中 3R 連続同種）`・`Round 4+ 新領域 backlog 化` は維持（grep で各キーワードが既存と同等以上の件数で残ること）
- `templates/review_summary_template.md` の反復回数表記補注（`v2.5.2 以降の上限値・完了条件`）が **新ルール（`last_round_clean`）と整合**するよう更新されている
- 本 Unit 完了後、本サイクル後続 Unit（002 / 003 / 004）の AI レビューに **新ルールが即時適用**されることを Unit 005 の履歴に記録（適用順序の証跡）
