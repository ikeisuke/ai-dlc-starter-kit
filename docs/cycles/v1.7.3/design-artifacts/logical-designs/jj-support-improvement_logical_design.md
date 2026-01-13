# Unit 004: jjサポートの改善 - 論理設計

## 概要

jjサポートガイドに追加するセクションの詳細設計。

## 追加セクション詳細

### 1. 重要警告セクション

**配置**: 概要の直後

```text
## ⚠️ 重要: bookmarkは自動で進まない

**Git との最大の違い**:
- Git: ブランチは自動的にHEADに追従する
- jj: bookmarkは手動で移動する必要がある

**AI-DLCでの影響**:
Unit完了時に `jj bookmark set` を忘れると、cycle bookmarkが古いままになり、
次のUnit開始時やPR作成時に問題が発生します。

**必須対策**:
Unit完了時に **必ず** `jj bookmark set` を実行してください:
```bash
jj bookmark set cycle/vX.X.X -r @-
```

**補助設定**:
auto-local-bookmark を有効にすると、リモート同期時の混乱を減らせます（下記参照）。
ただし、これはbookmark自動追従ではないため、上記コマンドは引き続き必要です。
```

### 2. 推奨設定セクション

**配置**: 重要警告の直後

```text
## 推奨設定

jjをAI-DLCで使用する際の推奨設定です。

### auto-local-bookmark の有効化

`.jj/config.toml`（リポジトリローカル）または `~/.config/jj/config.toml`（グローバル）に追加:

```toml
[git]
auto-local-bookmark = true
```

**効果**:
- `jj git fetch` 時にリモートブランチに対応するローカルbookmarkを自動作成
- リモートとの同期が容易になる

**注意**: この設定はbookmarkの自動追従ではなく、自動作成のみです。
Unit完了時の `jj bookmark set` は引き続き必要です。
```

### 3. 作業開始時チェックリスト

**配置**: AI-DLCワークフローセクション内、各フェーズ説明の前

```text
### 作業開始時チェックリスト

Unit/フェーズを開始する前に確認してください。

- [ ] 現在のリビジョン（@）の位置を確認
  ```bash
  jj log -r @
  ```
- [ ] cycle bookmarkの位置を確認
  ```bash
  jj log -r 'cycle/vX.X.X'
  ```
- [ ] cycle bookmarkから新しいchangeを作成
  ```bash
  jj new cycle/vX.X.X
  ```
```

### 4. 作業終了時チェックリスト

**配置**: AI-DLCワークフローセクション内、各フェーズ説明の後

```text
### 作業終了時チェックリスト

Unit/フェーズを完了する際に**必ず**実行してください。

- [ ] コミットメッセージを設定
  ```bash
  jj describe -m "feat: [vX.X.X] Unit NNN完了 - 概要"
  ```
- [ ] 新しいリビジョンを作成（現在の変更を確定）
  ```bash
  jj new
  ```
- [ ] **cycle bookmarkを進める（重要）**
  ```bash
  jj bookmark set cycle/vX.X.X -r @-
  ```
- [ ] リモートにプッシュ
  ```bash
  jj git push --bookmark cycle/vX.X.X
  ```

**ワンライナー版**（上記をまとめて実行）:
```bash
jj describe -m "feat: [vX.X.X] Unit NNN完了" && jj new && jj bookmark set cycle/vX.X.X -r @- && jj git push --bookmark cycle/vX.X.X
```
```

## 既存セクションの調整

### AI-DLCワークフローセクション

各フェーズの説明は維持し、作業開始・終了チェックリストを追加する形で拡張。

### 注意事項セクション

以下を追記:
- 「bookmarkの手動移動が必要」であることの再強調
- 作業終了時チェックリストへの参照

## 完了条件チェック

| 条件 | 対応セクション |
|------|---------------|
| 「bookmarkは自動で進まない」警告 | 重要警告セクション（コマンド例あり） |
| 「作業開始時」セクション | 作業開始時チェックリスト |
| 「作業終了時」セクション | 作業終了時チェックリスト |
| jjコマンド例（作業開始・終了チェックリストに1つ以上） | チェックリストに複数のコマンド例あり |
| 推奨設定（auto-local-bookmark） | 推奨設定セクション |
| Unit境界でのbookmark操作ガイド | 作業終了時チェックリスト |
