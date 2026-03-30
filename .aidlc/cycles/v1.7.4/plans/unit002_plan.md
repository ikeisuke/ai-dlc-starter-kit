# Unit 002: ツールインストール案内 - 実装計画

## 概要

初回セットアップ時に必要なツール（gh, dasel等）のインストール方法を案内するセクションを `prompts/setup-prompt.md` に追加する。

## 対象ファイル

- `prompts/setup-prompt.md` - ツールインストール案内セクションを追加

## 実装内容

### 追加するセクション

「セクション1. 実行環境の確認」の前に「0. 必要ツールの準備」セクションを新設。

### 記載内容

| ツール | 必須/オプション | 用途 |
|--------|----------------|------|
| gh (GitHub CLI) | 必須 | GitHub Issue/PR操作、バックログ管理（issue-only モード時） |
| dasel | オプション | TOML設定ファイルの解析（なくてもAIが代替可能） |
| jq | オプション | JSON解析（なくてもAIが代替可能） |
| curl | オプション | Webリソース取得（なくてもAIが代替可能） |

### インストールコマンド

```bash
# macOS (Homebrew)
brew install gh
brew install dasel  # オプション
brew install jq     # オプション

# Ubuntu/Debian (APT)
sudo apt install gh
# dasel: https://github.com/TomWright/dasel/releases からダウンロード
sudo apt install jq  # オプション
```

### 配置位置

- 現在の「## 1. 実行環境の確認」の前に配置
- 新しいセクション番号: `## 0. 必要ツールの準備`

## Phase 1: 設計

- ドメインモデル/論理設計: ドキュメント追加のみのため、設計ドキュメントは最小限
- 記載内容の構造と順序を確定

## Phase 2: 実装

1. `prompts/setup-prompt.md` にセクション追加
2. Markdownlint実行
3. 動作確認（読みやすさ・構造の確認）

## 完了基準

- [ ] ツールインストール案内セクションが追加されている
- [ ] 必須/オプションの区別が明確である
- [ ] 主要パッケージマネージャー（brew, apt）のコマンドが記載されている
- [ ] Markdownlintエラーなし
