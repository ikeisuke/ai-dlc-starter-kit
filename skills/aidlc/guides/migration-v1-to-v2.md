# AI-DLC v1 → v2 移行ガイド

## 概要

AI-DLC v2.0.0 では、フェーズプロンプトがClaude Code スキルとして再構成されました。
このガイドでは v1 から v2 への主要な変更点と移行手順を説明します。

## 主要な変更点

### 1. フェーズプロンプトのスキル化

| v1 | v2 |
|-----|-----|
| `docs/aidlc/prompts/inception.md` | `/aidlc inception`（`skills/aidlc/steps/inception/` に分割） |
| `docs/aidlc/prompts/construction.md` | `/aidlc construction`（`skills/aidlc/steps/construction/` に分割） |
| `docs/aidlc/prompts/operations.md` | `/aidlc operations`（`skills/aidlc/steps/operations/` に分割） |
| `prompts/setup-prompt.md` | `/aidlc setup`（`skills/aidlc/steps/setup/` に分割） |

### 2. ディレクトリ構造の変更

```text
v1:
docs/aidlc/prompts/          → フェーズプロンプト
docs/aidlc/prompts/common/   → 共通プロンプト

v2:
skills/aidlc/SKILL.md        → オーケストレーター
skills/aidlc/steps/inception/ → Inception Phase ステップファイル（6ファイル）
skills/aidlc/steps/construction/ → Construction Phase ステップファイル（4ファイル）
skills/aidlc/steps/operations/   → Operations Phase ステップファイル（4+1ファイル）
skills/aidlc/steps/setup/        → Setup Phase ステップファイル（3ファイル）
skills/aidlc/steps/common/       → 共通ステップファイル
```

### 3. CLAUDE.md / AGENTS.md の参照先変更

| v1 | v2 |
|-----|-----|
| `@docs/aidlc/prompts/CLAUDE.md` | `@skills/aidlc/CLAUDE.md` |
| `@docs/aidlc/prompts/AGENTS.md` | `@skills/aidlc/AGENTS.md` |

### 4. フェーズ開始方法の変更

| v1 | v2 |
|-----|-----|
| 「`docs/aidlc/prompts/inception.md` を読み込んで」 | 「インセプション進めて」or `/aidlc inception` |
| 「`docs/aidlc/prompts/construction.md` を読み込んで」 | 「コンストラクション進めて」or `/aidlc construction` |
| 「`docs/aidlc/prompts/operations.md` を読み込んで」 | 「オペレーション進めて」or `/aidlc operations` |
| 「`prompts/setup-prompt.md` を読み込んで」 | 「セットアップ」or `/aidlc setup` |

### 5. 削除されたディレクトリ

以下のディレクトリは v2 で廃止されました:

| ディレクトリ | 移行先 |
|------------|--------|
| `docs/aidlc/prompts/` | `skills/aidlc/steps/` |
| `docs/aidlc/tests/` | `skills/aidlc/scripts/tests/` |

### 6. 継続利用されるディレクトリ

以下のディレクトリは v2 でも引き続き使用されます:

| ディレクトリ | 説明 |
|------------|------|
| `skills/aidlc/templates/` | ドキュメントテンプレート |
| `docs/aidlc/guides/` | ガイドドキュメント |
| `skills/aidlc/config/` | デフォルト設定（defaults.toml） |
| `skills/aidlc/scripts/` | ユーティリティスクリプト |
| `skills/` | レビュースキル等の個別スキル |

## 移行手順

### 既存プロジェクトの移行

1. **スターターキットの更新**: `/aidlc setup` を実行して最新版に更新
2. **CLAUDE.md の更新**: 参照先を `@skills/aidlc/CLAUDE.md` に変更
3. **AGENTS.md の更新**: 参照先を `@skills/aidlc/AGENTS.md` に変更
4. **旧ファイルの削除**: `docs/aidlc/prompts/` ディレクトリを削除

### フェーズ指示の移行

従来のファイルパス指定による指示は、`/aidlc` コマンドにリダイレクトされます。
新しい指示方法への移行を推奨しますが、旧形式も引き続き認識されます。

## 注意事項

- 既存サイクルの成果物（`.aidlc/cycles/` 配下）は影響を受けません
- `.aidlc/config.toml` の設定は変更不要です
- `skills/aidlc/templates/` のテンプレートは引き続き同じパスで参照されます
