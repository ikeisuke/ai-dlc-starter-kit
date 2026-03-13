# 論理設計: マーケットプレイス対応

## 概要

リポジトリルートに `.claude-plugin/marketplace.json` を配置し、Claude Code のマーケットプレイス機能からスキルをインストール可能にする。

## コンポーネント構成

### 1. marketplace.json（新規作成）

**配置場所**: `.claude-plugin/marketplace.json`（リポジトリルート直下）

**理由**: Claude Code のプラグイン規約に従い、`.claude-plugin/` ディレクトリにカタログファイルを配置する。`prompts/package/` 配下ではなくリポジトリルートに配置する理由は、`/plugin marketplace add` がリポジトリルートの `.claude-plugin/` を参照するため。

**sync-package.sh との関係**: `.claude-plugin/` は `prompts/package/` → `docs/aidlc/` の rsync 対象外。メタ開発ルール（`prompts/` がスターターキット本体）の適用外であり、リポジトリルートに直接配置する。

### 2. スキルパス参照規則

marketplace.json 内のスキルパスは、リポジトリルートからの相対パスを使用する。

**パス設計の根拠**: Claude Code の `/plugin marketplace add` はリポジトリをクローンし、`.claude-plugin/marketplace.json` 内のパスをリポジトリルート起点で解決する。このリポジトリではスキルが `prompts/package/skills/` に配置されているため、パスは `./prompts/package/skills/<slug>` とする。

```text
.claude-plugin/marketplace.json
  └→ plugins[].skills[] = ["./prompts/package/skills/reviewing-code", ...]
     ※ source が "./" の場合、リポジトリルート起点
```

**注意**: `claude-skills` リポジトリではスキルがルート直下 `skills/` にあるが、このリポジトリでは `prompts/package/skills/` にあるため、パスが異なる。

### 3. プラグイングループ設計

スキルを論理的に2グループに分類:

| グループ名 | 説明 | 含まれるスキル |
|-----------|------|-------------|
| `aidlc` | AI-DLC固有のワークフロースキル | aidlc-setup, reviewing-architecture, reviewing-code, reviewing-inception, reviewing-security, squash-unit |
| `tools` | 汎用ツールスキル | session-title |

**除外**: `versioning-with-jj` はUnit 004で削除予定のため、カタログに登録しない。

### 4. marketplace.json の具体的構造

```json
{
  "name": "ai-dlc-starter-kit",
  "owner": {
    "name": "ikeisuke",
    "email": "keisuke@reirou.jp"
  },
  "metadata": {
    "description": "AI-DLC (AI-Driven Development Lifecycle) skills for Claude Code",
    "version": "1.21.0"
  },
  "plugins": [
    {
      "name": "aidlc",
      "description": "AI-DLC workflow skills for development lifecycle management",
      "source": "./",
      "strict": false,
      "skills": [
        "./prompts/package/skills/aidlc-setup",
        "./prompts/package/skills/reviewing-architecture",
        "./prompts/package/skills/reviewing-code",
        "./prompts/package/skills/reviewing-inception",
        "./prompts/package/skills/reviewing-security",
        "./prompts/package/skills/squash-unit"
      ]
    },
    {
      "name": "tools",
      "description": "Utility skills for Claude Code workflows",
      "source": "./",
      "strict": false,
      "skills": [
        "./prompts/package/skills/session-title"
      ]
    }
  ]
}
```

## インターフェース定義

### マーケットプレイス方式のインストールフロー

```text
ユーザー操作:
1. /plugin marketplace add <リポジトリURL>
   → Claude Code がリポジトリを登録
   → .claude-plugin/marketplace.json を読み取りスキルカタログを取得

2. /plugin install <スキルスラッグ>
   → カタログからスラッグに一致するスキルパスを解決
   → スキルをインストール（.claude/plugins/cache/ にキャッシュ）
   → スキルが呼び出し可能になる
```

### 埋め込み方式のインストールフロー（既存・変更なし）

```text
ユーザー操作:
1. /aidlc-setup
   → sync-package.sh: prompts/package/ → docs/aidlc/ を rsync
   → setup-ai-tools.sh: docs/aidlc/skills/ → .claude/skills/ にシンボリックリンク作成
   → スキルが呼び出し可能になる
```

## 2方式の共存と競合解決

### 対象ユーザーの違い

| 方式 | 対象 | 使用シナリオ |
|------|------|-------------|
| マーケットプレイス方式 | 外部プロジェクトの利用者 | スターターキットを使わずに個別スキルだけ導入したい場合 |
| 埋め込み方式 | スターターキット利用者 | `/aidlc-setup` でスターターキット全体をセットアップする場合 |

### 競合時の動作

同一スキルが両方式で導入された場合:

1. マーケットプレイス方式: `.claude/plugins/cache/` にスキルをキャッシュ
2. 埋め込み方式: `.claude/skills/<slug>` にシンボリックリンクを作成（`docs/aidlc/skills/<slug>` を参照）

**運用ルール（二重導入の禁止）**: スターターキット利用者（埋め込み方式）は、埋め込み方式で提供される同一スキルをマーケットプレイス方式で重複インストールしないこと。マーケットプレイス方式は以下のケースでのみ使用する:
- 埋め込み方式を使用しない外部プロジェクトでの個別スキル導入
- 埋め込み方式で提供されない追加スキルの導入

**前提としているClaude Code仕様**: `/plugin marketplace add` はリポジトリの `.claude-plugin/marketplace.json` を読み取りスキルカタログを取得する。`/plugin install` はカタログからスキルパスを解決しインストールする。この仕様は動作確認時に検証する。

## エラーケース設計

エラーハンドリングは Claude Code プラットフォーム側の責務。以下はテスト時の期待動作:

| ケース | 期待動作 | 検証方法 |
|--------|---------|---------|
| 存在しないスキル名の指定 | エラーメッセージ表示、インストールされない | `/plugin install nonexistent-skill` |
| 既インストールスキルの再インストール | 上書き更新 | `/plugin install reviewing-code` を2回実行 |
| リポジトリ未登録での install | エラーメッセージ表示 | marketplace add 前に install 実行 |
| シンボリックリンク先不在（埋め込み方式） | Warning表示しスキップ、セットアップ中断しない | setup-ai-tools.sh 実行時 |

## 変更影響範囲

| コンポーネント | 変更 | 影響 |
|--------------|------|------|
| `.claude-plugin/marketplace.json` | 新規作成 | マーケットプレイスからのインストールが可能になる |
| `prompts/package/bin/sync-package.sh` | 変更なし | rsync 対象は `prompts/package/` → `docs/aidlc/` のみ |
| `docs/aidlc/bin/setup-ai-tools.sh` | 変更なし | シンボリックリンク作成ロジックは変更不要 |
| `.gitignore` | 確認のみ | `.claude-plugin/` がignoreされていないことを確認 |
