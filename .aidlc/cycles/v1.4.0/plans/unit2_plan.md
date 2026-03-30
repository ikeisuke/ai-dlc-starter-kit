# Unit 2: GitHub Issue確認とセットアップ統合 - 実装計画

## 概要

Inception Phase開始時にGitHub Issueを確認し、ブランチ作成を確実に提案する機能を追加

## 対象ファイル

**編集対象**: `prompts/package/prompts/inception.md`

> **注意**: `docs/aidlc/` は `prompts/package/` の rsync コピーのため直接編集禁止。必ず `prompts/package/` を編集する。

## 変更内容

### 1. ステップ1にブランチ確認を追加

現在のステップ1（サイクル存在確認）に、以下の機能を追加：

- 現在のブランチ名を確認
- main/masterブランチの場合、サイクル用ブランチ（`cycle/vX.X.X`）の作成を提案

**追加位置**: ステップ1の冒頭（サイクル存在確認の前）

### 2. ステップ2.5の後にGitHub Issue確認を追加（ステップ2.7）

Dependabot PR確認（ステップ2.5）と同様の形式で、オープンなIssueを確認：

```bash
# GitHub CLIの利用可否確認と Issue一覧取得
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    gh issue list --state open --limit 10
else
    echo "SKIP: GitHub CLI not available or not authenticated"
fi
```

**判定ロジック**:
- SKIP: 次のステップへ進行
- 0件: 「オープンなIssueはありません」と表示
- 1件以上: 今回のサイクルで対応するかユーザーに確認

## Phase 1: 設計

### ドメインモデル設計

このUnitはプロンプト編集のみで、コードは書かないため、ドメインモデル設計は**簡略化**します。

**設計対象**:
- ブランチ確認フロー（既存のサイクル存在確認フローの拡張）
- Issue確認フロー（既存のDependabot PR確認フローと同様）

### 論理設計

**コンポーネント**:
- `inception.md` のステップ1拡張（ブランチ確認）
- `inception.md` のステップ2.7追加（Issue確認）

**依存関係**:
- GitHub CLI（gh コマンド）
- 既存のDependabot PR確認フローと同じパターン

## Phase 2: 実装

### コード生成

`prompts/package/prompts/inception.md` を編集：

1. ステップ1にブランチ確認ロジックを追加
2. ステップ2.7（GitHub Issue確認）を追加

### テスト生成

このUnitはプロンプト編集のため、自動テストは不要。手動確認項目：

- [ ] main/masterブランチでの動作確認
- [ ] GitHub CLI未認証時のスキップ確認
- [ ] オープンなIssueがある場合の表示確認

## 見積もり

- ドメインモデル設計: 簡略（プロンプト編集のため）
- 論理設計: 簡略
- コード生成: `inception.md` への2箇所の追加
- 統合とレビュー: 手動確認

## リスク

- GitHub CLI の出力形式変更による影響（低リスク）
