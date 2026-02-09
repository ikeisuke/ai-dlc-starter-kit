# Unit 002 計画: フィードバック送信機能オン/オフ設定

## 概要

`docs/aidlc.toml` に `[rules.feedback]` セクションを追加し、フィードバック送信機能のオン/オフを制御可能にする。`enabled = false` 時は導線全体をブロックしメッセージを表示する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup/templates/aidlc.toml.template` | `[rules.feedback]` セクション追加 |
| `prompts/package/prompts/AGENTS.md` | フィードバック送信セクションに設定読み込み・分岐ロジック追加 |
| `docs/aidlc.toml` | `[rules.feedback]` セクション追加（現プロジェクト設定） |

## 実装計画

### Phase 1: 設計

#### ステップ1: ドメインモデル設計

設定値の構造と振る舞いを定義：

- **設定キー**: `rules.feedback.enabled`
- **型**: boolean
- **デフォルト値**: `true`（明示的に `false` を設定した場合のみ無効化）
- **読み込み方法**: `read-config.sh rules.feedback.enabled --default "true"`
- **不正値時の挙動**: `true`（有効）にフォールバック

#### ステップ2: 論理設計

AGENTS.mdのフィードバック送信セクションの処理フロー：

1. 「AIDLCフィードバック」「aidlc feedback」と言われた場合
2. `read-config.sh` で `rules.feedback.enabled` を読み取り
3. **`true` の場合**: 既存のフィードバック送信フローを実行
4. **`false` の場合**: ブロックメッセージを表示して終了

#### ステップ3: 設計レビュー

設計内容のAIレビューと人間承認。

### Phase 2: 実装

#### ステップ4: コード生成

1. `prompts/setup/templates/aidlc.toml.template` に `[rules.feedback]` セクション追加
2. `prompts/package/prompts/AGENTS.md` のフィードバック送信セクションに分岐ロジック追加
3. `docs/aidlc.toml` に `[rules.feedback]` セクション追加

#### ステップ5: テスト生成

- `read-config.sh` の読み取り確認（手動検証）
- `enabled = true`（デフォルト）でフィードバック導線が表示されること
- `enabled = false` でブロックメッセージが表示されること

#### ステップ6: 統合とレビュー

AIレビュー → 人間承認。

## 完了条件チェックリスト

- [ ] `docs/aidlc.toml`（テンプレート: `prompts/setup/templates/aidlc.toml.template`）に `[rules.feedback]` セクションを追加
- [ ] `prompts/package/prompts/AGENTS.md` のフィードバック送信セクションに設定読み込みと分岐ロジックを追加
- [ ] `enabled = false` 時に導線全体をブロックし、メッセージを表示
