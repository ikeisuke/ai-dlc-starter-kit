# v2.3.5 リリース後の運用記録

## リリース情報

- **バージョン**: v2.3.5
- **リリース予定日**: 2026-04-18
- **リリース内容**: Operations/Inception フェーズの修正と運用品質改善（Unit 001-006）
- **リリース種別**: Patch リリース（バグ修正中心）

## 含まれる Unit（成果物）

| Unit | タイトル | 対応 Issue | 状態 |
|------|---------|----------|------|
| 001 | Operations 復帰判定の進捗源移行 | #579 | 完了 |
| 002 | リモート同期チェックの squash 後 divergence 対応 | #574 (1)(2) | 完了 |
| 003 | merge-pr `--skip-checks` オプション追加 | #575 | 完了 |
| 004 | Construction squash 後 force-push 案内追加 | #574 (3) | 完了 |
| 005 | config.toml.template の ai_author 既定値空文字化 | #577 | 完了 |
| 006 | 設定保存フローの暗黙書き込み防止 | #578 | 完了 |
| 007 | suggest-permissions acknowledged findings | #576 | 取り下げ（`ikeisuke/claude-skills#26` へ移送） |

## PR マージ時の自動クローズ対象

以下 Issue を PR 本文の Closes セクションで指定する:

- `Closes #579` (Unit 001)
- `Closes #574` (Unit 002 + 004 で完全対応)
- `Closes #575` (Unit 003)
- `Closes #577` (Unit 005)
- `Closes #578` (Unit 006)

`#576` は既にクローズ済み（Unit 007 取り下げ時にクローズ）。

## E2E 検証引き継ぎ

Unit 006 の `AskUserQuestion` 起動・デフォルト選択挙動は 3 場面で自然発火時に目視検証が必要:

| 場面 | 検証サイクル | 検証タイミング |
|------|------------|-------------|
| `merge_method=ask` | **v2.3.5 Operations Phase** | ステップ 7.13 PR マージ時 |
| `branch_mode=ask` | 次サイクル Inception | 01-setup.md §9-1 |
| `draft_pr=ask` | 次サイクル Inception | 05-completion.md §5d-1 |

詳細: `operations/unit_006_e2e_handover.md`、結果記録先: `history/operations.md`。

## 既知の問題・注意点

- なし（本サイクルで発覚した運用上の制限事項なし）

## リリース後の保守計画

- GitHub Release ノートは自動タグ付け（`.github/workflows/auto-tag.yml`）後に手動作成検討
- `bin/post-merge-sync.sh` による main 同期・ブランチクリーンアップを PR マージ後に実施
- `branch_mode` / `draft_pr` の E2E 検証は次サイクル（v2.4.x 相当）Inception Phase で実施
- バックログ未対応項目（#573, #568, #565, #554, #552, #545, #536, #492, #443, #442, #441, #440, #436, #405, #398, #304, #281, #31）は次サイクル以降で段階対応

## 次サイクルの計画

- 次バージョン番号: 未確定（v2.4.0 または v2.3.6）
- 優先検討: Unit 006 E2E 残件（`branch_mode` / `draft_pr`）、および未対応バックログの Inception 対象選定

## 備考

- 本サイクルは Inception バックトラック発生サイクル（Unit 001-004 着手後に Unit 005/006/007 追加）
- Unit 007 は「スキル本体が別リポジトリ」のため取り下げ（DR-006 参照）
