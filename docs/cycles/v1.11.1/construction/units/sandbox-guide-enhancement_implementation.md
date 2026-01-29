# 実装記録: サンドボックス環境ガイド補完

## 概要

sandbox-environment.mdに認証方式・サンドボックス種類の説明と、各ツールのOAuth認証でのDocker利用手順を追加した。

## 実装内容

### 追加したセクション

| セクション | 内容 |
|-----------|------|
| 1.5 認証方式の違い | API Key vs OAuthの比較、各ツールの認証方式（参考例） |
| 1.7 サンドボックスの種類 | アプリケーションレベル vs OSレベルの比較、推奨組み合わせパターン |
| 3.5 Claude Code - OAuth認証でのDocker利用 | サブスク契約でのDocker環境構築手順 |
| 4.5 Codex CLI - OAuth認証でのDocker利用 | サブスク契約でのDocker環境構築手順 |
| 5.5 KiroCLI - Docker環境での利用 | Docker環境構築手順 |

### 変更したファイル

- `prompts/package/guides/sandbox-environment.md`

### 技術的な工夫

1. **HOME環境変数の明示**: `--user $(id -u):$(id -g)` 使用時に `-e HOME=/home/node` を設定
2. **tmpfs設定**: `--read-only` 使用時に `/tmp`、`/home/node/.npm`、`/home/node/.cache` をtmpfsでマウント
3. **断定表現の回避**: OAuth対応プラン・認証コマンド・保存先は「参考例」「要確認」として記載
4. **サプライチェーン対策**: 全ツールでnpxのバージョン固定/事前インストールを推奨

## テスト結果

- Markdownlint: パス

## AIレビュー

- 設計レビュー: Codex CLIによるレビュー実施、指摘反映済み
- 実装レビュー: Codex CLIによるレビュー実施、指摘反映済み

## 完了状態

完了
