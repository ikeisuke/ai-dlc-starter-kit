# Unit 006 計画: マイグレーション改善

## 概要

migrate-config.sh を bootstrap.sh 非依存の自己完結スクリプトに改修し、不足セクション追加・エラー表示改善を実装する。

## 関連Issue

- #456: config.toml移行時に内容のマイグレーションも実施する
- #453: migrate-config.shの部分失敗時メッセージとコメント乖離

## アーキテクチャ方針

- **スキル自己完結**: 他スキルの内部実装に依存しない（Anthropic公式スキルのパターンに準拠）
- **bootstrap.sh 脱却**: pwd + SCRIPT_DIR でパス解決を自己完結化
- **配置変更なし**: migrate-config.sh は aidlc-setup に留める

## 変更対象ファイル

1. `skills/aidlc-setup/scripts/migrate-config.sh`:
   - bootstrap.sh の source を削除、pwd + SCRIPT_DIR でパス自己解決
   - v2追加セクション（automation, construction, preflight, squash, unit_branch, upgrade_check）の不足補完
   - サマリ表示改善（`result:{status}:migrated={N},skipped={N},warnings={N}`）
   - `_has_warnings` の適切な処理
   - コメントと実装の終了コード仕様一致
   - `rules.reviewing.tools` 追加失敗時の成功メッセージ抑制

## 実装計画

### Phase 2: 実装

1. bootstrap.sh 依存除去（source 削除、パス解決の自己完結化）
2. 不足セクション追加（6セクション）
3. エラー表示改善（#453）
4. サマリ表示改善（カウント付き）
5. dry-run テスト実行
6. 統合レビュー

### バックログ登録

- 他スクリプトへの bootstrap.sh 依存脱却の適用（aidlc-setup, aidlc-migrate 全体）
- migrate-apply-config.sh の migrate-config.sh 参照問題

## 完了条件チェックリスト

- [ ] migrate-config.sh が bootstrap.sh に依存せず自己完結で動作する
- [ ] v2追加セクションの不足補完が実装されている
- [ ] マイグレーション結果のサマリ表示（成功件数・警告件数）
- [ ] 部分失敗時のエラー表示改善（項目名、原因、次アクション）
- [ ] _has_warnings変数が適切に処理されている
- [ ] コメントと実装の終了コード仕様が一致している
- [ ] dry-run モードで正常動作する
- [ ] bootstrap.sh脱却のバックログIssueが登録されている
