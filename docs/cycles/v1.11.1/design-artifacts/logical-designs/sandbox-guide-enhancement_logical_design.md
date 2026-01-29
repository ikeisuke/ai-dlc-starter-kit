# 論理設計: サンドボックス環境ガイド補完

## 概要

`prompts/package/guides/sandbox-environment.md`に追加するセクション構成と内容の設計。

## 追加セクション一覧

| セクション番号 | タイトル | 挿入位置 |
|---------------|---------|---------|
| 1.5 | 認証方式の違い | セクション1の後 |
| 1.7 | サンドボックスの種類 | セクション1.5の後 |
| 3.5 | Claude Code - OAuth認証でのDocker利用 | セクション3の後 |
| 4.5 | Codex CLI - OAuth認証でのDocker利用 | セクション4の後 |
| 5.5 | KiroCLI - Docker環境での利用 | セクション5の後 |

## 各セクションの詳細設計

### セクション1.5: 認証方式の違い

**目的**: API Key認証とOAuth認証の違いを明確化

**内容構成**:

1. 認証方式比較表
   - API Key: 特徴、メリット、デメリット
   - OAuth: 特徴、メリット、デメリット

2. 各ツールの認証方式一覧表
   - Claude Code
   - Codex CLI
   - KiroCLI

3. Docker利用時の認証方式選択ガイド

### セクション1.7: サンドボックスの種類

**目的**: アプリケーションレベルとOSレベルの違いを説明

**内容構成**:

1. サンドボックスレベル比較表
   - アプリケーションレベル
   - OSレベル（Docker/コンテナ）

2. 各レベルの保護範囲
   - ファイルシステム
   - ネットワーク
   - プロセス
   - 環境変数

3. 推奨組み合わせパターン（具体例付き）
   - 読み取り専用作業: `docker run --read-only -v $(pwd):/workspace:ro ...`
   - 通常開発作業: `-v $(pwd):/workspace:rw` + アプリレベルサンドボックス
   - 高セキュリティ要件: `--read-only --network none -v ...` + tmpfs併用

### セクション3.5: Claude Code - OAuth認証でのDocker利用

**目的**: claude.ai Pro/TeamプランでのDocker環境構築手順を提供

**内容構成**:

1. 前提条件
   - claude.ai Pro/Teamプラン契約
   - ホストマシンでClaude Code認証済み

2. 認証情報の準備
   ```bash
   # ホストで認証（初回のみ）
   claude auth login
   ```

3. Docker実行例
   ```bash
   docker run -it --rm \
     -v ~/.claude:/home/user/.claude:ro \
     -v $(pwd):/workspace \
     ...
   ```

4. docker-compose例

5. トラブルシューティング
   - 認証エラー時の対処
   - トークン更新方法

### セクション4.5: Codex CLI - OAuth認証でのDocker利用

**目的**: ChatGPT Plus等でのDocker環境構築手順を提供

**内容構成**:

1. 前提条件
   - ChatGPT Plus等のサブスクリプション
   - ホストマシンでCodex認証済み

2. 認証情報の準備
   ```bash
   # ホストで認証（初回のみ）
   codex auth login
   ```

3. Docker実行例
   ```bash
   docker run -it --rm \
     -v ~/.codex:/home/user/.codex:ro \
     -v $(pwd):/workspace \
     ...
   ```

4. docker-compose例

5. トラブルシューティング

### セクション5.5: KiroCLI - Docker環境での利用

**目的**: Amazon Q DeveloperでのDocker環境構築手順を提供

**内容構成**:

1. 前提条件
   - Amazon Q Developer契約
   - ホストマシンでKiroCLI認証済み

2. 認証情報の準備
   ```bash
   # ホストで認証（初回のみ）
   kiro auth login
   ```

3. Docker実行例
   ```bash
   docker run -it --rm \
     -v ~/.kiro:/home/user/.kiro:ro \
     -v $(pwd):/workspace \
     ...
   ```

4. docker-compose例

5. トラブルシューティング

## 実装上の注意点

1. **認証ディレクトリのマウント**:
   - 通常運用: 読み取り専用（`:ro`）でマウントしてセキュリティ確保
   - トークン更新時: 書き込み可能（`:rw`）でマウントが必要な場合あり
   - 運用パターン: 「初回/更新時は`:rw`、普段は`:ro`」を推奨
2. **ユーザーID**:
   - 推奨: コンテナ内のユーザーIDとホストのユーザーIDを一致させる（`--user $(id -u):$(id -g)`）
   - 代替策: `--group-add`やvolume権限調整でも対応可能
3. **既存セクションとの整合性**: 既存のDocker実行例と矛盾しないよう注意
4. **セキュリティ警告**: 認証情報のマウントに関するリスクを明記
5. **セクション番号**: 挿入位置は見出し名基準とし、番号は既存文書に合わせて調整
