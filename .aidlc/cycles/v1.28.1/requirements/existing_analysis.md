# 既存コードベース分析

## ディレクトリ構造・ファイル構成

今回のスコープに関連するファイル:

```
prompts/package/
├── prompts/
│   ├── construction.md          # Construction Phase プロンプト
│   ├── operations.md            # Operations Phase プロンプト
│   └── operations-release.md    # Operations Release プロンプト
├── templates/
│   └── unit_definition_template.md  # Unit定義テンプレート
docs/cycles/
└── rules.md                     # プロジェクト固有ルール（Codex PRレビュー判定含む）
```

**注意**: `docs/aidlc/` は `prompts/package/` の rsync コピー。変更は `prompts/package/` に対して行う。

## アーキテクチャ・パターン

### Codex PRレビュー承認判定（#408関連）

`docs/cycles/rules.md` の「PRマージ前レビューコメント確認」セクション（Line 242-323）に定義。

**判定フロー**:
1. **a判定**: CHANGES_REQUESTED判定（レビュアーごとの最新レビュー状態）
2. **b判定**: 未返信コメント判定（`in_reply_to_id` がnullで返信なし）
3. **c判定**: 絵文字リアクション判定（3サブステップ）
   - **c-1**: `@codex review` を含むIssue Commentの最新1件のIDを特定
   - **c-2**: そのコメントのリアクションからCodexボットアカウントのものをフィルタ
   - **c-3**: `+1`（👍）存在→承認、`eyes`（👀）のみ→進行中、なし→スキップ

**Codexボットアカウント定数**: `chatgpt-codex-connector[bot]`（Line 230）

**現在の制限**: c判定はリアクションのみ検出。Codexボットが独立したIssue Comment（例: `Didn't find any major issues`）として投稿する承認パターンを検出できない。

### Unit実装状態管理（#406関連）

**有効値定義**: `construction.md` Line 238-254
- 現在の有効値: `未着手`, `進行中`, `完了`

**Unit選択ロジック**: `construction.md` Line 281-296
- `未着手` かつ依存完了 → 実行可能
- `進行中` → 優先的に継続

**進捗検証**: `operations.md` Line 194-247
- 全Unitの状態が `完了` であることを確認
- セミオートゲート: 全Unit完了→自動承認、未完了あり→フォールバック

**Unit定義テンプレート**: `unit_definition_template.md` Line 54-61
- `- **状態**: 未着手` がデフォルト値

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 言語 | Markdown（プロンプト）、Bash（スクリプト） | prompts/package/ |
| フレームワーク | AI-DLC（独自開発方法論） | docs/aidlc.toml |
| 主要ツール | gh CLI、codex CLI、dasel | docs/aidlc/bin/ |

## 依存関係

### #408の変更影響マップ
- `docs/cycles/rules.md` c判定ロジック → c-3の後にc-4（Issue Comment判定）を追加
- 既存のa/b判定、c-1/c-2/c-3は変更なし

### #406の変更影響マップ
| 変更箇所 | ファイル | 影響 |
|----------|---------|------|
| 有効値定義 | `prompts/package/prompts/construction.md` | 「取り下げ」追加 |
| Unit選択ロジック | `prompts/package/prompts/construction.md` | 「取り下げ」を除外 |
| 依存関係判定 | `prompts/package/prompts/construction.md` | 「取り下げ」を完了扱い |
| 進捗検証 | `prompts/package/prompts/operations.md` | 「取り下げ」を完了扱い |
| セミオートゲート | `prompts/package/prompts/operations.md` | 判定条件更新 |
| テンプレート | `prompts/package/templates/unit_definition_template.md` | 有効値リスト更新 |

## 特記事項

- `rules.md` はプロジェクト固有ルールであり `prompts/package/` 配下ではないため、直接編集可能
- `construction.md` と `operations.md` は `prompts/package/prompts/` 配下のため、メタ開発ルールに従い `prompts/package/` を編集する
- 依存関係判定で「取り下げ」Unitをどう扱うかは設計判断が必要（完了扱いとして依存を解決するか、依存先Unitも取り下げが必要か）
