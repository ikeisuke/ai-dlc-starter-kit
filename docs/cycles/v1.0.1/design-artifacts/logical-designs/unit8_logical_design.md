# 論理設計: セットアップファイル最適化

## 概要
1746行のセットアップファイルを5つのファイルに分割し、可読性・保守性を向上させる。

**重要**: この論理設計では**コードは書かず**、分割方針と構成定義のみを行います。

---

## アーキテクチャパターン
**モジュラー構成**: メインファイルがエントリーポイントとなり、フェーズ別ファイルに処理を委譲する構成。各ファイルは単一責務を持ち、独立して読み込み・修正可能。

---

## コンポーネント構成

### ファイル構成

```
prompts/
├── setup-prompt.md (メイン: 300行目安)
│   ├── 変数定義
│   ├── MODE判定
│   ├── AI-DLC概要（圧縮版）
│   └── フェーズ別ファイル参照指示
│
└── setup/
    ├── inception.md (500行目安)
    │   ├── inception.mdプロンプト生成
    │   └── テンプレート: intent, user_stories, unit_definition, prfaq, inception_progress
    │
    ├── construction.md (500行目安)
    │   ├── construction.mdプロンプト生成
    │   └── テンプレート: domain_model, logical_design, implementation_record
    │
    ├── operations.md (500行目安)
    │   ├── operations.mdプロンプト生成
    │   └── テンプレート: deployment_checklist, monitoring_strategy, distribution_feedback, post_release_operations, operations_progress
    │
    └── common.md (200行目安)
        ├── ディレクトリ作成手順
        ├── 共通ファイル生成 (history.md, additional-rules.md, index.md, backlog関連)
        └── 完了処理・次ステップ表示
```

### コンポーネント詳細

#### setup-prompt.md（メイン）
- **責務**: セットアップのエントリーポイント、MODE判定、フェーズ分岐
- **依存**: なし（他ファイルを参照する側）
- **公開インターフェース**:
  - MODE = list: 利用可能テンプレート一覧を表示
  - MODE = template: 指定テンプレートを表示
  - MODE = setup: セットアップ実行

#### setup/inception.md
- **責務**: Inception Phase関連のプロンプト・テンプレート生成
- **依存**: setup-prompt.mdから参照される
- **含まれる内容**:
  - inception.mdプロンプト本体
  - intent_template.md
  - user_stories_template.md
  - unit_definition_template.md
  - prfaq_template.md
  - inception_progress_template.md

#### setup/construction.md
- **責務**: Construction Phase関連のプロンプト・テンプレート生成
- **依存**: setup-prompt.mdから参照される
- **含まれる内容**:
  - construction.mdプロンプト本体
  - domain_model_template.md
  - logical_design_template.md
  - implementation_record_template.md

#### setup/operations.md
- **責務**: Operations Phase関連のプロンプト・テンプレート生成
- **依存**: setup-prompt.mdから参照される
- **含まれる内容**:
  - operations.mdプロンプト本体
  - deployment_checklist_template.md
  - monitoring_strategy_template.md
  - distribution_feedback_template.md
  - post_release_operations_template.md
  - operations_progress_template.md

#### setup/common.md
- **責務**: 共通処理（ディレクトリ作成、共通ファイル生成、完了処理）
- **依存**: setup-prompt.mdから参照される
- **含まれる内容**:
  - ディレクトリ構成作成手順
  - history.md生成
  - additional-rules.md生成
  - templates/index.md生成
  - backlog.md, backlog_completed.md生成
  - 完了確認・次ステップ表示

---

## 処理フロー概要

### セットアップ実行フロー

**ステップ**:
1. setup-prompt.mdを読み込み
2. 変数定義・MODE判定
3. MODE = setup の場合:
   a. setup/common.mdの「ディレクトリ作成」を実行
   b. setup/inception.mdの「プロンプト生成」を実行
   c. setup/construction.mdの「プロンプト生成」を実行
   d. setup/operations.mdの「プロンプト生成」を実行
   e. setup/common.mdの「共通ファイル生成」を実行
   f. setup/common.mdの「完了処理」を実行

**関与するコンポーネント**: 全ファイル

---

## 分割詳細（現行ファイルの対応表）

### setup-prompt.md に残す内容
| 現行行番号 | 内容 |
|-----------|------|
| 1-65 | 変数定義、MODE判定 |
| 65-144 | 実行環境確認、AI-DLC概要（圧縮して残す） |
| - | フェーズ別ファイル参照指示（新規追加） |

### setup/inception.md に移動
| 現行行番号 | 内容 |
|-----------|------|
| 252-349 | inception.mdプロンプト |
| 594-628 | intent_template |
| 629-656 | user_stories_template |
| 657-704 | unit_definition_template |
| 705-738 | prfaq_template |
| 1400-1437 | inception_progress_template |

### setup/construction.md に移動
| 現行行番号 | 内容 |
|-----------|------|
| 349-423 | construction.mdプロンプト |
| 739-824 | domain_model_template |
| 825-951 | logical_design_template |
| 952-1011 | implementation_record_template |

### setup/operations.md に移動
| 現行行番号 | 内容 |
|-----------|------|
| 423-537 | operations.mdプロンプト |
| 1012-1125 | deployment_checklist_template |
| 1126-1242 | monitoring_strategy_template |
| 1243-1302 | distribution_feedback_template |
| 1303-1399 | post_release_operations_template |
| 1438-1479 | operations_progress_template |

### setup/common.md に移動
| 現行行番号 | 内容 |
|-----------|------|
| 148-201 | ディレクトリ作成 |
| 537-577 | history.md, additional-rules.md生成 |
| 1480-1605 | templates/index.md生成 |
| 1606-1746 | バージョン記録、完了処理、次ステップ |
| - | backlog関連（Unit 4で追加済み） |

---

## 圧縮方針

### 1. 冗長な説明の簡潔化
- 「以下のファイルを作成してください」→「作成:」
- 繰り返される説明文の統合

### 2. 空行の削減
- テンプレート内の連続空行を1行に
- セクション間の空行を最小限に

### 3. コメントの最適化
- 自明な説明コメントを削除
- 重要な注意事項のみ残す

---

## 非機能要件（NFR）への対応

### 可読性
- **要件**: 各ファイル500行以内
- **対応策**: フェーズ別分割、圧縮

### 保守性
- **要件**: フェーズごとに独立した修正可能
- **対応策**: 単一責務の分割、明確な境界

### 互換性
- **要件**: 既存セットアップ手順を完全維持
- **対応策**: 機能の増減なし、参照方式のみ変更

### テスト容易性
- **要件**: 分割後のセットアップ動作確認
- **対応策**: 既存プロジェクトで動作テスト

---

## 実装上の注意事項
- 分割時にテンプレートの`EOF`マーカーを壊さない
- 変数参照（`{{AIDLC_ROOT}}`等）を正確に維持
- heredocの開始・終了を正しく対応させる

---

## 不明点と質問（設計中に記録）

（現時点で不明点なし - 分割方針が明確なため）

---

## 作成日時
2025-11-28
