# Unit: Issue操作スクリプト

## 概要
Issueへのラベル付けとCloseを行うスクリプトを作成する。

## 含まれるユーザーストーリー
- ストーリー 1-5: Issue操作

## 関連Issue
- #34

## 責務
- サブコマンド（label, close）で操作を選択
- Issue番号とラベル名を引数で受け取る
- プロンプト内のIssue操作をスクリプト呼び出しに置換

## 境界
- Issue作成は含まない（gh issue createは複雑なため）

## 依存関係

### 依存する Unit
- Unit 001（環境情報でgh確認）

### 外部依存
- gh（GitHub CLI）

## 非機能要件（NFR）
- **パフォーマンス**: 5秒以内
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: gh認証済み環境で動作

## 技術的考慮事項

### 使用方法
```bash
# ラベル付け
bin/issue-ops.sh label 123 "cycle:v1.8.0"

# Close
bin/issue-ops.sh close 123

# Close（not planned）
bin/issue-ops.sh close 123 --not-planned
```

### 出力例

```text
issue:123:labeled:cycle:v1.8.0
issue:123:closed
issue:123:closed:not-planned
issue:123:error:not found
```

### 変更対象ファイル
- `prompts/package/bin/issue-ops.sh`（新規）
- `prompts/package/prompts/inception.md`（呼び出し追加）
- `prompts/package/prompts/operations.md`（呼び出し追加）

## 実装優先度
Medium

## 見積もり
30分

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
