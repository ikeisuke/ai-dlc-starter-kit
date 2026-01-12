# ドメインモデル: バックログ管理改善

## 概要

AI-DLCにおけるバックログ管理の概念と設定を整理し、modeオプション（git/issue/git-only/issue-only）による一貫した管理方針を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### BacklogMode

バックログの保存先を決定するモード。

- **属性**: mode: string - "git" | "issue" | "git-only" | "issue-only"
- **不変性**: 設定後はサイクル全体で一貫して使用
- **デフォルト値**: "git"

| 値 | 保存先 | 排他性 | 説明 |
|---|--------|-------|------|
| git | `docs/cycles/backlog/*.md` | 許容 | ローカルファイルがデフォルト、状況に応じてIssueも許容 |
| issue | GitHub Issues | 許容 | GitHub Issueがデフォルト、状況に応じてローカルも許容 |
| git-only | `docs/cycles/backlog/*.md` | 排他 | ローカルファイルのみ（Issueへの記録を禁止） |
| issue-only | GitHub Issues | 排他 | GitHub Issueのみ（ローカルファイルへの記録を禁止） |

## エンティティ（Entity）

### BacklogItem

バックログに記録される気づき・課題。

- **ID**: ファイル名（git mode）またはIssue番号（issue mode）
- **属性**:
  - title: string - タイトル
  - discovery_date: date - 発見日
  - discovery_phase: string - 発見フェーズ（Inception/Construction/Operations）
  - discovery_cycle: string - 発見サイクル
  - priority: string - 優先度（高/中/低）
  - summary: string - 概要
  - details: string - 詳細
  - action_plan: string - 対応案
- **振る舞い**:
  - create(): 新規作成
  - migrate(target_mode): 別のmodeへ移行
  - close(): 対応完了としてクローズ

## ドメインサービス

### BacklogMigrationService

バックログアイテムを別のmodeへ移行するサービス。

- **責務**: 既存バックログの新modeへの移行を支援
- **操作**:
  - migrateToGit(issue): GitHub Issue → ローカルファイル
  - migrateToIssue(file): ローカルファイル → GitHub Issue
  - suggestMigration(): 設定されたmodeに基づいて移行先を提案

### BacklogRecordingService

バックログアイテムを記録するサービス。

- **責務**: mode設定に基づいて適切な保存先に記録
- **操作**:
  - record(item, mode): modeに基づいて記録
  - isExclusive(mode): mode が排他的（*-only）かどうかを判定
  - validateRecording(target, mode): 記録先がmodeと整合するか検証

## 設定スキーマ

### aidlc.toml [backlog] セクション

```toml
[backlog]
# mode: "git" | "issue" | "git-only" | "issue-only"
# - git: ローカルファイルがデフォルト、状況に応じてIssueも許容（デフォルト）
# - issue: GitHub Issueがデフォルト、状況に応じてローカルも許容
# - git-only: ローカルファイルのみ（Issueへの記録を禁止）
# - issue-only: GitHub Issueのみ（ローカルファイルへの記録を禁止）
mode = "git"
```

## ユビキタス言語

このドメインで使用する共通用語：

- **バックログ**: 対応が必要だが現在のスコープ外の気づき・課題の一覧
- **mode**: バックログの保存先と排他性を指定（git/issue/git-only/issue-only）
- **排他モード**: `-only` サフィックス付きのmode。指定された保存先のみを使用
- **移行**: あるmodeから別のmodeへバックログアイテムを転送すること

## 不明点と質問（設計中に記録）

（現時点で不明点なし）
