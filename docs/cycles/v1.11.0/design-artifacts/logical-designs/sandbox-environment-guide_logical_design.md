# 論理設計: サンドボックス環境ガイド

## 概要

各AIエージェントのサンドボックス設定の詳細と実装方針を定義する。

## コンポーネント設計

### 1. 概要セクション

**目的**: サンドボックスの概念と重要性を説明

**内容**:

- サンドボックスとは: 隔離された実行環境で、システムへの影響を制限する仕組み
- 目的:
  - 意図しないファイルの変更・削除を防止
  - 危険なコマンドの実行を制限
  - 機密情報へのアクセスを制御
- 利点:
  - 安全な実験環境の提供
  - 本番環境への誤操作リスク軽減
  - AIエージェントの動作検証が安全に行える

### 2. Claude Code セクション

**サンドボックス機能**:

- Claude Codeはデフォルトでパーミッションシステムを持つ
- ファイル操作やコマンド実行時にユーザー確認を求める
- `--dangerously-skip-permissions` フラグで確認をスキップ可能（非推奨）

**Docker環境での実行**:

```bash
# 基本的なDocker実行
docker run -it --rm \
  -v $(pwd):/workspace \
  -w /workspace \
  node:20-slim \
  npx @anthropic-ai/claude-code

# 読み取り専用マウント
docker run -it --rm \
  -v $(pwd):/workspace:ro \
  -w /workspace \
  node:20-slim \
  npx @anthropic-ai/claude-code
```

**注意事項**:

- `--dangerously-skip-permissions` は本番環境での使用を避ける
- Docker使用時は適切なボリュームマウント設定を行う

### 3. Codex CLI セクション

**サンドボックス設定オプション**:

| オプション | 説明 | ユースケース |
|-----------|------|-------------|
| `read-only` | 読み取りのみ許可 | コードレビュー、調査 |
| `workspace-write` | ワークスペース内の書き込み許可 | 通常の開発作業 |
| `danger-full-access` | 全アクセス許可 | 特殊な要件がある場合のみ |

**設定方法**:

```bash
# コマンドラインオプション
codex --sandbox read-only

# 設定ファイル（.codex/config.toml）
[sandbox]
mode = "workspace-write"
```

### 4. KiroCLI セクション

**現状**:

- KiroCLIは現時点で組み込みのサンドボックス機能を持たない
- ファイル操作やコマンド実行は直接システムに影響

**代替手段**:

- Docker環境での実行を推奨
- ファイルシステムのパーミッション設定で制限

### 5. Docker/コンテナ環境セクション

**Dockerfile例**:

```dockerfile
FROM node:20-slim

# 作業ディレクトリ
WORKDIR /workspace

# 必要なツールのインストール
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザーの作成（セキュリティ向上）
RUN useradd -m developer
USER developer

CMD ["claude-code"]
```

**docker-compose例**:

```yaml
version: '3.8'
services:
  ai-agent:
    build: .
    volumes:
      - ./src:/workspace/src
      - ./docs:/workspace/docs:ro  # ドキュメントは読み取り専用
    environment:
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
```

### 6. セキュリティ注意事項セクション

**リスク一覧**:

| リスク | 説明 | 対策 |
|--------|------|------|
| ファイル削除 | 重要ファイルの誤削除 | 読み取り専用マウント、バックアップ |
| 機密情報漏洩 | 環境変数やシークレットの露出 | 環境変数の制限、.envファイルの除外 |
| システム破壊 | OSレベルの変更 | コンテナ隔離、非rootユーザー |

**推奨設定**:

1. 本番環境では常にサンドボックスを有効化
2. 必要最小限の権限を付与
3. 機密情報を含むディレクトリはマウントしない
4. 定期的なバックアップを実施

## インターフェース設計

### ファイル構成

```
prompts/package/guides/sandbox-environment.md
```

### 外部参照

- Claude Code公式ドキュメント
- Codex CLI公式ドキュメント
- KiroCLI公式ドキュメント
- Docker公式ドキュメント

## Q&A

（設計中に発生した質問と回答を記録）

- なし
