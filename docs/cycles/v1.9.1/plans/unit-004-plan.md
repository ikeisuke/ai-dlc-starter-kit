# Unit 004 計画: Co-Authored-By設定の柔軟化

## 概要

コミットメッセージの Co-Authored-By 値を aidlc.toml で設定可能にし、ユーザーが任意のAIツール名やメールアドレスを指定できるようにする。

## 変更対象ファイル

### 変更

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/aidlc.toml.template` | `[rules.commit].ai_author` 設定を追加 |
| `prompts/package/prompts/common/rules.md` | Co-Authored-By の参照方法を追加 |
| `prompts/setup-prompt.md` | マイグレーションセクションに設定追加を案内 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - 設定値の構造と読み取り方法を定義
   - デフォルト値とフォールバック動作を明確化

2. **論理設計**
   - 設定の読み取りロジック
   - 各プロンプトでの参照方法

### Phase 2: 実装

1. **aidlc.toml.template の修正**
   - `[rules.commit]` セクションを追加
   - `ai_author` 設定を追加（コメント付き説明）
   - デフォルト値: `Claude <noreply@anthropic.com>`

2. **rules.md の修正**
   - Gitコミット時のCo-Authored-Byルールを追加
   - 設定値の参照方法を記載

3. **setup-prompt.md の修正**
   - マイグレーションセクションに `[rules.commit]` の追加を案内

## 完了条件チェックリスト

- [x] aidlc.toml に [rules.commit].ai_author 設定が追加されている
- [x] 各フェーズプロンプトで設定を参照するよう修正されている
- [x] デフォルト値（Claude <noreply@anthropic.com>）が定義されている
- [x] setup-prompt.md のマイグレーションセクションに追加されている

## 技術的考慮事項

- 設定形式: `ai_author = "ツール名 <email>"`
- デフォルト値: `Claude <noreply@anthropic.com>`
- 未設定時はデフォルト値を使用
- 任意の文字列が設定可能（バリデーションなし）
- 既存プロジェクトは設定がなくてもデフォルト値で動作する
