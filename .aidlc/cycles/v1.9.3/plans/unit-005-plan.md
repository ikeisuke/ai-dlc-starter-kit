# Unit 005 計画: env-info.sh セットアップ情報追加

## 概要

env-info.sh に `--setup` オプションを追加し、セットアップ時に必要な情報を一括出力できるようにする。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/bin/env-info.sh` | --setup オプション追加、追加情報出力機能 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: スクリプトの責務と出力仕様を定義
2. **論理設計**: オプション解析と情報取得ロジックを設計

### Phase 2: 実装

1. **コード生成**: env-info.sh に以下を追加
   - `--setup` オプションの引数解析
   - project.name 取得（docs/aidlc.toml から）
   - backlog.mode 取得（docs/aidlc.toml から）
   - current_branch 取得（git branch --show-current）
   - latest_cycle 取得（docs/cycles/ 配下の最新ディレクトリ）

2. **テスト**: 手動テストで動作確認

## 出力仕様

### 既存出力（オプションなし）
```
gh:available
dasel:available
jj:available
git:available
```

### --setup オプション時の出力
```
gh:available
dasel:available
jj:available
git:available
project.name:ai-dlc-starter-kit
backlog.mode:issue-only
current_branch:main
latest_cycle:v1.9.2
```

## 完了条件チェックリスト

- [ ] --setup オプションが追加されている
- [ ] project.name, backlog.mode, current_branch, latest_cycle が出力される
- [ ] 既存出力（オプションなし）との後方互換性が維持されている
