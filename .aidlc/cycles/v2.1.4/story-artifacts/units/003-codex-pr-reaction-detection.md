# Unit: Codex PRレビューコメントリアクション検出追加

## 概要
PRマージ前レビュー確認のCodex PRレビュー状態判定（c判定フロー）に、Pull Request Review Commentへのリアクション検出を追加する。GitHub REST APIのReactions APIはPull Request Review本体ではなくReview Comment（行コメント等）に対して提供されているため、検出対象をReview Commentのリアクションとする。

## 含まれるユーザーストーリー
- ストーリー 3: Codex PRリアクション検出追加（#511）

## 責務
- `.aidlc/rules.md`のPRマージ前レビューコメント確認セクションに、Pull Request Review Commentリアクション検出ステップを追加

## 境界
- 既存のIssue Commentベースの検出（c-2, c-4）は変更しない
- Codexボットアカウント名の定数は変更しない
- Pull Request Review本体へのリアクションは対象外（REST APIで未サポート）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub REST API（`pulls/{PR}/comments` エンドポイント — Review Comments）
- GitHub REST API（`pulls/comments/{comment_id}/reactions` エンドポイント — Review Commentのリアクション）

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- Review Commentのリアクション取得: `gh api repos/{owner}/{repo}/pulls/{PR}/comments` → Codexボットのコメントを特定 → `gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions` でリアクション取得
- 判定優先順: Review Commentリアクション → Issue Commentリアクション(c-2) → コメント本文(c-4)
- API失敗時はc-2にフォールバック
- Review CommentがCodexボットの承認表現を含むかも合わせて判定

## 関連Issue
- #511

## 実装優先度
High

## 見積もり
中（rules.mdのc判定フロー改修、API呼び出し追加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
