# 既存コード分析 - v1.18.0

## 1. セミオートモード関連（#164）

### 承認ポイント一覧

全フェーズにおけるユーザー承認ポイントを洗い出し、自動化可能性を分類した。

#### Inception Phase

| ステップ | 承認項目 | セミオートでの扱い |
|----------|---------|------------------|
| セットアップ | バージョン確認 | 自動判定可 |
| ステップ7 | ブランチ作成方式 | 設定ベースで自動判定可 |
| ステップ12 | Issue対応確認 | 自動判定可 |
| ステップ13 | バックログ確認 | 自動判定可 |
| ステップ1 | Intent計画承認 | AIレビュー合格で自動承認 |
| ステップ3 | ユーザーストーリー承認 | AIレビュー合格で自動承認 |
| ステップ4 | Unit定義承認 | AIレビュー合格で自動承認 |
| 完了時 | ドラフトPR作成 | 自動実行可 |
| 完了時 | コンテキストリセット | 継続実行フラグで制御 |

#### Construction Phase

| ステップ | 承認項目 | セミオートでの扱い |
|----------|---------|------------------|
| ステップ4 | Unit選択 | 優先度順で自動選択 |
| ステップ5 | 計画承認 | AIレビュー合格で自動承認 |
| ステップ6 | Unitブランチ作成 | 設定ベースで自動判定可 |
| Phase 1 ステップ3 | 設計レビュー承認 | AIレビュー合格で自動承認 |
| Phase 2 ステップ4 | コードレビュー | AIレビュー合格で自動承認 |
| Phase 2 ステップ6 | 統合レビュー承認 | AIレビュー合格で自動承認 |
| Unit完了 | 完了条件チェック | 自動検証可 |
| 完了時 | コンテキストリセット | 継続実行フラグで制御 |

#### Operations Phase

| ステップ | 承認項目 | セミオートでの扱い |
|----------|---------|------------------|
| ステップ1-4 | デプロイ・CI/CD等の計画承認 | AIレビュー合格で自動承認 |
| ステップ6.6 | PR Ready化 | 自動実行可 |
| ステップ6.7 | PRマージ | 自動実行可 |
| 完了時 | コンテキストリセット | 継続実行フラグで制御 |

### 設定ファイル構造

`docs/aidlc.toml` の `[rules]` セクションに新規セクション追加が必要:

```toml
[rules.semi_auto]
enabled = false  # デフォルト無効（オプトイン）
```

### レビューフロー構造

`review-flow.md` のフロー:
1. mode確認 → 2. レビュー種別決定 → 3. Tools確認 → 4. 反復レビュー → 5. 判定

セミオートモードでは、ステップ5の「ユーザーレビューフロー」をスキップし、AIレビュー合格で自動承認に変更。

### フェーズ遷移

各フェーズ完了時に「コンテキストリセット提示」がある。セミオートモードではリセット提示をスキップし、次フェーズへ自動遷移。

---

## 2. レビューサマリ改善（#247）

### 問題箇所

`prompts/package/prompts/common/review-flow.md` の指摘一覧テーブルフォーマット:

```markdown
| # | 重要度 | 内容 | 対応 |
```

- 「内容」列: プレースホルダ `[指摘内容]` のみで、具体的コンテキスト（どのファイルの何が問題か）の記述ガイダンスが不足
- 「対応」列: 修正の詳細が自由記述で統一されていない

### 修正対象

1. `prompts/package/prompts/common/review-flow.md` - フォーマット定義の拡張
2. `docs/aidlc/templates/review_summary_template.md` - テンプレートの詳細化

---

## 3. Issueクローズタイミング（#249）

### 現在の動作

- `prompts/package/prompts/construction.md` のUnit完了時必須作業でIssueステータスを `waiting-for-review` に更新
- `issue-ops.sh set-status` で実行

### 問題

PRマージ前にIssueが完了扱いになる。マージ前のリバート・追加修正時にIssueの整合性が崩れる。

### 修正方針

- Construction PhaseのUnit完了時のIssueクローズ処理を削除
- GitHubの `Closes #XX` 構文によるPRマージ時自動クローズに統一（Operations Phaseで既に正しく実装済み）

### 修正対象

- `prompts/package/prompts/construction.md` - Unit完了時のIssueステータス更新を削除

---

## 4. issue-ops.sh 改善（#250）

### 現在の実装

- `parse_gh_error()` でエラー理由を分類（not-found, auth-error, unknown）
- ラベル付与は `gh issue edit --add-label` で実行

### 問題

ラベルが存在しない場合のエラーハンドリングが不完全。「Issue見つからず」と「ラベル見つからず」が区別されない。

### 修正方針

- `label-not-found` エラー理由を追加
- ラベル自動作成機能（`gh label create`）またはエラーメッセージ改善

### 修正対象

- `prompts/package/bin/issue-ops.sh` - エラーハンドリング改善

---

## 5. squash-unit.sh 修正（#251）

### 現在の実装

- 2件以上のコミット: `git reset --soft "$base"` してから新規コミット
- retroactiveモード: `git rebase` ベース

### 問題

ルートコミット（initial commit）が squash 対象の場合、`git reset --soft` が失敗する。`HEAD^` が存在しない状態への対応がない。

### 修正方針

- ルートコミット検出ロジックを追加
- ルートコミット時は `git rebase --root` へ分岐

### 修正対象

- `prompts/package/bin/squash-unit.sh` - ルートコミット対応

---

## 6. resolve-starter-kit-path.sh 修正（#252）

### 現在の実装

スクリプトは**未実装**（新規作成が必要）。

### 問題

メタ開発モードで、スクリプトの実行位置（`docs/aidlc/bin/` vs `prompts/package/bin/`）によりスターターキットパスの解決が正しく行われない。

### 修正方針

- `$BASH_SOURCE[0]` でスクリプト位置を判定
- パスに `prompts/package/bin` が含まれるかで分岐
- 新規スクリプト作成

### 修正対象

- `prompts/package/bin/resolve-starter-kit-path.sh` - 新規作成
