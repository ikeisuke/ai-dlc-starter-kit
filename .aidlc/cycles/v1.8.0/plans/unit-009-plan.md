# Unit 009: フィードバック手段追加 - 実行計画

## 概要

スターターキット利用者がフィードバックを伝える方法を整備する。
**特にAI作業中に「AIDLCフィードバック」と言うだけでAIが案内を出せる仕組みを作る。**

## 現状分析

### 既存のIssueテンプレート

- `.github/ISSUE_TEMPLATE/backlog.yml` - バックログ用
- `.github/ISSUE_TEMPLATE/bug.yml` - バグ報告用
- `.github/ISSUE_TEMPLATE/feature.yml` - 機能要望用

### AGENTS.mdの簡略指示

既に「インセプション進めて」「AIDLCアップデート」などの簡略指示が定義されている。
同様のパターンで「AIDLCフィードバック」を追加する。

### README.mdの現状

既に「📮 フィードバック」セクションが存在し、GitHub Issuesへの案内がある。

## 作成・変更するファイル

### 1. `prompts/package/prompts/AGENTS.md`（修正）

フェーズ簡略指示テーブルに「AIDLCフィードバック」を追加：

```markdown
| 「AIDLCフィードバック」「aidlc feedback」 | フィードバック送信案内 |
```

フィードバック送信時のAI動作を定義するセクションを追加。

### 2. `.github/ISSUE_TEMPLATE/feedback.yml`（新規作成）

フィードバック専用のIssueテンプレートを作成。

### 3. `README.md`（修正）

「📮 フィードバック」セクションをより充実させる。

## AI動作仕様

「AIDLCフィードバック」と言われた際のAI動作：

1. フィードバック内容をヒアリング
2. `gh issue create` でスターターキットリポジトリにIssueを作成
3. または手動作成用のリンクを案内

## 実行ステップ

### Phase 1: 設計（このUnitはドキュメント作成のため省略可）

- ドメインモデル設計: N/A（コード実装なし）
- 論理設計: N/A（コード実装なし）

### Phase 2: 実装

1. `prompts/package/prompts/AGENTS.md` に簡略指示とフィードバックセクション追加
2. `feedback.yml` Issueテンプレート作成
3. `README.md` フィードバックセクション更新
4. Markdownlint実行
5. コミット

## 完了条件

- [ ] AGENTS.mdに「AIDLCフィードバック」簡略指示が追加されている
- [ ] フィードバック用Issueテンプレートが作成されている
- [ ] README.mdにフィードバック手段が明記されている
- [ ] ビルド/リント成功
- [ ] Unit定義ファイルの実装状態が「完了」に更新されている
