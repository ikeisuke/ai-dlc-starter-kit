# ドメインモデル: Co-Authored-By設定の柔軟化

## 概要

コミットメッセージのCo-Authored-By値をユーザーが設定可能にするための設定項目を追加する。

## エンティティ

### CommitConfig（設定エンティティ）

| 属性 | 型 | 説明 |
|------|-----|------|
| ai_author | String | Co-Authored-Byに使用するAIの著者情報 |

**不変条件**:
- ai_author は任意の文字列（バリデーションなし）
- 未設定時はデフォルト値を使用

## 値オブジェクト

### AiAuthor（著者情報）

**形式**: 任意の文字列（バリデーションなし）

**推奨形式**: `{ツール名} <{email}>`

**設定例**:
- `Claude <noreply@anthropic.com>`（デフォルト）
- `Claude Opus 4.5 <noreply@anthropic.com>`
- `GitHub Copilot <noreply@github.com>`
- `My Custom AI`（emailなしも可）

**注意**: 形式は推奨であり強制ではない。ユーザーは任意の文字列を設定可能。

## 設定の読み取り方法

### AI-DLCプロンプトでの参照

**責務**: AIがコミット時に aidlc.toml から設定を読み取る

**参照タイミング**: Gitコミット作成時

**ロジック**（AIが実行）:
1. `docs/aidlc.toml` を読み込む
2. `[rules.commit]` セクションを探す
3. `ai_author` 値を取得
4. 値が存在しなければデフォルト値 `Claude <noreply@anthropic.com>` を使用

**実装箇所**: `prompts/package/prompts/common/rules.md` に参照ルールを記載し、各フェーズプロンプトがこのルールを継承する

## 設定ファイル構造

```toml
[rules.commit]
# コミット設定（v1.9.1で追加）
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"
```

## デフォルト値

| 設定項目 | デフォルト値 | 理由 |
|---------|-------------|------|
| ai_author | `Claude <noreply@anthropic.com>` | Anthropicの汎用的なAI名 |

## 使用箇所

1. **common/rules.md** - Gitコミットセクションで参照方法を記載
2. **各フェーズプロンプト** - コミット時に設定を参照（rules.md経由）

## 後方互換性

- TOML仕様では未知のセクションは無視される
- 古いバージョンのAI-DLCプロンプトは `[rules.commit]` セクションを認識しないが、エラーにはならない
- 既存プロジェクトは設定追加前と同じ動作を継続（デフォルト値使用）
