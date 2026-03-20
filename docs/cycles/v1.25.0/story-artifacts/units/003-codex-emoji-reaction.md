# Unit: Codex PRレビュー絵文字リアクション検出

## 概要
PRマージ前ゲートにCodex PRレビューの絵文字リアクション（👍/👀）検出を追加し、レビュー完了の自動判定精度を向上させる。

## 含まれるユーザーストーリー
- ストーリー 4: Codex PRレビュー絵文字リアクション検出

## 責務
- `@codex review` コメントの特定（本文検索）
- コメントへのリアクション取得（GitHub REST API）
- リアクション判定ルール実装（Codexボットアカウントからのリアクションのみ有効、👀優先）
- PRマージ前ゲート（rules.md 6.6.7相当）への統合
- API失敗時のフォールバック（既存コメントベース判定）

## 境界
- 👍/👀以外のリアクション判定は含まない
- Codexボット以外のユーザーからのリアクションは無視
- 既存のCHANGES_REQUESTED判定・未返信コメント判定は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub REST API（`gh api repos/{owner}/{repo}/issues/comments/{id}/reactions`）
- Codexボットアカウントの `login` 識別子（Construction Phase の設計時に実際のGitHub Appの `login` を確認し、`rules.md` にハードコードする。将来的に設定化が必要な場合はバックログに登録）

## 非機能要件（NFR）
- **パフォーマンス**: API呼び出し回数を最小限にする（@codex reviewコメントの最新1件のみ対象）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: API失敗時は既存判定にフォールバック

## 技術的考慮事項
- 変更対象: `docs/cycles/rules.md`（PRマージ前ゲートセクション）、`prompts/package/prompts/operations-release.md`
- Codexボットアカウント名は実際のGitHub Appの `login` を事前確認する必要あり

## 関連Issue
- #336

## 実装優先度
Medium

## 見積もり
S-M（2ポイント）— 主要タスク: rules.md ゲートロジック拡張、operations-release.md 統合（計2ファイル変更）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-20
- **完了日**: 2026-03-20
- **担当**: -
