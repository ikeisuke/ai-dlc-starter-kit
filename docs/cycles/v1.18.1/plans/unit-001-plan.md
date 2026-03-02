# Unit 001 計画: operations.md分割リファクタリング

## 概要

operations.mdの行数超過（1,097行 > 閾値1,000行）を解消するため、ステップ6（リリース準備、466-903行目、約438行）を`operations-release.md`として分離する。

## 変更対象ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `prompts/package/prompts/operations.md` | 編集 | ステップ6を削除し、operations-release.mdへの参照を追加 |
| `prompts/package/prompts/operations-release.md` | 新規作成 | ステップ6の内容を移植 |

## パス参照の規約

正本は`prompts/package/`配下だが、実行時にAIが読み込むのは`docs/aidlc/`（rsyncコピー）配下。そのため、プロンプト内の`【次のアクション】`参照パスは`docs/aidlc/prompts/`形式を使用する（既存パターン準拠）。

## 実装計画

### Phase 1: 設計

1. **分割境界確定**: ステップ6の抽出範囲と残留するセクションの確定
2. **リンク仕様確定**: operations.mdに残すリダイレクト見出しと参照パスの設計

### Phase 2: 実装

1. `operations-release.md`を新規作成（ステップ6の全内容を移植）
2. `operations.md`からステップ6（466-903行目）を削除
3. `operations.md`のステップ6があった箇所にリダイレクト見出しと参照リンクを追加
4. 参照パスの整合性を確認（grepによるリンク検証）

### 分割境界

- **operations.md に残す内容**: ステップ0〜5、実行ルール、完了基準、完了時の確認、バックトラック、AI-DLCサイクル完了セクション
- **operations-release.md に移す内容**: ステップ6（リリース準備）の全サブステップ（6.0〜6.7）

### 互換性契約

- ステップ6の見出し（`### ステップ6: リリース準備`）はoperations.mdに残し、リダイレクトとして機能させる
- ステップ6のサブステップ一覧（6.0〜6.7）をoperations.mdにナビゲーション用概要として維持する（正本はoperations-release.md。operations.md側はサブステップ名のみの一覧で、詳細手順は含まない）
- operations-release.md側にも元ファイルへの逆参照（ナビゲーション）を配置する
- CLI引数・戻り値・終了コードへの影響なし（プロンプト内容の移動のみ）

### 参照方式

operations.mdのステップ6があった箇所に以下を追加:

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
```

## 完了条件チェックリスト

- [ ] operations.mdからステップ6を`operations-release.md`として抽出
- [ ] 分割後のファイル間参照の整備（リダイレクト見出し + サブステップ一覧 + 逆参照）
- [ ] 参照パスの整合性確認（grep検証: 旧パスが残っていないこと）
- [ ] operations.mdの行数が閾値1,000行以下
