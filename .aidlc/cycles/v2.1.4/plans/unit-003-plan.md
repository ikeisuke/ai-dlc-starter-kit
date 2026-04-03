# Unit 003: Codex PRレビューコメントリアクション検出追加 - 計画

## 概要

PRマージ前レビュー確認のCodex PRレビュー状態判定（c判定フロー）に、Pull Request Review Commentへのリアクション検出を追加する。GitHub REST APIのReactions APIはPull Request Review本体ではなくReview Comment（行コメント等）に対して提供されているため、検出対象をReview Commentのリアクションとする。

## 変更対象ファイル

- `.aidlc/rules.md` - PRマージ前レビューコメント確認セクションのc判定フローにReview Commentリアクション検出ステップを追加し、関連する遷移先・エラーハンドリング注記を更新

## 実装計画

### 問題分析

現在のc判定フローは以下の構成:
- c-1: `@codex review` を含むIssue Commentを検索（全件データを保持）
- c-2: そのIssue Commentのリアクションを取得（Codexボットからのリアクション）
- c-3: リアクション判定（thumbs up = 承認）
- c-4: Issue Comment承認判定（c-3で未承認の場合）

手順2で `pulls/{PR番号}/comments` によりPR Review Commentsは既に全件取得されている。しかしCodexボットのReview Commentへのリアクションは検出対象外。

### 修正方針

手順2で取得済みのPR Review CommentsからCodexボットのコメント候補を特定し、必要なコメントIDに対してのみリアクションを追加取得する構造とする:

1. **新規ステップ追加（c-1bとしてc-1の後・c-2の前に挿入）**: 手順2で取得済みのPR Review Comments一覧からCodexボットアカウントのコメントをc-1のレビューラウンド境界でフィルタし、対象コメント全件のIDを取得
2. **リアクション取得**: 対象コメント全件に対して `gh api repos/{owner}/{repo}/pulls/comments/{comment_id}/reactions` でリアクションを取得・集約
3. **判定優先順**: Review Commentリアクション → Issue Commentリアクション(c-2) → コメント本文(c-4)
4. **エラーハンドリング分離**:
   - Review Comments一覧取得失敗: 既存の手順2の手動確認フローに従う（既存ルール）
   - Review Commentリアクション取得失敗: c判定内フォールバック（c-2以降に進む）

### 具体的な変更

- c判定フロー内に新しいサブステップを挿入（既存c-1〜c-4の前にReview Comment検出ステップを追加）
- 手順2の取得済みデータを活用するため、新ステップは追加のAPI呼び出し（リアクション取得のみ）に限定
- c-3/c-4の遷移条件を更新（新ステップからの遷移パスを追加）
- 末尾の「c-2とc-4の失敗時」注記を新ステップの失敗ケースも含めて更新

## 完了条件チェックリスト

- [x] `.aidlc/rules.md`のPRマージ前レビューコメント確認セクションに、Pull Request Review Commentリアクション検出ステップが追加されている
- [x] 既存のIssue Commentベースの検出（c-2, c-4）が変更されていない
- [x] API失敗時のフォールバックが定義されている（一覧取得失敗は手順2の既存フロー、リアクション取得失敗はc判定内フォールバック）
- [x] 判定優先順が明記されている
- [x] c判定内の参照番号・遷移先・エラーハンドリング注記が新ステップ追加後の構造に合わせて更新されている
