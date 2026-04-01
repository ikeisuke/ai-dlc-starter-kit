# Unit 004: 運用安定化 - 実装計画

## 概要

write-historyスキルのパス修正、reviewingスキルのCodex呼び出し統一、post-merge-sync.shのエラーハンドリング改善を行う。3つのIssueは対象ファイルが完全に独立しているため、順番に対応する。

## 変更対象ファイル

### #494: write-historyスキルのパス・パーミッション修正
- `skills/write-history/SKILL.md` — スクリプトパスの修正
- `skills/aidlc/config/settings-template.json` — `Skill(write-history)` パーミッション追加（`aidlc`スキルが設定テンプレートを所有し、`aidlc-setup`はそれを利用する側）

### #491: reviewingスキルのCodex呼び出し統一
- `skills/reviewing-construction-code/SKILL.md`
- `skills/reviewing-construction-design/SKILL.md`
- `skills/reviewing-construction-integration/SKILL.md`
- `skills/reviewing-construction-plan/SKILL.md`
- `skills/reviewing-inception-intent/SKILL.md`
- `skills/reviewing-inception-stories/SKILL.md`
- `skills/reviewing-inception-units/SKILL.md`
- `skills/reviewing-operations-deploy/SKILL.md`
- `skills/reviewing-operations-premerge/SKILL.md`

### #500: post-merge-sync.shのエラーハンドリング改善
- `bin/post-merge-sync.sh` — `git ls-remote --exit-code` による事前存在確認追加

## #491 共通契約（Codex呼び出し統一仕様）

9つのreviewingスキルで統一する変更内容:

1. **呼び出し構文**: `codex exec -s read-only -C .` → codexスキル経由（`codex exec` / `codex review`）。codexスキルのSKILL.mdが定義するインターフェースに準拠
2. **セッション継続**: `codex exec resume <session-id>` は維持（codexスキルが提供するresume機能を利用）
3. **allowed-tools**: `Bash(codex:*)` は維持（codexスキル経由でも最終的にcodex CLIを実行するため変更不要）
4. **reviewingスキル側の責務**: レビュー観点・出力フォーマット・セルフレビューモードは各スキル固有のまま維持。変更するのはCodex実行コマンドセクションのみ

## #500 状態遷移表

`post-merge-sync.sh` のリモートブランチ削除時の状態遷移:

| 入力状態 | 判定条件 | 出力 | 終了コード への影響 |
|---------|---------|------|-----------------|
| リモートに存在する | `git ls-remote --exit-code` 成功 → `git push origin --delete` 成功 | `deleted:remote:{branch}` | なし（正常） |
| リモートに存在する | `git ls-remote --exit-code` 成功 → `git push origin --delete` 失敗 | `warn:remote-delete-failed:{branch}` | `DELETE_FAILED=true` |
| リモートに存在しない（自動削除済み） | `git ls-remote --exit-code` 失敗 | `skipped:already-deleted:{branch}` | なし（正常扱い） |

**既存動作との互換性**: `deleted:remote` と `warn:remote-delete-failed` の出力は既存のまま維持。`skipped:already-deleted` が新規追加。`--dry-run`モードでは `[dry-run] git push origin --delete` の出力を維持。

## 実装計画

### Phase 1: 設計（standard depth_level）
1. ドメインモデル設計 — 3つのIssueの影響範囲と変更パターンの整理
2. 論理設計 — 各ファイルの具体的な変更内容の定義
3. 設計レビュー

### Phase 2: 実装
1. **#494対応**: write-history SKILL.mdのパス修正 + settings-template.jsonへのパーミッション追加
2. **#491対応**: 共通契約に従い、9つのreviewingスキルのCodexセクションをcodexスキル経由の記述に統一
3. **#500対応**: 状態遷移表に従い、post-merge-sync.shの2箇所（`--yes`モード・対話モード）に`git ls-remote --exit-code`による事前確認を追加
4. テスト・検証
5. AIレビュー

## 検証ケース

| Issue | 検証内容 | 方法 |
|-------|---------|------|
| #494 | write-historyスキルが正しいパスでスクリプトを実行できる | SKILL.mdのパスが実在するスクリプトを指していることを確認 |
| #494 | settings-template.jsonにSkill(write-history)が含まれている | ファイル内容の確認 |
| #491 | 全9件のreviewingスキルでCodex呼び出しが統一されている | grepで全9件一括確認 |
| #500 | `post-merge-sync.sh --dry-run`が正常終了する | コマンド実行 |
| #500 | 既存の`deleted:remote`出力パターンが維持されている | コードの差分確認 |
| #500 | `skipped:already-deleted`パターンが実装されている | コードの差分確認 |
| #500 | ref不在とシステムエラーが分離されている | `warn:remote-check-failed`パターンの確認 |

## 完了条件チェックリスト

- [ ] skills/write-history/SKILL.mdのスクリプトパスが修正されている
- [ ] skills/aidlc/config/settings-template.jsonにSkill(write-history)パーミッションが追加されている
- [ ] 全9つのreviewingスキルのSKILL.mdでCodex呼び出しがcodexスキル経由に変更されている
- [ ] bin/post-merge-sync.shにgit ls-remote --exit-codeによるリモートブランチ存在確認が追加されている（2箇所: --yesモード・対話モード）
- [ ] post-merge-sync.sh --dry-runが正常終了すること
- [ ] skipped:already-deleted出力パターンが実装されていること
- [ ] warn:remote-check-failed出力パターンが実装されていること（ref不在とシステムエラーの分離）
