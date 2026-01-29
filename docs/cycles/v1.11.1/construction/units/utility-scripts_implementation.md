# 実装記録: 定型コマンドのスクリプト化

## 概要

AI-DLCで頻繁に使用する定型コマンドをスクリプト化し、許可リスト設定を簡素化した。

## 実装内容

### 作成したスクリプト

| スクリプト | 機能 |
|------------|------|
| `aidlc-env-check.sh` | gh, dasel, jj, gitの存在確認 |
| `aidlc-git-info.sh` | VCS種類、ブランチ、ワークツリー状態、直近コミット |
| `aidlc-cycle-info.sh` | 現在サイクル、フェーズ、最新サイクル |

### 変更したファイル

- `prompts/package/bin/aidlc-env-check.sh`（新規作成）
- `prompts/package/bin/aidlc-git-info.sh`（新規作成）
- `prompts/package/bin/aidlc-cycle-info.sh`（新規作成）
- `prompts/package/guides/ai-agent-allowlist.md`（セクション6.2追加）

### 技術的な工夫

1. **set -uo pipefail（-e なし）**: コマンド失敗時もスクリプト全体はexit 0を維持
2. **jj/git両対応**: VCS判定ロジックでjjを優先、フォールバックでgitを使用
3. **出力形式統一**: `key:value` 形式でパース可能
4. **許可リストパス**: `prompts/package/bin/` の相対パスを含む表記

## テスト結果

### aidlc-env-check.sh
```text
gh:available
dasel:available
jj:available
git:available
```

### aidlc-git-info.sh
```text
vcs_type:jj
current_branch:(no bookmark)
worktree_status:dirty
recent_commits_count:3
recent_commit_1:o
recent_commit_2:tt feat: [v1.11.1] Unit 003完了 - サンドボックス環境ガイド補完
recent_commit_3:n feat: [v1.11.1] Unit 002完了 - Construction → Operations引き継ぎの仕組み
```

### aidlc-cycle-info.sh
```text
current_cycle:none
cycle_phase:unknown
latest_cycle:v1.11.1
cycle_dir:none
```

- Markdownlint: パス

## AIレビュー

- 設計レビュー: Codex CLIによる3回のレビュー実施、全指摘反映済み
- 実装レビュー: 動作確認完了

## 完了状態

完了
