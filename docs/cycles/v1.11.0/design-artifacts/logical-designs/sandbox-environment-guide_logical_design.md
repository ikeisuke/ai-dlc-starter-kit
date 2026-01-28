# 論理設計: サンドボックス環境ガイド

## 概要

各AIエージェントのサンドボックス設定の詳細と実装方針を定義する。

## 検証情報

| 項目 | 値 | 参照先 |
|------|-----|--------|
| 検証日 | 2026-01-28 | - |
| Claude Code | 1.0.x | [公式ドキュメント](https://docs.anthropic.com/claude-code) |
| Codex CLI | 0.89.x | [GitHub](https://github.com/openai/codex) |
| KiroCLI | 0.x | [公式ドキュメント](https://kiro.dev/docs/cli) |

**注意**: 各ツールの仕様は頻繁に更新されます。実装時は公式ドキュメントで最新情報を確認してください。

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

### 2. ユースケース別推奨設定セクション【新規】

| ユースケース | 推奨設定 | ツール別設定 |
|-------------|---------|-------------|
| コードレビュー・調査 | 読み取り専用 | Claude: Docker `:ro`マウント / Codex: `read-only` |
| 通常の開発作業 | ワークスペース書き込み | Claude: 特定ディレクトリのみマウント / Codex: `workspace-write` |
| 自動修正・リファクタリング | ワークスペース書き込み | 同上 |
| 特殊な要件（システム設定変更等） | フルアクセス（要注意） | Codex: `danger-full-access`（非推奨） |

**選択フローチャート**:

```text
1. ファイル変更が必要か？
   - いいえ → 読み取り専用
   - はい → 2へ
2. 変更範囲はプロジェクト内のみか？
   - はい → ワークスペース書き込み
   - いいえ → フルアクセス（要承認）
```

### 3. Claude Code セクション

**サンドボックス機能**:

- Claude Codeはデフォルトでパーミッションシステムを持つ
- ファイル操作やコマンド実行時にユーザー確認を求める
- `--dangerously-skip-permissions` フラグで確認をスキップ可能（非推奨）

**Docker環境での実行**:

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

**オプション説明**:

| オプション | 説明 |
|-----------|------|
| `-e ANTHROPIC_API_KEY` | APIキーを環境変数で渡す（シークレットをイメージに含めない） |
| `--user $(id -u):$(id -g)` | ホストユーザーと同じUID/GIDで実行（ファイル権限問題を回避） |
| `:ro` | 読み取り専用マウント |
| `--cap-drop ALL` | 不要なLinux capabilityを削除（セキュリティ向上） |

**ネットワーク制限について**:

Claude CodeはAnthropicのAPIと通信する必要があるため、`--network none`は使用できません。
ファイルシステムの読み取り専用マウント（`:ro`）でファイル変更を防止し、セキュリティを確保します。

**注意事項**:

- `--dangerously-skip-permissions` は本番環境での使用を避ける
- Docker使用時は適切なボリュームマウント設定を行う
- APIキーは環境変数で渡し、Dockerfileやイメージに含めない

### 4. Codex CLI セクション

**サンドボックス設定オプション**:

| オプション | 説明 | ユースケース |
|-----------|------|-------------|
| `read-only` | 読み取りのみ許可、ファイル変更不可 | コードレビュー、調査 |
| `workspace-write` | ワークスペース内の書き込み許可 | 通常の開発作業 |
| `danger-full-access` | 全アクセス許可、システム変更可能 | 特殊な要件がある場合のみ |

**設定方法**:

```bash
# コマンドラインオプション（最優先）
codex --sandbox read-only

# 短縮形
codex -s read-only

# 設定ファイル（~/.codex/config.toml）
[sandbox]
mode = "workspace-write"
```

**設定の優先順位**:

1. コマンドライン引数（`--sandbox`）
2. 環境変数（`CODEX_SANDBOX`）
3. プロジェクト設定（`.codex/config.toml`）
4. ユーザー設定（`~/.codex/config.toml`）
5. デフォルト値（`workspace-write`）

**権限制御の範囲**:

- `read-only`: ファイル読み取り、コマンド実行（出力のみ）
- `workspace-write`: カレントディレクトリ以下の読み書き
- `danger-full-access`: システム全体へのアクセス（sudo相当の危険性）

### 5. KiroCLI セクション

**現状（2026-01時点）**:

- KiroCLIは組み込みのサンドボックス機能を持たない
- ファイル操作やコマンド実行は直接システムに影響
- 公式ドキュメント: [KiroCLI Docs](https://kiro.dev/docs/cli)

**代替手段**:

1. **Docker環境での実行（推奨）**: 後述のDockerセクションを参照
2. **ファイルシステムのパーミッション設定**: 専用ユーザーでの実行
3. **chroot/jail環境**: 高度な隔離が必要な場合

**将来の対応**:

- KiroCLIのサンドボックス機能は開発中の可能性があります
- 最新情報は公式ドキュメントを確認してください

### 6. Docker/コンテナ環境セクション

**Dockerfile例（セキュリティ強化版）**:

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

**docker-compose例（本番向け）**:

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
    # ネットワーク制限（必要に応じて）
    # network_mode: none
```

**注意**: `read_only: true` を使用する場合、ワークスペースへの書き込みが必要な場合は
明示的にボリュームマウント（`:rw`）または `tmpfs` で書き込み可能領域を確保してください。

**実行コマンド例**:

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

**検証方法**:

```bash
# サンドボックスが正しく動作しているか確認
# 書き込み制限のテスト
docker run --rm -v $(pwd):/workspace:ro alpine touch /workspace/test.txt
# → "Read-only file system" エラーが出れば成功

# ネットワーク制限のテスト
docker run --rm --network none alpine ping -c 1 google.com
# → "Network is unreachable" エラーが出れば成功
```

### 7. セキュリティ注意事項セクション【拡充】

**リスク一覧**:

| リスク | 説明 | 対策 |
|--------|------|------|
| ファイル削除 | 重要ファイルの誤削除 | 読み取り専用マウント、バックアップ |
| 機密情報漏洩 | 環境変数やシークレットの露出 | 環境変数の制限、.envファイルの除外 |
| システム破壊 | OSレベルの変更 | コンテナ隔離、非rootユーザー |
| ネットワーク外部通信 | 意図しない外部送信 | `--network none`（※API不要なツールのみ）、ファイアウォール |
| シークレットのログ露出 | APIキー等がログに記録される | ログフィルタリング、シークレット管理ツール |
| プロンプトインジェクション | 悪意あるプロンプトによる危険操作 | 入力検証、サンドボックス強化 |
| サプライチェーン攻撃 | 依存パッケージの脆弱性 | 依存関係の監査、固定バージョン |

**ネットワーク制御**:

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

**シークレット保護のベストプラクティス**:

1. APIキーは環境変数で渡す（Dockerfileに書かない）
2. `.env`ファイルはマウントしない
3. シークレット管理ツール（Vault等）の使用を検討
4. ログにシークレットが含まれないよう設定

**プロンプトインジェクション対策**:

1. 信頼できないソースからのプロンプトを検証
2. サンドボックスを常に有効化
3. 危険なコマンドパターンの検出・ブロック

**依存関係のセキュリティ**:

1. `npm audit` / `pip audit` で脆弱性チェック
2. 依存パッケージのバージョンを固定
3. 信頼できるソースからのみインストール

**推奨設定**:

1. 本番環境では常にサンドボックスを有効化
2. 必要最小限の権限を付与（最小権限の原則）
3. 機密情報を含むディレクトリはマウントしない
4. 定期的なバックアップを実施
5. ネットワークアクセスは必要最小限に制限
6. 非rootユーザーでの実行を徹底

## インターフェース設計

### ファイル構成

```text
prompts/package/guides/sandbox-environment.md
```

### 外部参照

| リソース | URL |
|---------|-----|
| Claude Code公式ドキュメント | [docs.anthropic.com](https://docs.anthropic.com/claude-code) |
| Codex CLI公式ドキュメント | [github.com/openai/codex](https://github.com/openai/codex) |
| KiroCLI公式ドキュメント | [kiro.dev](https://kiro.dev/docs/cli) |
| Docker公式ドキュメント | [docs.docker.com](https://docs.docker.com/) |
| Dockerセキュリティベストプラクティス | [Docker Security](https://docs.docker.com/engine/security/) |

## Q&A

（設計中に発生した質問と回答を記録）

- なし
