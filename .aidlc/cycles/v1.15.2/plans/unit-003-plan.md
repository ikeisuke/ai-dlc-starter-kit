# Unit 003 計画: エラー処理改善

## 概要

`issue-ops.sh`、`cycle-label.sh`、`setup-branch.sh` の3つのシェルスクリプトについて、エラー処理の強化、コメントの改善、パス変換処理の改善を行う。

関連Issue: #194（項番 #13, #14, #15）

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/bin/issue-ops.sh` | `parse_gh_error` 関数に認証エラーパターンを追加、ヘルプ文のエラー一覧も更新 |
| `prompts/package/bin/cycle-label.sh` | `create_label` 関数のリダイレクト設定コメントを改善 |
| `prompts/package/bin/setup-branch.sh` | `worktree_exists` 関数の相対パス→絶対パス変換を `realpath` 利用に改善 |

## 実装計画

### 1. `issue-ops.sh` - `parse_gh_error` 関数の改善

**現状** (L151-159):
- `not found` / `could not find` / `could not resolve` のみ検出
- 認証エラー（401, 403等）が `unknown` として返される

**変更内容**:
- 認証エラーパターンを追加: `authentication`, `401`, `403`, `token`, `credential` 等を検出
- 認証エラー時は `auth-error` を返す（受け入れ基準に準拠。`parse_gh_error` の既存戻り値 `not-found` と同様プレフィックスなし。`gh-not-authenticated` は `check_gh_available` のプレチェック用で別関数）
- 既存の `not-found` パターンはそのまま維持
- ヘルプメッセージ（`show_help` 関数）のエラー一覧に `auth-error` を追加

### 2. `cycle-label.sh` - リダイレクト設定コメントの改善

**現状** (L101-103):
- コメント: `# リダイレクト順序: まずstdoutを/dev/nullに、次にstderrをstdout(キャプチャ対象)に`
- 実際のリダイレクト `2>&1 1>/dev/null` の処理順序と記述順序の関係が不明確

**変更内容**:
- コメントを改善: 「stderrをstdoutへリダイレクトし、stdoutは/dev/nullに破棄。結果としてstderrの内容のみ変数に格納される」という趣旨の説明に変更

### 3. `setup-branch.sh` - `realpath` 利用によるパス変換改善

**現状** (L52-53):
- `cd + dirname + pwd + basename` で相対パスを絶対パスに変換
- コードが複雑で可読性が低い

**変更内容**:
- `realpath` コマンドが利用可能かつ実行成功する場合はそれを使用
- `realpath` が利用不可の場合（macOS等）または実行失敗する場合（未存在パス等）は既存の `cd + pwd` 方式にフォールバック
- 変換ロジックの可読性を向上

**注意**: `worktree_exists` は未作成パスにも呼ばれるため、`realpath` が未存在パスで失敗するケースへの対応が必須。

## 依存境界に関する注意

- 変更対象は `prompts/package/bin/` 配下（ソース側）
- `docs/aidlc/bin/` 配下（配布側）への同期は Operations Phase で `/upgrading-aidlc` 実行時に rsync で反映される
- Construction Phase では `prompts/package/bin/` のみを編集する

## 完了条件チェックリスト

- [ ] `issue-ops.sh` の `parse_gh_error` 関数に認証エラーパターンを追加
- [ ] `issue-ops.sh` のヘルプ文のエラー一覧に `auth-error` を追加
- [ ] `cycle-label.sh` のリダイレクト設定の補足コメント改善
- [ ] `setup-branch.sh` の相対パス→絶対パス変換を `realpath` 利用に改善（フォールバック付き）
- [ ] `setup-branch.sh` で未存在パスが渡された場合もフォールバックで正しく動作すること
- [ ] 成功系パスの既存動作に影響がないこと
