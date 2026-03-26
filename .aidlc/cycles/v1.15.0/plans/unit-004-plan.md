# Unit 004 計画: コミット処理統合

## 概要

分散しているコミット関連ロジックを `prompts/package/prompts/common/commit-flow.md` に集約し、各フェーズプロンプトと `review-flow.md` からの参照を統一する。squash機能もこの統合フローに組み込む。

## 現状分析

コミット関連ロジックが以下5箇所に分散している：

| ファイル | 内容 | 行数（概算） |
|---------|------|-------------|
| `common/review-flow.md` | レビュー前/後コミット手順（4箇所） | ~50行 |
| `common/rules.md` | コミットタイミング、Co-Authored-By設定 | ~75行 |
| `construction.md` | squashフロー、Unit完了コミット、確認チェックリスト | ~170行 |
| `operations.md` | Operations Phase完了コミット | ~15行 |
| `inception.md` | Inception Phase完了コミット | ~15行 |

## 変更対象ファイル

### 新規作成

| ファイル | 説明 |
|---------|------|
| `prompts/package/prompts/common/commit-flow.md` | コミット処理統合モジュール |

### 変更

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/common/review-flow.md` | インラインコミット手順を `commit-flow.md` への参照に置換 |
| `prompts/package/prompts/common/rules.md` | コミットタイミング・Co-Authored-By セクションを `commit-flow.md` への参照に置換 |
| `prompts/package/prompts/construction.md` | squashフロー・Unit完了コミットセクションを `commit-flow.md` への参照に置換 |
| `prompts/package/prompts/operations.md` | 完了コミットセクションを `commit-flow.md` への参照に置換 |
| `prompts/package/prompts/inception.md` | 完了コミットセクションを `commit-flow.md` への参照に置換 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: コミット処理の構成要素（コミットタイプ、メッセージフォーマット、実行手順）の構造定義
2. **論理設計**: `commit-flow.md` のセクション構成、参照パターン、各既存ファイルとの連携インターフェース設計
3. **設計レビュー**: AIレビュー + ユーザー承認

### Phase 2: 実装

4. **コード生成**: `commit-flow.md` 作成 + 既存ファイルの参照統一
5. **テスト生成**: 該当なし（プロンプトファイルのため。整合性チェックで代替）
6. **統合とレビュー**: 全ファイルの参照整合性確認 + AIレビュー + ユーザー承認

## `commit-flow.md` の想定構成

責務を「ポリシー層」と「実行フロー層」に明確分離する：

```
【ポリシー層】（いつ・何を・どのフォーマットで）
1. コミットポリシー
   1.1 コミットタイミング（必須4ポイント）
   1.2 コミットメッセージフォーマット一覧（全パターンの定義）
   1.3 Co-Authored-By 設定と検出フロー

【実行フロー層】（具体的な手順・コマンド）
2. レビューコミット手順
   2.1 レビュー前コミット手順
   2.2 レビュー反映コミット手順

3. フェーズ完了コミット手順
   3.1 Inception Phase完了コミット
   3.2 Unit完了コミット（標準パス）
   3.3 Operations Phase完了コミット

4. Squash統合フロー（オプション）
   4.1 設定確認・VCSタイプ判定
   4.2 中間コミット作成
   4.3 ベースコミット検出・Squash実行
   4.4 jjブックマーク更新・エラーリカバリ

5. コミット前確認チェックリスト
```

## 設計上の重要な判断ポイント（設計フェーズで確定必須）

### 1. 参照パターン（確定方針: 案B - セクション参照方式）

各フェーズプロンプトは `commit-flow.md` の特定セクションを名前で参照する。

- 理由: 冒頭一括読み込み（案A）はコンテキスト肥大化を招く。セクション参照（案B）なら必要な手順のみをAIが参照でき、既存の `review-flow.md` 参照パターンとも一貫する
- 参照形式: `「commit-flow.md」の「セクション名」手順に従う`
- **依存方向の制約**: `commit-flow.md` からフェーズプロンプトへの逆参照は禁止（DAG維持）

### 2. rules.md との境界

- Co-Authored-By ロジック: `commit-flow.md` に完全移動
- コミットタイミングルール: `commit-flow.md` に完全移動
- `rules.md` には `commit-flow.md` への参照のみを残す

### 3. review-flow.md の粒度

- コミット手順ブロック（`git status --porcelain` → `git add -A` → `git commit`）を丸ごと抽出
- フロー制御（「変更がある場合のみ」の条件分岐）は `commit-flow.md` 側に含める

### 4. プレースホルダの統一

既存のプレースホルダ命名を標準化する：

| 統一名 | 現状の表記ゆれ | 意味 |
|-------|-------------|------|
| `{{CYCLE}}` | `{{CYCLE}}` | サイクル番号（既存統一済み） |
| `{NNN}` | `{N}`, `{NNN}`, `{NN}` | Unit番号（3桁ゼロパディング） |
| `{UNIT_NAME}` | `{Unit名}`, `[unit_name]` | Unit名 |
| `{ARTIFACT_NAME}` | `{成果物名}` | 成果物名 |
| `{AI_AUTHOR}` | `{ai_author}`, `{検出...値}` | Co-Authored-By値 |

## 完了条件チェックリスト

- [ ] コミット関連処理の `prompts/package/prompts/common/` への集約
- [ ] 各フェーズプロンプトからのコミット処理参照の統一
- [ ] squash機能の統合フローへの組み込み
