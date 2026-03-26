# ドメインモデル: Issue駆動統合設計

## 概要
GitHub Issuesを活用してAI-DLCサイクル（Inception → Construction → Operations）の進捗を可視化・管理するための概念モデルを定義する。個人/小規模チーム向けのシンプルな運用を前提とする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

---

## 設計前提

- **プラットフォーム**: GitHub のみ
- **利用シナリオ**: 個人/小規模チーム向け、シンプルな運用
- **自動化**: 手動でのIssue管理が中心（将来の自動化は拡張として検討）

---

## エンティティ（Entity）

### Issue
GitHub Issueの基本単位。AI-DLCサイクルのタスクや課題を表現する。

- **ID**: Issue Number（GitHub自動採番）
- **属性**:
  - title: String - Issueのタイトル（内容を端的に表現）
  - body: Markdown - Issueの詳細説明（テンプレートに従う）
  - state: IssueState - 状態（Open/Closed）
  - labels: Label[] - 分類用ラベル
  - milestone: Milestone - 所属するマイルストーン（サイクルバージョン）
  - assignees: User[] - 担当者（個人利用では省略可）
- **振る舞い**:
  - open(): 新規Issueを作成
  - close(): Issueを完了としてクローズ
  - reopen(): クローズしたIssueを再オープン
  - addLabel(label): ラベルを追加
  - removeLabel(label): ラベルを削除

### Milestone
サイクルバージョンに対応。複数のIssueをグループ化する。

- **ID**: Milestone ID（GitHub自動採番）
- **属性**:
  - title: String - マイルストーン名（例: "v1.0.1"）
  - description: String - マイルストーンの説明
  - dueDate: Date - 期限（任意）
  - state: MilestoneState - 状態（Open/Closed）
- **振る舞い**:
  - create(): 新規マイルストーンを作成
  - close(): マイルストーンをクローズ（サイクル完了時）
  - getProgress(): 進捗率を取得（Closed Issues / Total Issues）

---

## 値オブジェクト（Value Object）

### IssueState
- **属性**: value: Enum - "open" | "closed"
- **不変性**: Issue作成後、状態はopen/closedのみ遷移
- **等価性**: value値が同じであれば等価

### IssueType
Issueの種類を分類するラベル。

- **属性**: value: Enum
- **値**:
  - `epic` - 複数Unitをまとめる大きな単位（Intent相当）
  - `unit` - 1つのUnitに対応する実装単位
  - `bug` - バグ報告・修正
  - `task` - 小さな改善タスク

### Phase
AI-DLCフェーズを示すラベル。

- **属性**: value: Enum
- **値**:
  - `inception` - Inception Phase
  - `construction` - Construction Phase
  - `operations` - Operations Phase

### Priority
優先度を示すラベル。

- **属性**: value: Enum
- **値**:
  - `critical` - 最優先
  - `high` - 高
  - `medium` - 中
  - `low` - 低

---

## AI-DLCサイクルとの対応関係

| AI-DLC概念 | GitHub Issue概念 | 備考 |
|-----------|-----------------|------|
| サイクル（v1.0.1等） | Milestone | 1サイクル = 1マイルストーン |
| Intent | Epic Issue | type:epicラベル付きIssue |
| Unit | Unit Issue | type:unitラベル付きIssue |
| ユーザーストーリー | Issue本文内に記載 | Unit Issue内に含める |
| フェーズ | Label (phase:*) | phase:inception等 |
| 優先度 | Label (priority:*) | priority:high等 |

---

## ラベル体系

### 必須ラベル

| カテゴリ | ラベル名 | 色（推奨） | 説明 |
|---------|---------|-----------|------|
| Type | `type:epic` | #7057ff (紫) | Epic Issue |
| Type | `type:unit` | #0075ca (青) | Unit Issue |
| Type | `type:bug` | #d73a4a (赤) | バグ |
| Type | `type:task` | #0e8a16 (緑) | 小タスク |
| Phase | `phase:inception` | #fbca04 (黄) | Inception Phase |
| Phase | `phase:construction` | #1d76db (青) | Construction Phase |
| Phase | `phase:operations` | #5319e7 (紫) | Operations Phase |

### 任意ラベル（必要に応じて使用）

| カテゴリ | ラベル名 | 色（推奨） | 説明 |
|---------|---------|-----------|------|
| Priority | `priority:critical` | #b60205 (濃赤) | 最優先 |
| Priority | `priority:high` | #d93f0b (オレンジ) | 高優先度 |
| Priority | `priority:medium` | #fbca04 (黄) | 中優先度 |
| Priority | `priority:low` | #0e8a16 (緑) | 低優先度 |
| Status | `status:blocked` | #000000 (黒) | ブロック中 |

---

## 状態遷移モデル

### Issue状態遷移

```
[作成] --> Open --> Closed
              ^        |
              |        v
              +-- Reopen（必要時）
```

### フェーズ遷移とラベル

```
Inception Phase (phase:inception)
    |
    | Unit定義完了
    v
Construction Phase (phase:construction)
    |
    | 実装完了
    v
Operations Phase (phase:operations)
    |
    | サイクル完了
    v
Issue Close + Milestone Close
```

---

## ドメインモデル図

```mermaid
classDiagram
    class Issue {
        +number: Int
        +title: String
        +body: Markdown
        +state: IssueState
        +labels: Label[]
        +milestone: Milestone
        +open()
        +close()
        +addLabel()
    }

    class Milestone {
        +id: Int
        +title: String
        +state: MilestoneState
        +getProgress()
    }

    class Label {
        +name: String
        +color: String
    }

    class IssueType {
        <<enumeration>>
        epic
        unit
        bug
        task
    }

    class Phase {
        <<enumeration>>
        inception
        construction
        operations
    }

    Issue "*" --> "0..1" Milestone : belongs to
    Issue "*" --> "*" Label : has
    Label ..> IssueType : type:*
    Label ..> Phase : phase:*
```

---

## ユビキタス言語

このドメインで使用する共通用語：

- **Epic Issue**: 複数のUnitをまとめる親Issue。AI-DLCのIntentに相当
- **Unit Issue**: 1つのUnitに対応するIssue。実装の基本単位
- **マイルストーン**: サイクルバージョン（v1.0.1等）に対応するGitHub Milestone
- **フェーズラベル**: AI-DLCの3フェーズを示すラベル（phase:inception等）
- **タイプラベル**: Issueの種類を示すラベル（type:epic, type:unit等）

---

## 不明点と質問（設計中に記録）

[Question] このIssue駆動統合は、どのプラットフォームを主なターゲットとしますか？
[Answer] GitHub のみ

[Question] Issue駆動統合の利用シナリオについて確認させてください。
[Answer] 個人/小規模チーム向け、シンプルな運用、手動でのIssue管理が中心

---

## 設計判断の記録

1. **シンプルさ優先**: 個人/小規模チーム向けのため、複雑なワークフローやステータス管理は省略
2. **GitHub標準機能のみ**: GitHub Actions等の自動化は将来の拡張として位置づけ
3. **ラベル体系の最小化**: 必須ラベルを最小限に抑え、運用負荷を軽減
4. **マイルストーン = サイクル**: 1サイクル1マイルストーンの単純な対応関係
