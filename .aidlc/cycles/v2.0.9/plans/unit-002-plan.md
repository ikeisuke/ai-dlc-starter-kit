# Unit 002 計画: Construction/Opsステップファイル乖離修正

## 概要

Construction PhaseおよびOperations Phaseのステップファイルとスクリプトの記述乖離を修正する。v2.0.8総点検で検出された問題を一括修正。

## サブユニット構成

責務境界とレビュー単位を明確化するため、以下の3サブユニットに分割して実装する。

| サブユニット | 責務 | 対象 |
|-------------|------|------|
| A: Construction文書修正 | #474対応 | ステップ文書のみ |
| B: Operations文書修正 | #477のうち文書修正5項目 | ステップ文書のみ |
| C: スクリプト実装修正 | #477のうちスクリプト修正3項目 | .shファイルのみ |

## Source of Truth（依存方向）

各修正項目の正の定義を以下のように定める。修正時は Source of Truth を確認し、consumer側を合わせる。

| 修正対象 | Source of Truth | 修正方向 |
|---------|-----------------|---------|
| `issue-ops.sh` 出力形式 | スクリプト実装（実際の出力） | 文書をスクリプト実装に合わせる |
| `distribution_plan` vs `distribution_feedback` | テンプレートファイル名（実態） | ステップ文書をテンプレートに合わせる |
| `write-history.sh` 複数`--artifacts` | スクリプト実装（引数パース） | 文書をスクリプト実装に合わせる |
| `pr-ops.sh get-related-issues` 出力形式 | スクリプト実装（ヘッダ定義） | ステップ文書をスクリプトヘッダに合わせる |
| `post-merge-cleanup.sh` の `--` | gitコマンド仕様 | スクリプトをgit仕様に合わせる |
| `step_result:4:ok:skipped-*` | スクリプト実装（実際の出力） | ヘッダ定義をスクリプト実装に合わせる |
| `04-completion.md` worktreeフロー | `post-merge-cleanup.sh`の実装 | ステップ文書をスクリプト実装に合わせる |
| `ios-build-check.sh` `file` vs `files` | スクリプト実装（実際の出力） | ヘッダ定義をスクリプト実装に合わせる |

## API契約表

| 項目 | Producer | Consumer | 正の名称/キー | 互換性方針 |
|------|----------|----------|-------------|-----------|
| issue-ops.sh set-status | `issue-ops.sh` | `construction/01-setup.md` | `issue:{N}:status-updated:{status}` | 文書追記のみ |
| distribution template | テンプレートファイル | `operations/02-deploy.md` | テンプレートファイル名の実態に統一 | 文書修正のみ |
| write-history.sh --artifacts | `write-history.sh` | `operations/01-setup.md` | 複数`--artifacts`対応 | 文書追記のみ |
| pr-ops.sh get-related-issues | `pr-ops.sh` | `operations-release.md` | `issues:#123,#456,...` / `issues:none` | 文書追記のみ |
| post-merge-cleanup.sh git cmds | gitコマンド | `post-merge-cleanup.sh` | `--`不要（pull/fetch） | スクリプト修正 |
| step_result拡張形式 | `post-merge-cleanup.sh` | ヘッダ定義 | `step_result:<N>:ok:<qualifier>` | ヘッダ追記 |
| ios-build-check.sh file key | `ios-build-check.sh` | ヘッダ定義・`operations-release.md` | `file:{path}`（found時）/ `files:{paths}`（multiple時） | ヘッダ追記 |

## 変更対象ファイル

### サブユニットA: Construction文書修正（#474）

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/construction/01-setup.md` | ステップ11に`issue-ops.sh set-status`の出力形式を追記 |

### サブユニットB: Operations文書修正（#477 文書4項目）

| # | ファイル | 変更内容 |
|---|---------|---------|
| 1 | `skills/aidlc/steps/operations/02-deploy.md` | `distribution_plan` vs `distribution_feedback` 名称不一致を統一 |
| 2 | `skills/aidlc/steps/operations/01-setup.md` | `write-history.sh`の複数`--artifacts`対応を記述に反映 |
| 3 | `skills/aidlc/steps/operations/operations-release.md` | `pr-ops.sh get-related-issues`出力形式の記述を明確化 |
| 4 | `skills/aidlc/steps/operations/04-completion.md` | worktreeフロー説明の「ステップスキップ」記述を正確化 |
| 5 | `skills/aidlc/steps/operations/operations-release.md` | ステップ7.1の`ios-build-check.sh`出力形式に`file:`キーを追記 |

### サブユニットC: スクリプト実装修正（#477 スクリプト3項目）

| # | ファイル | 変更内容 |
|---|---------|---------|
| 1 | `skills/aidlc/scripts/post-merge-cleanup.sh` | `git pull`/`git fetch`での不要な`--`を除去 |
| 2 | `skills/aidlc/scripts/post-merge-cleanup.sh` | `step_result:4:ok:skipped-branch-not-found`の仕様をヘッダに追記 |
| 3 | `skills/aidlc/scripts/ios-build-check.sh` | ヘッダに`file:`キー（found時の出力）を追記 |

## 実装計画

### Phase 1: 設計

depth_level=standardのため設計を実施するが、本Unitはドキュメント修正+スクリプト軽微修正が主体であり、新規エンティティやコンポーネントの追加はない。上記のSource of Truth定義とAPI契約表が設計に相当する。

### Phase 2: 実装

サブユニット順に実装する:
1. **サブユニットA**: construction/01-setup.mdのステップ11に出力形式追記
2. **サブユニットB**: Operations文書5項目を順次修正
3. **サブユニットC**: スクリプト3項目を順次修正

各サブユニット完了時に差分レビューを実施する。

## 完了条件チェックリスト

### サブユニットA: Construction文書修正
- [ ] issue-ops.sh set-statusの出力形式がconstruction 01-setup.mdに記述されている（#474）
- [ ] Source of Truth（スクリプト実装）との整合確認済み

### サブユニットB: Operations文書修正
- [ ] distribution名称がテンプレートファイル名と統一されている
- [ ] write-history.sh 複数--artifacts対応がoperations/01-setup.mdに反映されている
- [ ] pr-ops.sh get-related-issues出力形式がoperations-release.mdに明記されている
- [ ] 04-completion.md worktreeフロー説明がpost-merge-cleanup.sh実装と整合している
- [ ] operations-release.mdステップ7.1のios-build-check.sh出力形式に`file:`キーが含まれている

### サブユニットC: スクリプト実装修正
- [ ] post-merge-cleanup.shのgit pull/fetchから不要な`--`が除去されている
- [ ] step_result拡張形式（`ok:<qualifier>`）がpost-merge-cleanup.shヘッダに定義されている
- [ ] ios-build-check.shヘッダに`file:`キー（found時の出力）が追記されている
