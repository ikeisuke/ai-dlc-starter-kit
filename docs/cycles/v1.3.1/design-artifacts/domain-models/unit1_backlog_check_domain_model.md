# ドメインモデル: バックログ対応済みチェック

## 概要

Inception Phaseのバックログ確認ステップにおいて、対応済みバックログファイル（backlog-completed.md）との照合を行い、重複や類似項目をユーザーに通知する機能のドメインモデル。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はプロンプト修正として行います。

## 値オブジェクト（Value Object）

### BacklogItem（バックログ項目）
- **属性**:
  - title: String - 項目の見出し（例: 「バックログ項目の対応済みチェック」）
  - description: String - 詳細説明
  - source: Enum(common, cycle_specific) - 出自（共通 or サイクル固有）
- **不変性**: バックログ項目の内容はファイル読み込み時点で確定
- **等価性**: titleを基準に判定

### CompletedItem（対応済み項目）
- **属性**:
  - title: String - 項目の見出し
  - completedCycle: String - 対応したサイクル（例: v1.2.0）
  - completedDate: Date - 対応完了日
- **不変性**: 完了済み項目は変更されない
- **等価性**: titleを基準に判定

### MatchResult（照合結果）
- **属性**:
  - backlogItem: BacklogItem - 照合対象のバックログ項目
  - matchedCompletedItem: CompletedItem - 一致した対応済み項目
  - matchType: Enum(exact, similar) - 一致種別
  - similarity: String - 類似の根拠（AIによる判断理由）
- **不変性**: 照合結果は一度生成されたら変更されない

## ドメインサービス

### BacklogCompletedChecker（バックログ対応済みチェッカー）
- **責務**: バックログ項目と対応済み項目の照合を行い、重複・類似を検出する
- **操作**:
  - checkForDuplicates(backlogItems, completedItems) → MatchResult[] - 照合を実行し、一致・類似項目のリストを返す
  - notifyUser(matchResults) - ユーザーに通知メッセージを生成

## プロセスフロー

```
1. バックログ確認（既存: 3-1, 3-2）
   ↓
2. backlog-completed.md の存在確認
   ↓ 存在する場合
3. AIが両方のファイル内容を比較
   ↓
4. 類似項目を検出（AIによる文脈判断）
   ↓
5. ユーザーに通知
   - 該当項目の一覧表示
   - 確認するかどうかを質問
```

## ユビキタス言語

- **バックログ項目**: 対応待ちのタスクや課題
- **対応済み項目**: 過去のサイクルで完了したタスク
- **照合**: バックログ項目と対応済み項目を比較し、重複や類似を検出すること
- **類似判定**: AIが文脈を読み取り、同一または関連する項目かどうかを判断すること

## 不明点と質問（設計中に記録）

[Question] バックログ項目の照合において、「類似項目」の判定基準は？
[Answer] AIによる判断（文脈を読み取って類似性を判断）
