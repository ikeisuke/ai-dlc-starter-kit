# 論理設計: operations.md分割リファクタリング

## 概要

operations.mdからステップ6を分離し、operations-release.mdとして新規作成するファイル構成とナビゲーション方式を設計する。

## アーキテクチャパターン

リダイレクト分割パターン: メインファイルにナビゲーション概要と参照リンクを残し、詳細を別ファイルに委譲する。既存のconstruction.mdの`【次のアクション】`パターンに準拠。

## コンポーネント構成

```text
prompts/package/prompts/
├── operations.md          (メイン: ステップ0-5 + ステップ6リダイレクト + 完了・サイクル完了)
└── operations-release.md  (新規: ステップ6詳細)
```

### operations.md（編集後）

- **責務**: Operations Phase全体制御、ステップ0-5詳細、ステップ6のナビゲーション概要
- **依存**: operations-release.mdへの`【次のアクション】`参照
- **推定行数**: 約660行（1,097行 - 438行 ≒ 659行）

### operations-release.md（新規）

- **責務**: ステップ6（リリース準備）の全サブステップ（6.0〜6.7）の詳細手順
- **暗黙的前提**: ステップ0〜5完了済み、共通ルール・aidlc.toml読み込み済み、環境情報（gh/backlog_mode）確認済み
- **推定行数**: 約450行（ステップ6本体 + ヘッダ + 逆参照）

## リダイレクト見出し契約（固定フォーマット）

operations.mdに残すリダイレクト見出しの必須要素:

1. **見出し**: `### ステップ6: リリース準備`（既存見出しと同一）
2. **タスク管理指示**: `**タスク管理機能を活用してください。**`
3. **progress.md更新指示**: `- **ステップ開始時**: progress.mdでステップ6を「進行中」に更新`
4. **サブステップ一覧**: 6.0〜6.7の名称リスト（詳細なし、ナビゲーション用）
5. **【次のアクション】リンク**: `docs/aidlc/prompts/operations-release.md` への参照
6. **ステップ完了更新**: `- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録`

## ナビゲーション設計

### operations.md → operations-release.md（順方向）

```markdown
### ステップ6: リリース準備

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ6を「進行中」に更新

**サブステップ一覧**（順番に実行）:
1. 6.0 バージョン確認
2. 6.1 CHANGELOG更新（`changelog = true` の場合）
3. 6.2 README更新
4. 6.3 履歴記録
5. 6.4 Markdownlint実行
6. 6.4.5 progress.md更新 ← **PR準備完了**
7. 6.5 Gitコミット
8. 6.6 ドラフトPR Ready化
9. 6.6.5 コミット漏れ確認
10. 6.6.6 リモート同期確認
11. 6.7 PRマージ

**【次のアクション】** 今すぐ `docs/aidlc/prompts/operations-release.md` を読み込んで、各サブステップの詳細手順に従ってください。

- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録
```

### operations-release.md → operations.md（逆参照 + 前提条件）

ファイル冒頭に以下を配置:

```markdown
# Operations Phase - ステップ6: リリース準備

> このファイルは `operations.md` のステップ6の詳細です。全体フローは `docs/aidlc/prompts/operations.md` を参照してください。

**前提条件**: このステップを開始する前に、以下が完了していること:
- ステップ0〜5が完了済み（progress.mdで確認）
- 共通ルール（`docs/aidlc/prompts/common/rules.md`）読み込み済み
- `docs/aidlc.toml` の設定確認済み
- 環境情報（gh/backlog_mode）確認済み（ステップ2.5）
```

## 参照整合性検証手順

実装完了後に以下の検証を実施する:

1. **ファイル存在確認**: `prompts/package/prompts/operations-release.md` が存在すること
2. **リンク先見出し確認**: operations-release.mdに`# Operations Phase - ステップ6: リリース準備`見出しが存在すること
3. **旧コンテンツ残存チェック**: operations.md内に`#### 6.0`〜`#### 6.7`の見出しが存在しないこと（リダイレクト見出し内のサブステップ一覧は番号付きリストのため見出しではない）
4. **参照パス確認**: operations.md内の`operations-release.md`への参照パスが`docs/aidlc/prompts/operations-release.md`であること
5. **行数確認**: operations.mdが1,000行以下であること
6. **rsync後の検証**（Operations Phaseで実施）: `/upgrading-aidlc`実行後に`docs/aidlc/prompts/operations.md`および`docs/aidlc/prompts/operations-release.md`のリンク解決・見出し到達を再確認する

## 処理フロー概要

### 分割実行フロー

1. operations-release.md を新規作成（ヘッダ + 前提条件 + ステップ6本体を移植）
2. operations.md から`### ステップ6: リリース準備`の詳細（サブステップ本体）を削除
3. 削除箇所にリダイレクト見出し契約に準拠したコンテンツを挿入
4. 参照整合性検証手順を実行

## 実装上の注意事項

- 正本は `prompts/package/prompts/` を編集する（`docs/aidlc/` は直接編集禁止）
- 参照パスは実行時パス（`docs/aidlc/prompts/`）を使用する（メタ開発の標準パターン）
- ステップ6内の相対的な内部参照（サブステップ間のリンク等）がある場合は維持する
