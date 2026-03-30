# Unit 002 計画: issue-ops.sh 認証判定バグ修正

## 概要

`issue-ops.sh` の `check_gh_available()` 関数が、認証済み環境でも `gh-not-authenticated` エラーを返すバグを修正する。`gh auth status` を `gh auth status --hostname <host>` に変更し、特定ホストの認証状態を正確に判定する。ホストは環境変数 `GH_HOST`（未設定時は `github.com`）で解決する。

## 変更対象ファイル

- `prompts/package/bin/issue-ops.sh` - `check_gh_available()` 関数の修正

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 認証判定ロジックの構造と責務を定義
2. **論理設計**: `--hostname` オプション対応とフォールバック設計
3. **設計レビュー**

### Phase 2: 実装

4. **コード修正**:
   - `check_gh_available()` 関数を修正
   - ホスト解決: `GH_HOST` 環境変数（未設定時は `github.com`）を使用
   - `gh auth status --hostname <host>` を使用して対象ホストの認証のみ確認
   - フォールバック: `--hostname` が未対応（stderr に "unknown flag" 等を含む場合）のみ従来の `gh auth status` にフォールバック。認証失敗等の他エラーはフォールバックせず `gh-not-authenticated` を返す
5. **テスト**: 認証済み環境での正常動作確認、動作検証
6. **統合とレビュー**: ビルド確認、AIレビュー実施

## 完了条件チェックリスト

- [ ] check_gh_available() 関数の認証判定ロジック修正
- [ ] 認証済み環境での正常動作確認
- [ ] gh未インストール/未認証環境での従来動作維持確認

## 気づき

- `check-gh-status.sh` にも同じ `gh auth status` パターンが存在するが、Unit 002 のスコープ外（別途バックログ検討）
- 認証チェック+エラー出力変換が各サブコマンドに重複している構造的課題があるが、Unit 002 のスコープ（認証チェック部分のみ）外のため、リファクタは別途検討
