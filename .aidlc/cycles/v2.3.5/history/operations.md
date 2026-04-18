# Operations Phase 履歴

## 2026-04-18T09:52:37+09:00

- **フェーズ**: Operations Phase
- **ステップ**: リリース準備 7.1-7.4（バージョン確認・CHANGELOG・README・履歴記録）
- **実行内容**: v2.3.5 リリース準備を開始。7.1: version.txt/aidlc.toml/skills/aidlc,aidlc-setup の version を 2.3.4→2.3.5 に更新（bin/update-version.sh 成功）。7.2: CHANGELOG.md に Keep a Changelog 形式で v2.3.5 エントリ追加（Added: #575 / Fixed: #579 #574(1)(2) / Changed: #574(3) #577 #578 / Removed: Unit 007 #576）。7.3: README.md にバージョン直接参照なく更新不要。7.4: 本履歴記録作成。Unit 001-006 完了、Unit 007 取り下げ（ikeisuke/claude-skills#26 へ移送）。
- **成果物**:
  - `CHANGELOG.md`
  - `version.txt`
  - `.aidlc/config.toml`
  - `.aidlc/cycles/v2.3.5/operations/progress.md`
  - `.aidlc/cycles/v2.3.5/operations/post_release_operations.md`

---
## 2026-04-18T10:10:32+09:00

- **フェーズ**: Operations Phase
- **ステップ**: Codex PR マージ前レビュー対応（バックトラック）
- **実行内容**: Codex review --base main で P1x2/P2x1 の指摘を受領:
- P1: operations_progress_template.md の固定スロットが更新されず release_done/completion_done が false ロック
- P2: pr-ready で pr_number が progress.md に永続化されない
- P1: validate-git.sh が branch.<name>.merge 未設定を即ハードエラー化する regression

ユーザーと相談し対応方針を確定:
1. P1-validate-git.sh: 同名ブランチフォールバックを復活（refs/remotes/<remote>/<branch> 存在確認で救済）。テスト6を status:ok 期待に更新、テスト6b を新設（存在しないブランチ指定で no-upstream 確認）。PASS=34 FAIL=0。
2. P1-template + P2: スコープ縮小（選択肢 A）を採用。
   - operations_progress_template.md から <!-- fixed-slot-grammar: v1 --> ブロック 4 行削除
   - legacy_format パス（history/operations.md ベース）で動作
   - Intent 「含まれるもの」の『サブステップフラグ追加（#579）』部分を取り下げ → 新 Issue #581 として次サイクル送り
   - スコープ保護ルールに従いユーザー承認取得済み（『選択肢 A（テンプレートから削除、スコープ縮小）』を明示選択）

影響範囲の整理:
- Unit 001 の Intent スコープ縮小（承認済み）
- phase-recovery-spec.md / index.md / compaction.md / session-continuity.md / operations-release.md の new_format 仕様記述は残置（将来実装の設計仕様として保持）
- 次サイクル Operations で新サイクル progress.md に固定スロットが含まれず legacy_format で動作するため、復帰判定の機能不全を回避
- **成果物**:
  - `skills/aidlc/scripts/validate-git.sh`
  - `skills/aidlc/scripts/tests/test_validate_git_remote_sync.sh`
  - `skills/aidlc/templates/operations_progress_template.md`
  - `https://github.com/ikeisuke/ai-dlc-starter-kit/issues/581`

---
