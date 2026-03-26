# ドメインモデル: Unit 7 複数人開発時コンフリクト対策

## 概要

history.md と backlog.md の複数人開発時コンフリクトを防ぐためのファイル構造設計。

**重要**: このUnit はプロンプト・ルールの更新が主であり、実装コードは書かない。

---

## 1. History ファイル構造

### 現状（Before）

```
docs/cycles/v1.4.0/
  └── history.md        # 1ファイルに全履歴を追記
```

**問題点**:
- 複数人が同時に追記するとコンフリクト発生
- ファイルが肥大化

### 新構造（After）

```
docs/cycles/v1.4.0/history/
  ├── inception.md              # Inception Phase の履歴
  ├── construction_unit1.md     # Unit 1 の履歴
  ├── construction_unit2.md     # Unit 2 の履歴
  ├── construction_unit3.md     # Unit 3 の履歴
  ├── ...
  └── operations.md             # Operations Phase の履歴
```

### History ファイルの命名規則

| フェーズ | ファイル名 |
|---------|-----------|
| Inception | `inception.md` |
| Construction | `construction_unit{N}.md` (N = Unit番号) |
| Operations | `operations.md` |

### History ファイルの内容フォーマット

```markdown
# [フェーズ名] 履歴

## YYYY-MM-DD HH:MM:SS

- **実行内容**: [実行した作業の概要]
- **成果物**: [作成・更新したファイル]
- **備考**: [特記事項]

---

## YYYY-MM-DD HH:MM:SS
...
```

---

## 2. Backlog ファイル構造

### 現状（Before）

```
docs/cycles/
  ├── backlog.md              # 共通バックログ（1ファイル）
  ├── backlog-completed.md    # 完了済み
  └── v1.4.0/
      └── backlog.md          # サイクル固有バックログ（1ファイル）
```

**問題点**:
- 共通/サイクル固有の2重管理
- 複数人が同時に追記するとコンフリクト発生
- サイクル完了時の移行処理が複雑

### 新構造（After）

```
docs/cycles/
  ├── backlog/                    # 共通バックログ（ディレクトリ）
  │   ├── feature-xxx.md          # 新機能
  │   ├── bugfix-yyy.md           # バグ修正
  │   ├── chore-zzz.md            # メンテナンス
  │   └── ...
  ├── backlog-completed/          # 完了済み（ディレクトリ）
  │   ├── feature-aaa.md
  │   └── ...
  └── v1.4.0/
      # backlog.md は廃止
```

### Backlog ファイルの命名規則

`{種類}-{スラッグ}.md`

| 種類 | prefix | 説明 |
|------|--------|------|
| 新機能 | `feature-` | 新しい機能の追加 |
| バグ修正 | `bugfix-` | バグの修正 |
| メンテナンス | `chore-` | 雑務・メンテナンス作業 |
| リファクタリング | `refactor-` | コード改善 |
| ドキュメント | `docs-` | ドキュメント改善 |
| パフォーマンス | `perf-` | パフォーマンス改善 |
| セキュリティ | `security-` | セキュリティ関連 |

### Backlog ファイルの内容フォーマット

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

---

## 3. 既存データの移行方針

### 移行タイミング

**スターターキット更新時（update処理）にAIが1回だけ実行**

### History の移行

- **移行不要**
- 既存の `history.md` はそのまま残す
- 新規サイクルから新形式（`history/`）を使用

### Backlog の移行

- `docs/cycles/backlog.md` のみ移行対象
- サイクル固有バックログはOperations Phaseで共通に移動済み

AIが実行する処理:
1. `docs/cycles/backlog.md` の存在を確認
2. 存在する場合:
   - `docs/cycles/backlog/` ディレクトリを作成
   - 既存内容を `backlog/legacy.md` として移動
   - 元ファイルを削除

---

## 4. 不変条件

1. **1フェーズ/Unit = 1担当者**: 同じhistoryファイルを複数人が同時編集することはない
2. **1気づき = 1ファイル**: 同じbacklogファイルを複数人が同時編集することはない
3. **命名規則の遵守**: prefix と スラッグ の形式を守る

---

## 不明点と質問

[Question] 既存の history.md / backlog.md の移行タイミングは？
[Answer] スターターキット更新時（update処理）にAIが1回だけ実行。Historyは移行不要、Backlogは共通のみ移行。

---

作成日: 2025-12-14
