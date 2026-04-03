# 論理設計: Codex PRレビューコメントリアクション検出追加

## 概要

`.aidlc/rules.md` のc判定フローにReview Commentリアクション検出ステップ（c-1b）を新設し、c-1の後・c-2の前に配置する。c-1のレビューラウンド情報を使ってReview Commentをフィルタする。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

パイプライン・フォールバックパターン。c-1 → c-1b（新規）→ c-2 → c-3 → c-4 の順に評価し、承認が得られた時点で後続をスキップ。各ステップの失敗は独立してフォールバック。

## コンポーネント構成

### 修正後のc判定フロー

```text
c-1: @codex review Issue Comment検索（既存・変更なし）
c-1b: Review Commentリアクション検出（新規）
  ├── 入力: 手順2取得済みReview Comments + c-1の created_at（ラウンド境界）
  ├── approved → 完了（c-2〜c-4スキップ）
  └── fallback → c-2へ（none/error いずれもc-2にフォールバック）
c-2: Issue Commentリアクション取得（既存・変更なし）
c-3: リアクション判定（既存・変更なし）
c-4: Issue Comment承認判定（既存・変更なし）
```

## 処理フロー: c-1b Review Commentリアクション検出

### 入力インターフェース

| 入力 | 型 | ソース |
|------|-----|--------|
| review_comments_data | list | 手順2で取得済みのPR Review Comments全件 |
| latest_review_round_created_at | datetime | c-1で特定した最新`@codex review`コメントの`created_at` |

**前提条件**: c-1でコメントIDが取得できた場合のみc-1bを実行。c-1がnull/空の場合はc判定全体がスキップされるため、c-1bには到達しない。

### 出力インターフェース

| 出力 | 型 | 説明 |
|------|-----|------|
| result | enum(approved, fallback) | approved: 承認済み / fallback: c-2に進む |

### c-1b-1: Codexボットコメント特定

手順2で取得済みのPR Review Comments一覧から、以下の条件でフィルタ:

1. `user.login == "chatgpt-codex-connector[bot]"`（Codexボットアカウント）
2. `created_at >= latest_review_round_created_at`（c-1のレビューラウンド境界）

CodexボットのReview Commentが0件の場合: c-1bをスキップし、c-2へ。

1件以上の場合、対象コメント全件のIDを取得。

### c-1b-2: リアクション取得

対象コメント全件のIDに対してリアクションを取得・集約:

```bash
gh api --paginate repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions \
  --jq '[.[] | select(.user.login == "chatgpt-codex-connector[bot]")]' \
  | jq -s 'add | map({content: .content})'
```

上記を対象コメント全件に対して実行し、リアクションを集約する。個別コメントの取得失敗はスキップして残りで続行。全件失敗: 「⚠ Review Commentリアクション取得に失敗しました。Issue Commentベースの判定に進みます」と表示し、c-2へ

### c-1b-3: リアクション判定

c-3と同様のパターン:
- いずれかのコメントに `+1` リアクションが存在 → 「✓ Codex PRレビュー: 承認済み（Review Comment👍）」と表示。c-2〜c-4をスキップ
- `eyes` リアクションのみ → c-2へ（判定保留）
- Codexボットからのリアクションなし → c-2へ

## 具体的な変更差分設計

### 挿入位置

既存の `c-2.` の直前（c-1の注記の後）に `c-1b.` セクションを挿入する。

### 既存ステップへの影響

- c-1: 変更なし
- c-2: 変更なし（c-1bからのフォールバック先として機能）
- c-3: 変更なし（c-1bで承認の場合は到達しない）
- c-4: 変更なし

### 末尾のエラーハンドリング注記更新

現在:
> c-2（リアクション取得）およびc-4（コメント承認判定）の失敗は補助判定の失敗であり...

修正後:
> c-1b（Review Commentリアクション取得）、c-2（Issue Commentリアクション取得）、およびc-4（コメント承認判定）の失敗は補助判定の失敗であり...

現在:
> c-2とc-4の両方が失敗した場合は...

修正後:
> c-1b、c-2、c-4のすべてが失敗した場合は...

## 実装上の注意事項

- 既存のc-1〜c-4のテキストは変更しない（c-1b挿入と末尾注記更新のみ）
- c-1bの追加API呼び出しは対象コメント全件に対する `pulls/comments/{comment_id}/reactions` のみ（Review Comments一覧は手順2で取得済み）
- c-1bはリアクション検出のみを責務とする。Review Comment本文の承認パターン検出はスコープ外（c-4の責務と重複するため）

## 不明点と質問（設計中に記録）

（なし）
