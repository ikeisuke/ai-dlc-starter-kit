# v2.3.6 リリース後の運用記録

## リリース情報

- **バージョン**: v2.3.6
- **リリース予定日**: 2026-04-20
- **リリース内容**: Operations Phase マージ前完結契約の強化、Inception progress 表記統一、Draft PR 時の GitHub Actions スキップ実装（Unit 001-004）
- **リリース種別**: Patch リリース（内部品質向上・運用コスト削減）

## 含まれる Unit（成果物）

| Unit | タイトル | 対応 Issue | 状態 |
|------|---------|----------|------|
| 001 | operations-release.md §7.6 固定スロット反映ステップ追加 | #583-A | 完了 |
| 002 | write-history.sh マージ後呼び出しガード + 04-completion.md 禁止記述 | #583-B | 完了 |
| 003 | Inception progress Part/ステップ命名統一 + CHANGELOG 集約 | #565, DR-002 | 完了 |
| 004 | Draft PR 時の GitHub Actions スキップ（二段ガード） | DR-004（サイクル追加要件） | 完了 |

## PR マージ時の自動クローズ対象

以下 Issue を PR 本文の Closes セクションで指定済み（PR マージで自動クローズ）:

- `Closes #583` (Unit 001 + Unit 002 で A/B 両サブタスクを完了)
- `Closes #565` (Unit 003)

**注意**: PR 番号は #584。マージ直前に Closes セクションの再確認（ステップ7.13）が必要。

## E2E 検証引き継ぎ

v2.3.5 Operations Phase で検証完了した `merge_method=ask` に続き、`branch_mode=ask` と `draft_pr=ask` の AskUserQuestion 自然発火検証が次サイクル以降で残課題。

| 場面 | 検証サイクル | 検証タイミング |
|------|------------|-------------|
| `merge_method=ask` | v2.3.5 で検証済み | - |
| `branch_mode=ask` | 次サイクル Inception | 01-setup.md §9-1 |
| `draft_pr=ask` | 次サイクル Inception | 05-completion.md §5d-1 |

詳細: `.aidlc/cycles/v2.3.5/operations/unit_006_e2e_handover.md`。

## Unit 004 完了条件フォローアップ

Unit 004 の完了条件 L23（専用テスト Draft PR での 2 段検証 + Ready 遷移確認）は「完了コミット後のフォローアップ」として扱う。cycle PR マージ後、または別途テスト Draft PR を用いて実施し、結果を `history/operations.md` または後続サイクルで記録する。

## 既知の問題・注意点

- DR-005 で確認された 3 層整合化課題（テンプレート 6 ステップ / fixture 5 ステップ / 判定仕様 5 checkpoint）は #586 として次サイクル以降にバックログ化済み

## リリース後の保守計画

- GitHub Release ノートは自動タグ付け（`.github/workflows/auto-tag.yml`）後に手動作成検討
- `bin/post-merge-sync.sh` / `post-merge-cleanup.sh`（worktree 環境）による main 同期・ブランチクリーンアップを PR マージ後に実施
- Unit 004 完了条件 L23 のフォローアップ（Draft→Ready 遷移の本番観測）を継続観察
- バックログ未対応項目（#586, #585, #582, #581, #573, #568, #554, #552, #545, #536, #492, #443, #442, #441, #440, #436, #405, #398, #304, #281, #31）は次サイクル以降で段階対応

## 次サイクルの計画

- 次バージョン番号候補: **v2.4.0**（#586 = 3 層整合化リファクタが minor リリース推奨のため）、または v2.3.7（scope 次第）
- 優先検討:
  - #586 Inception 3 層整合化（DR-005 で次サイクル送り）
  - #581 Operations 復帰判定 new_format 実装完成
  - #585 operations_progress_template.md 固定スロット追加

## 備考

- 本サイクルは Construction Phase 途中で Unit 004（Draft PR GitHub Actions スキップ）がユーザーからの直接要望で Intent 拡張された
- Unit 003 Phase 1 設計着手時に DR-005 構造問題を発見し、スコープを「Part ラベル修正 + CHANGELOG 集約」に縮小（DR-005）
