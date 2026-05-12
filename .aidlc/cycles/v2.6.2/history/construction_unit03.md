# Construction Phase 履歴: Unit 03

## 2026-05-12T01:58:53+09:00

- **フェーズ**: Construction Phase
- **Unit**: 03-fix-squash712-history-integration（Operations §7.12.5 squash-712 と write-history operations-round の整合性）
- **ステップ**: Unit完了処理
- **実行内容**: Unit 003 完了 - Operations §7.12.5 squash-712 と write-history operations-round の整合性（A+B 併用）

## 採用案

A+B 併用（DR-009）:
- 案 A: write-history.sh `--mode operations-round` の auto-commit 化（`--no-commit` opt-out / 事前 staged ガード / 非 git 環境ガード）
- 案 B: operations-release.sh squash-712 への history dirty 検出 fail-fast ガード

## 主要な変更

1. `skills/aidlc/scripts/write-history.sh`
   - `NO_COMMIT` グローバル変数追加
   - `--no-commit` フラグ追加（help テキスト + 引数パース）
   - `_commit_operations_round_history()` 関数追加（git add + git commit + 環境ガード + index rollback）
   - main の append 完了後と dry-run 早期 exit 前に operations-round フック追加
2. `skills/aidlc/scripts/operations-release.sh`
   - `__squash_712_check_history_clean()` 関数追加（dirty 検出 + パストラバーサル拒否）
   - `cmd_squash_712()` Step 1 直後にガード呼び出し追加（`squash:failed:reason=dirty_history` exit 1）
3. `skills/aidlc/steps/operations/operations-release.md`
   - §7.12 完了条件に auto-commit 既定化と opt-out 注意を追記
   - §7.12.5 戻り値表に `squash:failed:reason=dirty_history` 行追加
4. テスト追加（合計 15 ケース、全 pass）
   - `tests/write-history-operations-round-commit.bats`（6 ケース）
   - `tests/operations-release-squash712-dirty-history.bats`（7 ケース、パストラバーサル拒否 2 ケース含む）
   - `tests/operations-release-squash712-integration.bats`（2 ケース）

## AI レビュー完了（対象タイミング: 統合とレビュー）

- 計画レビュー: codex Round 1 で HIGH/MEDIUM 各 1 件 → Round 2 で全対応確認
- 設計レビュー: codex Round 1 で HIGH 3 + MEDIUM 2 + LOW 1 → Round 3 で全解消確認
- コードレビュー: codex Round 1 で MEDIUM 1 + LOW 2 → Round 2 で対応確認、バックログ Issue #701 / #702 起票
- 統合レビュー: codex Round 1 で HIGH/MEDIUM/LOW すべて指摘なし、完了条件全達成

## 関連 Issue

- 解決: #677（致命的バグ / Operations §7.12.5 と write-history operations-round の整合性）
- バックログ起票: #701（cmd_squash_712 全体への --cycle バリデーション導入）
- バックログ起票: #702（write-history.sh パス解決処理の共通ヘルパ化 / refactor）
- 関連先行: #639（§7.12.5 導入起点）, #654（Construction Phase 側で同根問題を解決した先行事例）

## 決定事項

- DR-009: 採用案 A+B 併用を確定（auto-commit + fail-fast 二層防御）

---
