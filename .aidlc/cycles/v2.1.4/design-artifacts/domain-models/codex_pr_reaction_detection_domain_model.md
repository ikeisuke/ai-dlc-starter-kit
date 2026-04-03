# ドメインモデル: Codex PRレビューコメントリアクション検出追加

## 概要

c判定フローにReview Commentリアクション検出（c-1b）を追加し、c-1の後・c-2の前に配置する。c-1のレビューラウンド情報を使用してReview Commentをフィルタする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### c判定フロー（既存拡張）

- **責務**: Codex PRレビューの承認状態をリアクション・コメントから検出
- **属性**:
  - review_comment_reaction_result: enum(approved, fallback) - c-1b Review Commentリアクション検出結果（none/errorはfallbackに集約）
  - issue_comment_reaction_result: enum(approved, reviewing, none, error) - 既存c-2/c-3結果
  - issue_comment_approval_result: enum(approved, none, error) - 既存c-4結果
- **振る舞い**:
  - c-1（既存）→ c-1b（新規: Review Commentリアクション検出）→ c-2/c-3（既存）→ c-4（既存）の順で判定

### Review Commentリアクション検出（c-1b、新規ステップ）

- **責務**: 手順2で取得済みのPR Review CommentsからCodexボットのコメントを特定し、レビューラウンド境界でフィルタした上でリアクションを取得・判定
- **属性**:
  - codex_review_comments: list - Codexボットアカウントのコメント一覧（手順2取得済みデータ + ラウンド境界フィルタ）
  - target_comment_ids: list[integer] - 対象コメントID一覧
  - aggregated_reactions: list - 全対象コメントのリアクション集約結果
- **入力**: 手順2取得済みReview Comments + c-1のcreated_at（レビューラウンド境界）
- **出力**: enum(approved, fallback)
- **振る舞い**:
  - フィルタ: `user.login == "chatgpt-codex-connector[bot]"` かつ `created_at >= c-1のcreated_at`
  - リアクション取得: 対象コメント全件に対して `pulls/comments/{comment_id}/reactions` API呼び出し・集約。個別失敗はスキップして残りで続行、全件失敗でfallback
  - 判定: いずれかのコメントに `+1` リアクション存在 → approved、それ以外 → fallback（c-2へ）
- **制約**:
  - Review Comments一覧取得は手順2の責務（新規API呼び出しなし）
  - リアクション検出のみを責務とする（Review Comment本文の承認パターン検出はスコープ外）
  - c-1でコメントIDが取得できた場合のみ実行（c-1がnull/空の場合はc判定全体スキップ）

## 値オブジェクト（Value Object）

### リアクション判定結果

- **属性**:
  - status: enum(approved, reviewing, none)
  - source: string - 判定元（review_comment_reaction / issue_comment_reaction / issue_comment_body）
  - display_message: string - 表示メッセージ
- **不変性**: 判定ロジックの入力に対して一意に決まる

## 集約（Aggregate）

### c判定フロー全体

- **集約ルート**: Codex PRレビュー状態判定
- **含まれる要素**: c-1（Issue Comment検索）→ c-1b（Review Commentリアクション検出、新規）→ c-2/c-3（Issue Commentリアクション）→ c-4（Issue Comment承認判定）
- **境界**: c-1bはc-1の後・c-2の前に位置し、c-1のレビューラウンド情報を使用してフィルタする。承認判定が得られた時点で後続ステップをスキップ
- **不変条件**: 判定優先順は Review Commentリアクション(c-1b) → Issue Commentリアクション(c-2/c-3) → コメント本文(c-4)。各ステップの失敗は独立しており、他のステップに影響しない。レビューラウンド境界はc-1の`created_at`で統一

## ユビキタス言語

- **Review Comment**: Pull Request上の行コメント・差分コメント（`pulls/{PR}/comments` API）
- **Issue Comment**: PR上の一般コメント（`issues/{PR}/comments` API）
- **c判定フロー**: Codex PRレビューの承認状態を検出するフロー全体（c-1 → c-1b → c-2 → c-3 → c-4）
- **レビューラウンド境界**: c-1で取得した最新`@codex review`コメントの`created_at`。これ以降のコメント/リアクションのみを判定対象とする
- **補助判定**: c判定はa/b判定（主判定）を補完する補助的な判定

## 不明点と質問（設計中に記録）

（なし）
