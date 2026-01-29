# サンドボックス環境ガイド

AIエージェントをサンドボックス環境で安全に実行するためのガイドです。

## 検証情報

| 項目 | 値 | 参照先 |
|------|-----|--------|
| 検証日 | 2026-01-28 | - |
| Claude Code | 1.0.x | [公式ドキュメント](https://docs.anthropic.com/claude-code) |
| Codex CLI | 0.89.x | [GitHub](https://github.com/openai/codex) |
| KiroCLI | 0.x | [公式ドキュメント](https://kiro.dev/docs/cli) |

**注意**: 各ツールの仕様は頻繁に更新されます。実装時は公式ドキュメントで最新情報を確認してください。

---

## 1. 概要

### サンドボックスとは

サンドボックスは、隔離された実行環境でアプリケーションを動作させ、システムへの影響を制限する仕組みです。

### 目的

- **意図しないファイルの変更・削除を防止**: 重要なファイルやシステムファイルを保護
- **危険なコマンドの実行を制限**: 破壊的な操作をブロック
- **機密情報へのアクセスを制御**: APIキーや認証情報の露出を防止

### 利点

- 安全な実験環境の提供
- 本番環境への誤操作リスク軽減
- AIエージェントの動作検証が安全に行える

---

## 1.5 認証方式の違い

AIツールのバックエンドAPIへの認証方式は大きく2種類あります。Docker環境で使用する際の設定が異なるため、違いを理解しておくことが重要です。

### 認証方式比較

| 認証方式 | 説明 | メリット | デメリット |
|---------|------|---------|-----------|
| API Key | APIキーをHTTPヘッダーで送信 | シンプル、環境変数で管理可能、Docker連携が容易 | APIキーの漏洩リスク、従量課金 |
| OAuth | ブラウザでログイン→トークン取得 | サブスク契約で定額利用可能、キー管理不要 | Docker連携に工夫が必要、トークン更新が必要 |

### 各ツールの認証方式（参考例）

**注意**: 以下は参考例です。認証情報の保存先・対応プラン・コマンドはツールのバージョンや環境により異なる場合があります。実装時は必ず各ツールの公式ドキュメントと `--help` / `auth status` コマンドで確認してください。

| ツール | API Key | OAuth（参考） | 認証情報保存先（参考） |
|--------|---------|--------------|---------------------|
| Claude Code | `ANTHROPIC_API_KEY` | claude.aiプラン（要確認） | `~/.claude/`（要確認） |
| Codex CLI | `OPENAI_API_KEY` | OpenAIプラン（要確認） | `~/.codex/`（要確認） |
| KiroCLI | - | AWS認証（要確認） | `~/.kiro/`（要確認） |

### Docker利用時の認証方式選択

| 用途 | 推奨認証方式 | 理由 |
|------|-------------|------|
| CI/CD、自動化 | API Key | 環境変数で簡単に渡せる |
| 個人開発、コスト重視 | OAuth | サブスク契約で定額利用 |
| チーム開発 | 状況による | API Keyは共有リスク、OAuthは個人認証 |

---

## 1.7 サンドボックスの種類

サンドボックスには「アプリケーションレベル」と「OSレベル」の2種類があります。それぞれの特徴を理解し、適切に組み合わせることで効果的なセキュリティを実現できます。

### レベル比較

| レベル | 実装例 | 特徴 |
|--------|-------|------|
| アプリケーションレベル | Claude Codeのパーミッション、Codexの`--sandbox` | ツール内蔵の権限制御、設定が簡単 |
| OSレベル | Docker、chroot、VM | OS/コンテナによる隔離、より強力な保護 |

### 保護範囲の比較

**注意**: 実際の保護レベルは構成や設定に依存します。

| 保護対象 | アプリレベル | OSレベル（Docker等） |
|---------|-------------|---------------------|
| ファイルシステム | ツール経由のみ（制約弱） | 構成次第で強い制約可能 |
| ネットワーク | 通常は制御困難 | 構成次第で制御可能 |
| プロセス | 通常は制御困難 | 構成次第で隔離可能 |
| 環境変数 | ツールにより異なる | 構成次第で隔離可能 |

**補足**:

- アプリレベルでも一部ツールはネットワーク制限や環境変数マスク機能を持つ場合がある
- OSレベル（Docker）でも適切な設定（`--network none`、`:ro`マウント等）がなければ保護されない

### 推奨組み合わせパターン

| ユースケース | 推奨構成 | 具体例 |
|-------------|---------|--------|
| 読み取り専用作業 | OSレベル + アプリレベル | `docker run --read-only -v $(pwd):/workspace:ro ...` |
| 通常開発作業 | アプリレベル中心 | `-v $(pwd):/workspace:rw` + Codex `workspace-write` |
| 高セキュリティ要件 | OSレベル強化 | `--read-only --network none` + tmpfs + アプリサンドボックス |

---

## 2. ユースケース別推奨設定

| ユースケース | 推奨設定 | ツール別設定 |
|-------------|---------|-------------|
| コードレビュー・調査 | 読み取り専用 | Claude: Docker `:ro`マウント / Codex: `read-only` |
| 通常の開発作業 | ワークスペース書き込み | Claude: 特定ディレクトリのみマウント / Codex: `workspace-write` |
| 自動修正・リファクタリング | ワークスペース書き込み | 同上 |
| 特殊な要件（システム設定変更等） | フルアクセス（要注意） | Codex: `danger-full-access`（非推奨） |

### 選択フローチャート

```text
1. ファイル変更が必要か？
   - いいえ → 読み取り専用
   - はい → 2へ

2. 変更範囲はプロジェクト内のみか？
   - はい → ワークスペース書き込み
   - いいえ → フルアクセス（要承認）
```

---

## 3. Claude Code

### サンドボックス機能

Claude Codeはデフォルトでパーミッションシステムを持ちます。

- ファイル操作やコマンド実行時にユーザー確認を求める
- `--dangerously-skip-permissions` フラグで確認をスキップ可能（**非推奨**）

### Docker環境での実行

```bash
# 基本的なDocker実行（APIキー渡し方を含む）
docker run -it --rm \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  -v $(pwd):/workspace \
  -w /workspace \
  --user $(id -u):$(id -g) \
  node:20-slim \
  npx @anthropic-ai/claude-code

# 読み取り専用マウント（コードレビュー用）
# 注意: Claude CodeはAPI通信が必要なため、--network noneは使用不可
docker run -it --rm \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  -v $(pwd):/workspace:ro \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  node:20-slim \
  npx @anthropic-ai/claude-code
```

### オプション説明

| オプション | 説明 |
|-----------|------|
| `-e ANTHROPIC_API_KEY` | APIキーを環境変数で渡す（シークレットをイメージに含めない） |
| `--user $(id -u):$(id -g)` | ホストユーザーと同じUID/GIDで実行（ファイル権限問題を回避） |
| `:ro` | 読み取り専用マウント |
| `--cap-drop ALL` | 不要なLinux capabilityを削除（セキュリティ向上） |

### ネットワーク制限について

Claude CodeはAnthropicのAPIと通信する必要があるため、`--network none`は使用できません。
ファイルシステムの読み取り専用マウント（`:ro`）でプロジェクト領域のファイル変更を防止し、セキュリティを確保します。

**重要**: `:ro`マウントは**マウント対象のディレクトリのみ**を読み取り専用にします。コンテナのルートファイルシステムや`/tmp`などは書き込み可能のままです。完全な読み取り専用環境が必要な場合は、`--read-only`フラグと`tmpfs`を併用してください。

### 注意事項

- `--dangerously-skip-permissions` は本番環境での使用を避ける
- Docker使用時は適切なボリュームマウント設定を行う
- APIキーは環境変数で渡し、Dockerfileやイメージに含めない
- **サプライチェーン対策**: `npx`で毎回パッケージを取得する代わりに、バージョンを固定（`npx @anthropic-ai/claude-code@1.0.0`）するか、Dockerfileで事前インストールすることを推奨

---

## 3.5 Claude Code - OAuth認証（サブスク契約）でのDocker利用

claude.ai Pro/Teamプランを使用している場合、APIキーではなくOAuth認証でClaude Codeを利用できます。Docker環境で使用するには、ホストで事前に認証を行い、認証情報をコンテナにマウントします。

### 前提条件

- claude.ai Pro/Teamプランに加入済み
- ホストマシンでClaude Codeがインストール済み
- ホストマシンで認証済み（`claude auth login` 実行済み）

### 認証情報の準備（ホストで実行）

```bash
# Claude Codeのインストール（未インストールの場合）
npm install -g @anthropic-ai/claude-code

# OAuth認証（ブラウザが開きます）
claude auth login

# 認証状態の確認
claude auth status

# 認証情報の保存先を確認
ls -la ~/.claude/
```

**注意**: 認証情報の保存先（`~/.claude/`）はバージョンにより異なる場合があります。`claude auth status` の出力で実際のパスを確認してください。

### Docker実行例

```bash
# 基本的な実行（認証情報をマウント）
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.claude:/home/node/.claude:ro \
  -v $(pwd):/workspace \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  node:20-slim \
  npx @anthropic-ai/claude-code

# 読み取り専用作業用
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.claude:/home/node/.claude:ro \
  -v $(pwd):/workspace:ro \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /home/node/.npm \
  --tmpfs /home/node/.cache \
  node:20-slim \
  npx @anthropic-ai/claude-code
```

**注意**: `--user $(id -u):$(id -g)` を使用する場合、`-e HOME=/home/node` を明示的に設定しないとCLIが正しい認証情報パスを見つけられない場合があります。

**サプライチェーン対策**: `npx`で毎回パッケージを取得する代わりに、バージョンを固定（`npx @anthropic-ai/claude-code@1.0.0`）するか、Dockerfileで事前インストールすることを推奨します。

### docker-compose例

```yaml
version: '3.8'
services:
  claude-code:
    image: node:20-slim
    environment:
      - HOME=/home/node
    volumes:
      - ~/.claude:/home/node/.claude:ro  # 認証情報（読み取り専用）
      - ./src:/workspace/src
      - ./docs:/workspace/docs:ro
    working_dir: /workspace
    user: "${UID}:${GID}"
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    command: npx @anthropic-ai/claude-code
```

### トラブルシューティング

| 問題 | 原因 | 対処法 |
|------|------|--------|
| 認証エラー | トークン期限切れ | ホストで `claude auth login` を再実行 |
| 権限エラー | UID/GID不一致 | `--user $(id -u):$(id -g)` を確認 |
| ファイルが見つからない | 認証情報パスの違い | `claude auth status` でパスを確認 |
| トークン更新失敗 | `:ro`マウント中の更新 | 一時的に`:rw`でマウントして更新 |

**注意**: 認証情報ディレクトリを`:ro`でマウントしている場合、トークンの自動更新ができません。定期的にホスト側で `claude auth login` を実行してトークンを更新してください。

---

## 4. Codex CLI

### サンドボックス設定オプション

| オプション | 説明 | ユースケース |
|-----------|------|-------------|
| `read-only` | 読み取りのみ許可、ファイル変更不可 | コードレビュー、調査 |
| `workspace-write` | ワークスペース内の書き込み許可 | 通常の開発作業 |
| `danger-full-access` | 全アクセス許可、システム変更可能 | 特殊な要件がある場合のみ |

### 設定方法

```bash
# コマンドラインオプション（最優先）
codex --sandbox read-only

# 短縮形
codex -s read-only

# 設定ファイル（~/.codex/config.toml）
[sandbox]
mode = "workspace-write"
```

### 設定の優先順位（検証時点: 2026-01、v0.89.x）

以下は検証時点での挙動です。最新の仕様は[公式ドキュメント](https://github.com/openai/codex)を参照してください。

1. コマンドライン引数（`--sandbox`）
2. 環境変数（`CODEX_SANDBOX`）
3. プロジェクト設定（`.codex/config.toml`）
4. ユーザー設定（`~/.codex/config.toml`）
5. デフォルト値（`workspace-write`）

### 権限制御の範囲

- `read-only`: ファイル読み取り、コマンド実行（出力のみ）
- `workspace-write`: カレントディレクトリ以下の読み書き
- `danger-full-access`: システム全体へのアクセス（sudo相当の危険性）

---

## 4.5 Codex CLI - OAuth認証でのDocker利用

**注意**: このセクションの内容は参考例です。Codex CLIのOAuth認証の詳細（対応プラン、コマンド、保存先）は公式ドキュメントで確認してください。

OpenAIのサブスクリプションを使用している場合、APIキーではなくOAuth認証でCodex CLIを利用できる可能性があります。Docker環境で使用するには、ホストで事前に認証を行い、認証情報をコンテナにマウントします。

### 前提条件

- OpenAIのサブスクリプションに加入済み（対応プランは要確認）
- ホストマシンでCodex CLIがインストール済み
- ホストマシンで認証済み（認証コマンドは要確認）

### 認証情報の準備（ホストで実行）

```bash
# Codex CLIのインストール（未インストールの場合）
npm install -g @openai/codex

# OAuth認証（ブラウザが開きます）
codex auth login

# 認証状態の確認
codex auth status

# 認証情報の保存先を確認
ls -la ~/.codex/
```

**注意**: 認証情報の保存先（`~/.codex/`）はバージョンにより異なる場合があります。`codex auth status` の出力で実際のパスを確認してください。

### Docker実行例

```bash
# 基本的な実行（認証情報をマウント）
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.codex:/home/node/.codex:ro \
  -v $(pwd):/workspace \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  node:20-slim \
  npx @openai/codex --sandbox workspace-write

# 読み取り専用作業用
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.codex:/home/node/.codex:ro \
  -v $(pwd):/workspace:ro \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /home/node/.npm \
  --tmpfs /home/node/.cache \
  node:20-slim \
  npx @openai/codex --sandbox read-only
```

**注意**: `--user $(id -u):$(id -g)` を使用する場合、`-e HOME=/home/node` を明示的に設定しないとCLIが正しい認証情報パスを見つけられない場合があります。

**サプライチェーン対策**: `npx`で毎回パッケージを取得する代わりに、バージョンを固定（`npx @openai/codex@0.89.0`）するか、Dockerfileで事前インストールすることを推奨します。

### docker-compose例

```yaml
version: '3.8'
services:
  codex:
    image: node:20-slim
    environment:
      - HOME=/home/node
    volumes:
      - ~/.codex:/home/node/.codex:ro  # 認証情報（読み取り専用）
      - ./src:/workspace/src
      - ./docs:/workspace/docs:ro
    working_dir: /workspace
    user: "${UID}:${GID}"
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    command: npx @openai/codex --sandbox workspace-write
```

### トラブルシューティング

| 問題 | 原因 | 対処法 |
|------|------|--------|
| 認証エラー | トークン期限切れ | ホストで `codex auth login` を再実行 |
| 権限エラー | UID/GID不一致 | `--user $(id -u):$(id -g)` を確認、または `--group-add` で調整 |
| config.tomlが見つからない | 設定ファイルパスの違い | `codex auth status` でパスを確認 |
| サンドボックス設定が効かない | 設定の優先順位問題 | コマンドライン引数 `--sandbox` を明示的に指定 |

**注意**: 認証情報ディレクトリを`:ro`でマウントしている場合、トークンの自動更新ができません。定期的にホスト側で `codex auth login` を実行してトークンを更新してください。

---

## 5. KiroCLI

### 現状（2026-01時点）

- KiroCLIは組み込みのサンドボックス機能を持たない
- ファイル操作やコマンド実行は直接システムに影響
- 公式ドキュメント: [KiroCLI Docs](https://kiro.dev/docs/cli)

### 代替手段

1. **Docker環境での実行（推奨）**: 後述のDockerセクションを参照
2. **ファイルシステムのパーミッション設定**: 専用ユーザーでの実行
3. **chroot/jail環境**: 高度な隔離が必要な場合

### 将来の対応

KiroCLIのサンドボックス機能は開発中の可能性があります。最新情報は公式ドキュメントを確認してください。

---

## 5.5 KiroCLI - Docker環境での利用

**注意**: このセクションの内容は参考例です。KiroCLIのパッケージ名、認証コマンド、保存先は公式ドキュメントで確認してください。

KiroCLIは組み込みのサンドボックス機能を持たないため、Docker環境での実行が推奨されます。認証情報をコンテナにマウントして使用します。

### 前提条件

- KiroCLI対応のサブスクリプションに加入済み（対応プランは要確認）
- ホストマシンでKiroCLIがインストール済み
- ホストマシンで認証済み（認証コマンドは要確認）

### 認証情報の準備（ホストで実行）

```bash
# KiroCLIのインストール（パッケージ名は要確認）
npm install -g kiro-cli  # 実際のパッケージ名は公式ドキュメントで確認

# OAuth認証（コマンドは要確認）
kiro auth login

# 認証状態の確認
kiro auth status

# 認証情報の保存先を確認
ls -la ~/.kiro/
```

**注意**: 認証情報の保存先（`~/.kiro/`）はバージョンにより異なる場合があります。認証状態確認コマンドの出力で実際のパスを確認してください。また、AWS認証情報（`~/.aws/`）との連携が必要な場合があります。

### Docker実行例

```bash
# 基本的な実行（認証情報をマウント）
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.kiro:/home/node/.kiro:ro \
  -v $(pwd):/workspace \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  node:20-slim \
  npx kiro-cli  # パッケージ名は要確認

# AWS認証情報も必要な場合
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.kiro:/home/node/.kiro:ro \
  -v ~/.aws:/home/node/.aws:ro \
  -v $(pwd):/workspace \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  node:20-slim \
  npx kiro-cli

# 読み取り専用作業用（高セキュリティ）
docker run -it --rm \
  -e HOME=/home/node \
  -v ~/.kiro:/home/node/.kiro:ro \
  -v $(pwd):/workspace:ro \
  -w /workspace \
  --user $(id -u):$(id -g) \
  --cap-drop ALL \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /home/node/.npm \
  --tmpfs /home/node/.cache \
  node:20-slim \
  npx kiro-cli
```

**注意**: `--user $(id -u):$(id -g)` を使用する場合、`-e HOME=/home/node` を明示的に設定しないとCLIが正しい認証情報パスを見つけられない場合があります。

**サプライチェーン対策**: `npx`で毎回パッケージを取得する代わりに、バージョンを固定するか、Dockerfileで事前インストールすることを推奨します。

### docker-compose例

```yaml
version: '3.8'
services:
  kiro:
    image: node:20-slim
    environment:
      - HOME=/home/node
    volumes:
      - ~/.kiro:/home/node/.kiro:ro  # KiroCLI認証情報
      - ~/.aws:/home/node/.aws:ro    # AWS認証情報（必要な場合）
      - ./src:/workspace/src
      - ./docs:/workspace/docs:ro
    working_dir: /workspace
    user: "${UID}:${GID}"
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    command: npx kiro-cli  # パッケージ名は要確認
```

### トラブルシューティング

| 問題 | 原因 | 対処法 |
|------|------|--------|
| 認証エラー | トークン期限切れ | ホストで `kiro auth login` を再実行 |
| AWS認証エラー | AWS認証情報が不足 | `~/.aws/` もマウントする |
| 権限エラー | UID/GID不一致 | `--user $(id -u):$(id -g)` を確認 |
| ファイルが見つからない | 認証情報パスの違い | `kiro auth status` でパスを確認 |

**注意**: KiroCLIはサンドボックス機能を持たないため、Docker側で必ずセキュリティ設定（`--cap-drop ALL`、`:ro`マウント等）を行ってください。

**注意**: 認証情報ディレクトリを`:ro`でマウントしている場合、トークンの自動更新ができません。定期的にホスト側で認証コマンドを実行してトークンを更新してください。

---

## 6. Docker/コンテナ環境

### Dockerfile例（セキュリティ強化版）

```dockerfile
FROM node:20-slim

# 作業ディレクトリ
WORKDIR /workspace

# 必要なツールのインストール
RUN npm install -g @anthropic-ai/claude-code

# 非rootユーザーの作成（セキュリティ向上）
RUN groupadd -g 1000 developer && \
    useradd -u 1000 -g developer -m developer

# 不要なcapabilityを削除するための準備
# （実行時に --cap-drop ALL で指定）

USER developer

CMD ["claude-code"]
```

### docker-compose例（本番向け）

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
    # セキュリティ設定
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true  # ルートファイルシステムを読み取り専用に
    tmpfs:
      - /tmp  # 一時ファイル用に書き込み可能領域を提供
      - /home/developer/.config  # 設定ファイル用
      - /home/developer/.cache   # キャッシュ用
      - /home/developer/.npm     # npmキャッシュ用
    # ネットワーク制限（必要に応じて）
    # network_mode: none
```

**注意**:

- `read_only: true` を使用する場合、ツールが書き込みに使用するホーム/キャッシュ領域を`tmpfs`で確保する必要があります
- Claude Codeは `~/.config` やキャッシュ領域への書き込みを行うため、上記の`tmpfs`設定が必要です
- ワークスペースへの書き込みが必要な場合は、明示的にボリュームマウント（`:rw`）を使用してください

### 実行コマンド例

```bash
# 最小権限での実行
docker run -it --rm \
  --cap-drop ALL \
  --security-opt no-new-privileges:true \
  --user $(id -u):$(id -g) \
  -e ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}" \
  -v $(pwd)/src:/workspace/src \
  -w /workspace \
  ai-agent:latest
```

### 検証方法

```bash
# サンドボックスが正しく動作しているか確認

# 書き込み制限のテスト
docker run --rm -v $(pwd):/workspace:ro alpine touch /workspace/test.txt
# → "Read-only file system" エラーが出れば成功

# ネットワーク制限のテスト（API不要なツールの場合）
# ICMP（ping）テスト
docker run --rm --network none alpine ping -c 1 google.com
# → "Network is unreachable" エラーが出れば成功

# DNS解決テスト
docker run --rm --network none alpine nslookup google.com
# → "server can't find google.com" エラーが出れば成功

# HTTP接続テスト
docker run --rm --network none alpine wget -q -O- http://example.com
# → "bad address" または接続エラーが出れば成功
```

---

## 7. セキュリティ注意事項

### リスク一覧

| リスク | 説明 | 対策 |
|--------|------|------|
| ファイル削除 | 重要ファイルの誤削除 | 読み取り専用マウント、バックアップ |
| 機密情報漏洩 | 環境変数やシークレットの露出 | 環境変数の制限、.envファイルの除外 |
| システム破壊 | OSレベルの変更 | コンテナ隔離、非rootユーザー |
| ネットワーク外部通信 | 意図しない外部送信 | `--network none`（※API不要なツールのみ）、ファイアウォール |
| シークレットのログ露出 | APIキー等がログに記録される | ログフィルタリング、シークレット管理ツール |
| プロンプトインジェクション | 悪意あるプロンプトによる危険操作 | 入力検証、サンドボックス強化 |
| サプライチェーン攻撃 | 依存パッケージの脆弱性 | 依存関係の監査、固定バージョン |

### ネットワーク制御

```bash
# 完全にネットワークを無効化（APIアクセス不要なツールのみ）
# 注意: Claude Code等のAPI通信が必要なツールでは使用不可
docker run --network none ...
```

**注意**: AIエージェントは通常API通信が必要なため、`--network none`は限定的な用途にのみ使用可能です。
ファイルシステムの制限（読み取り専用マウント）と権限制限（`--cap-drop ALL`）でセキュリティを確保することを推奨します。

```yaml
# docker-compose: 外部通信を遮断し、内部通信のみ許可
# 注意: これは外部通信を完全に遮断します（特定ホスト許可ではありません）
networks:
  internal_only:
    driver: bridge
    internal: true  # 外部インターネットへのアクセスを遮断
```

### シークレット保護のベストプラクティス

1. APIキーは環境変数で渡す（Dockerfileに書かない）
2. `.env`ファイルはマウントしない
3. シークレット管理ツール（Vault等）の使用を検討
4. ログにシークレットが含まれないよう設定

### プロンプトインジェクション対策

1. 信頼できないソースからのプロンプトを検証
2. サンドボックスを常に有効化
3. 危険なコマンドパターンの検出・ブロック

### 依存関係のセキュリティ

1. `npm audit` / `pip audit` で脆弱性チェック
2. 依存パッケージのバージョンを固定
3. 信頼できるソースからのみインストール

### 推奨設定

1. **本番環境では常にサンドボックスを有効化**
2. **必要最小限の権限を付与**（最小権限の原則）
3. **機密情報を含むディレクトリはマウントしない**
4. **定期的なバックアップを実施**
5. **ネットワークアクセスは必要最小限に制限**
6. **非rootユーザーでの実行を徹底**

---

## 参考リンク

| リソース | URL |
|---------|-----|
| Claude Code公式ドキュメント | [docs.anthropic.com](https://docs.anthropic.com/claude-code) |
| Codex CLI公式ドキュメント | [github.com/openai/codex](https://github.com/openai/codex) |
| KiroCLI公式ドキュメント | [kiro.dev](https://kiro.dev/docs/cli) |
| Docker公式ドキュメント | [docs.docker.com](https://docs.docker.com/) |
| Dockerセキュリティベストプラクティス | [Docker Security](https://docs.docker.com/engine/security/) |
