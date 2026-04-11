# Unit 003 実装計画: 部分対応Issue自動判別

## 対象Unit

- Unit 003: 部分対応Issue自動判別
- 関連Issue: #546

## 目的

PR Closes記載時に部分対応Issueを自動判別し、Closes/Relatesを区別する。Unit定義ファイルの「関連Issue」セクションに部分対応記法を導入し、`get-related-issues` の出力とPR Closes確認ステップを改善する。

## 変更対象ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `skills/aidlc/scripts/pr-ops.sh` | 修正 | `get-related-issues` にCloses/Relates区別出力を追加 |
| `skills/aidlc/steps/operations/operations-release.md` | 修正 | 7.8 PR本文生成でCloses/Relates区別対応 |
| `skills/aidlc/templates/unit_definition_template.md` | 修正 | 「関連Issue」セクションに部分対応記法の説明追加 |
| `skills/aidlc/templates/pr_body_template.md` | 修正 | Closes/Relatesセクション対応 |

## 変更方針

### 1. 部分対応記法

Unit定義ファイルの「関連Issue」セクション:
- `- #NNN` → 完全対応（Closes）
- `- #NNN（部分対応）` → 部分対応（Relates）
- 注記なしはデフォルトで完全対応（後方互換）

### 2. `pr-ops.sh get-related-issues` 出力変更

現行: `issues:#123,#456`（区別なし）
変更後: `closes:#123,#456` + `relates:#789`（2行出力）

後方互換: `relates:none` の場合は従来と同じ意味。

### 3. PR本文テンプレート

```markdown
## Closes
Closes #123
Closes #456

## Related Issues
Relates to #789（部分対応）
```

### 変更しないもの

- 既存Unitの自動修正
- 過去サイクル成果物への注記追加
- PR本文の自動編集機能（検証と提案のみ）

## 完了条件チェックリスト

- [ ] Unit定義テンプレートに部分対応記法の説明がある
- [ ] `get-related-issues` が `#NNN` と `#NNN（部分対応）` を区別する
- [ ] 出力が `closes:...` + `relates:...` の2行形式
- [ ] `relates:none` の場合にRelatesセクションが省略される
- [ ] 注記なし `#NNN` は「完全対応」扱い（後方互換）
- [ ] PR本文テンプレートにRelatesセクションがある
- [ ] operations-release.md 7.8 でCloses/Relates区別対応
- [ ] `operations-release.sh pr-ready` の `get-related-issues` 呼び出しが新出力に対応
