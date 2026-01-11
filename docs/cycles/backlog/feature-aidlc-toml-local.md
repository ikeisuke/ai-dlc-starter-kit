# aidlc.toml.local による個人設定サポート

- **発見日**: 2026-01-11
- **発見フェーズ**: Operations
- **発見サイクル**: v1.7.0
- **優先度**: 中

## 概要

`aidlc.toml.local` のような個人設定ファイルをサポートし、チーム共有設定と個人設定を分離できるようにする。

## 詳細

### 現状の問題
- `docs/aidlc.toml` はgit管理対象でチーム共有
- jjサポート、バックログモードなど個人の好みに依存する設定がある
- 個人設定を入れるとコンフリクトの原因になる

### 提案する仕組み

**設定ファイルの優先順位**:
1. `docs/aidlc.toml.local` - 個人設定（gitignore推奨）
2. `docs/aidlc.toml` - チーム共有設定

**マージ方式**:
- 同一キーは `.local` が優先
- 深いマージ（セクション単位で上書き）

### 想定される個人設定項目
- `[rules.jj].enabled` - jj使用の有無
- `[backlog].mode` - バックログ管理モード（git/issue）
- `[rules.mcp_review].mode` - AIレビューモード
- 今後追加される個人の好みに依存する設定

## 対応案

1. プロンプト側で `.local` ファイルの読み込みロジックを追加
2. セットアップ時に `.local` ファイルのテンプレート作成を提案
3. `.gitignore` に `docs/aidlc.toml.local` を追加

## 関連

- deferred-home-directory-user-settings.md（ホームディレクトリのユーザー共通設定）

## 推奨対応サイクル

v1.8.0
