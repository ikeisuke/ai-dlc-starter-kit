# ドメインモデル: Codex PRレビュー絵文字リアクション検出

## 概要

PRマージ前ゲートにおけるCodex PRレビューの絵文字リアクション検出ロジックのドメインモデル。既存のPRマージ前レビューコメント確認（rules.md 6.6.7相当）に「c. 絵文字リアクション判定」を追加し、Codexのリアクションベースの状態通知を検出する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### CodexReviewComment（Codexレビュートリガーコメント）

- **属性**:
  - comment_id: number - コメントID（GitHub REST API用）
  - body: string - コメント本文（`@codex review` を含む）
  - created_at: string - 作成日時
- **不変性**: コメントは作成後に変更されない
- **等価性**: comment_id で判定

### Reaction（リアクション）

- **属性**:
  - content: string - リアクション種別（`+1`, `eyes` 等）
  - user_login: string - リアクションしたユーザーの login
- **不変性**: リアクションは作成後に変更されない
- **等価性**: content + user_login で判定

### ReactionCheckResult（リアクション判定結果）

- **属性**:
  - status: "approved" | "reviewing" | "no_comment" | "no_reaction" | "api_error" - 判定状態
  - source_comment_id: number | null - 判定元のコメントID
  - message: string - ユーザー向けメッセージ
- **不変性**: 判定後に変更されない
- **等価性**: status で判定

## 定数

### Codexボットアカウント

- **login**: `chatgpt-codex-connector[bot]`（`rules.md` に定数として記載。将来のBot名変更時は定数を更新する）
- **未一致時フォールバック**: Codexボットからのリアクションが見つからない場合（login変更含む）、a/b判定のみで続行し警告を表示

### リアクション優先度テーブル

| リアクション | 意味 | 優先度 |
|-------------|------|--------|
| `+1` (👍) | レビューOK（承認） | 高（最終判定） |
| `eyes` (👀) | レビュー中 | 低（暫定判定） |

## 判定ロジック

### リアクション判定フロー

1. PRコメントから `@codex review` を含む最新コメントを取得
2. API失敗時 → `api_error` で終了（既存エラーテーブルに従い手動確認を誘導）
3. コメントが見つからない場合 → `no_comment` で終了（リアクション判定をスキップ）
4. コメントのリアクションを取得
5. API失敗時 → `api_error` で終了（警告表示し、a/b判定のみで続行）
6. Codexボットアカウントからのリアクションのみフィルタ
7. フィルタ結果が空 → `no_reaction` で終了
8. `+1` リアクションが存在 → `approved`（👍優先: 👍と👀の両方がある場合も `approved`）
9. `eyes` リアクションのみ存在 → `reviewing`

### 既存判定との統合

既存のPRマージ前レビューコメント確認（rules.md ステップ3）:
- a. CHANGES_REQUESTED判定（既存・変更なし）
- b. 未返信コメント判定（既存・変更なし）
- **c. 絵文字リアクション判定（新規追加）**

統合ルール:
- a/bの判定は変更しない
- cの結果は判定ステップ4の「未対応指摘あり/なし」の判定に追加情報として統合
- `reviewing` の場合、「Codexレビューが進行中です」と情報表示する
- `no_comment` / `no_reaction` の場合、既存のa/b判定結果のみで判定（フォールバック）
- `api_error` の場合、既存エラーハンドリングテーブル（rules.md）に従い警告表示し、a/b判定のみで続行

## ユビキタス言語

- **絵文字リアクション**: GitHub PRコメントに付与されるリアクション（👍, 👀等）
- **Codexボットアカウント**: `chatgpt-codex-connector[bot]`。CodexのGitHub App連携で使用される
- **フォールバック**: API失敗時やリアクション未検出時に、既存のコメントベース判定のみで続行すること
