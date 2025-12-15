# 論理設計: Unit 7 複数人開発時コンフリクト対策

## 概要

history.md と backlog.md のファイル分割方式に伴うプロンプト・テンプレートの更新設計。

**重要**: このUnit はプロンプト・ルールの更新が主であり、実装コードは書かない。

---

## 更新対象ファイル一覧

### プロンプトファイル（通常版）

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/construction.md` | history分割方式への対応 |
| `prompts/package/prompts/inception.md` | backlog分割方式への対応 |
| `prompts/package/prompts/operations.md` | history/backlog分割方式への対応 |

### プロンプトファイル（lite版）

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/lite/construction.md` | history分割方式への対応 |
| `prompts/package/prompts/lite/inception.md` | backlog分割方式への対応 |
| `prompts/package/prompts/lite/operations.md` | history/backlog分割方式への対応 |

### セットアップ関連

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-cycle.md` | history/, backlog/ディレクトリ作成 |

### テンプレート

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/templates/cycle_backlog_template.md` | 廃止（削除）|
| `prompts/package/templates/backlog_item_template.md` | 新規作成 |
| `prompts/package/templates/history_entry_template.md` | 新規作成 |

---

## 変更詳細

### 1. setup-cycle.md

**Before**:
```markdown
## 5. history.md の初期化
`docs/cycles/[バージョン]/history.md` を作成:

## 6. backlog.md の初期化
`docs/cycles/[バージョン]/backlog.md` を作成
```

**After**:
```markdown
## 5. history/ ディレクトリの初期化
`docs/cycles/[バージョン]/history/` を作成:
- inception.md を作成（Inception Phase用）

## 6. backlog/ ディレクトリの確認
`docs/cycles/backlog/` が存在しなければ作成
（サイクル固有backlogは廃止）
```

### 2. construction.md

**Before**:
```markdown
履歴記録
`docs/cycles/{{CYCLE}}/history.md` に履歴を追記（heredoc使用）
```

**After**:
```markdown
履歴記録
`docs/cycles/{{CYCLE}}/history/construction_unit{N}.md` に履歴を記録
（Unit開始時にファイル作成、追記形式）
```

### 3. inception.md

**Before**:
```markdown
気づき記録
`docs/cycles/{{CYCLE}}/backlog.md` に追記
```

**After**:
```markdown
気づき記録
`docs/cycles/backlog/{種類}-{スラッグ}.md` に新規ファイル作成
（テンプレート: backlog_item_template.md）
```

### 4. operations.md

**Before**:
```markdown
履歴記録
`docs/cycles/{{CYCLE}}/history.md` に履歴を追記

バックログ処理
サイクル固有backlogの項目を共通backlogに移行
```

**After**:
```markdown
履歴記録
`docs/cycles/{{CYCLE}}/history/operations.md` に履歴を記録

バックログ処理
完了した項目は `docs/cycles/backlog-completed/` に移動
（サイクル固有backlogは廃止済み）
```

---

## 新規テンプレート

### backlog_item_template.md

```markdown
# [タイトル]

- **発見日**: YYYY-MM-DD
- **発見フェーズ**: [Inception / Construction / Operations]
- **発見サイクル**: vX.X.X
- **優先度**: [高 / 中 / 低]

## 概要

[簡潔な説明]

## 詳細

[詳細な説明]

## 対応案

[推奨される対応方法]
```

### history_entry_template.md

```markdown
# [フェーズ名] 履歴

## YYYY-MM-DD HH:MM:SS

- **実行内容**: [実行した作業の概要]
- **成果物**: [作成・更新したファイル]
- **備考**: [特記事項]

---
```

---

## 処理フロー

### サイクル開始時（setup-cycle.md）

1. `docs/cycles/[バージョン]/history/` ディレクトリを作成
2. `docs/cycles/[バージョン]/history/inception.md` を作成
3. `docs/cycles/backlog/` が存在しなければ作成

### Unit作業時（construction.md）

1. Unit開始時に `history/construction_unit{N}.md` を作成
2. 作業記録を追記
3. 気づきは `docs/cycles/backlog/{種類}-{スラッグ}.md` に新規ファイル作成

### サイクル完了時（operations.md）

1. `history/operations.md` に履歴を記録
2. 完了した backlog 項目は `backlog-completed/` に移動

---

## 非機能要件への対応

- **パフォーマンス**: 該当なし（ファイル操作のみ）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: ファイル分割により並行作業が可能に
- **可用性**: 該当なし

---

## 不明点と質問

（現時点で不明点なし）

---

作成日: 2025-12-14
