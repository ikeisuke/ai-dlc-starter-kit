# Unit 002: jjサポート - 設定とドキュメント 実装記録

## 概要

jjサポートのための設定テンプレート修正とドキュメント改善を実装した。

## 実装内容

### 1. setup-prompt.md セクション7.2 の修正

**変更内容**: aidlc.tomlテンプレートに `[rules.jj]` セクションを追加

```toml
[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
```

**挿入位置**: `[rules.history]` の後、`[rules.custom]` の前

### 2. setup-prompt.md セクション7.4 の修正

**変更内容**: 既存プロジェクト向けマイグレーションスクリプトを追加

- `[rules.jj]` セクションが存在しない場合に自動追加
- 既存の `[backlog]` マイグレーションと同様のパターン

### 3. jj-support.md の修正

**追加セクション**: 「gitとjjの考え方の違い」

**追加内容**:
- ワーキングコピーの扱いの違い（テーブル形式）
- コミットタイミングの違い（フロー図）
- ブランチ vs ブックマークの概念（テーブル形式）
- フロー比較図（ASCII図）
- 実践的な違いの例

**挿入位置**: 「## 前提条件」の後、「## jjの特徴と利点」の前

## テスト結果

- markdownlint: 0 error(s)

## 変更ファイル一覧

| ファイル | 変更種別 |
|---------|---------|
| `prompts/setup-prompt.md` | 修正（セクション7.2, 7.4） |
| `prompts/package/guides/jj-support.md` | 修正（新セクション追加） |
| `docs/cycles/v1.7.2/design-artifacts/domain-models/unit002_domain_model.md` | 新規作成 |
| `docs/cycles/v1.7.2/design-artifacts/logical-designs/unit002_logical_design.md` | 新規作成 |
| `docs/cycles/v1.7.2/plans/unit002_plan.md` | 新規作成 |
| `docs/cycles/v1.7.2/construction/units/unit002_implementation.md` | 新規作成 |

## 備考

- `enabled=true` 時のプロンプト動作変更は別Unit/サイクルで対応予定
- 現時点ではユーザーが手動でjj-support.mdを参照してGitコマンドを読み替える
