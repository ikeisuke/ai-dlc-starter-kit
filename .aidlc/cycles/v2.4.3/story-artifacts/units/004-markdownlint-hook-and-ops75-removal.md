# Unit: markdownlint PostToolUse hook 追加と Operations §7.5 削除（#609）

## 概要

`.claude/settings.json` の PostToolUse に markdownlint hook を追加し、Edit/Write 直後の `*.md` 編集で違反を即時検出する。同時に Operations Phase §7.5（手動 lint ステップ）と `scripts/operations-release.sh lint` サブコマンド本体を削除し、CI（必須 Check）と hook の二層に集約する。手順書 / スクリプト / 関連参照箇所を grep ベースで全特定して同期更新する。

## 含まれるユーザーストーリー

- ストーリー 4: markdownlint の hook 化と Operations §7.5 削除（#609）

## 責務

- `.claude/settings.json` の `hooks.PostToolUse` に `matcher: "Edit|Write"` の hook 追加
- 新規 hook スクリプト（命名は Construction で確定）の実装: 拡張子チェック / `markdownlint-cli2` 存在確認 / 違反時の exit code 通知 / 既存 hook との独立動作
- `skills/aidlc/steps/operations/operations-release.md` の §7.5 削除と関連参照（§7.7 の `markdownlint:auto-fix` 由来記述等）の整合更新
- `skills/aidlc/steps/operations/02-deploy.md` の §7.5 参照削除
- `skills/aidlc/scripts/operations-release.sh` の `lint` サブコマンド本体削除
- regression 検証: 既存 PostToolUse hook の連鎖 / matcher 起動範囲 / `*.md` 以外のスキップ動作
- `markdownlint-cli2` 未インストール環境での正常スキップ動作確認
- hook スクリプトのファイルパスを design.md に記録し settings.json 参照と一致

## 境界

- CI の `pr-check.yml` `markdown-lint` job は変更しない（必須 Check として継続）
- markdownlint のルール変更（`.markdownlint.json`）は対象外
- 他の lint ツール（shellcheck / yamllint 等）の hook 化は対象外
- PreToolUse hook 化（編集前検証）は対象外
- 過去サイクル（`.aidlc/cycles/v*/history/`）に残る §7.5 / `operations-release.sh lint` 言及は対象外（履歴改変はしない）

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `markdownlint-cli2`（任意。未インストール時はスキップ）
- Claude Code hook 仕様（PostToolUse の入力取得方法）

## 非機能要件（NFR）

- **パフォーマンス**: hook 実行は `*.md` 編集時のみで高速（拡張子チェックで早期 return）
- **セキュリティ**: 影響なし（既存 hook 枠組みを踏襲）
- **スケーラビリティ**: 影響なし
- **可用性**: `markdownlint-cli2` 未インストール環境でも編集動作をブロックしない

## 技術的考慮事項

- hook スクリプトは Bash で記述（既存 `check-utf8-corruption.sh` と同枠組み）
- PostToolUse の入力（編集対象ファイルパス）取得は Claude Code hook 仕様に従う
- `markdownlint-cli2` 検出は `command -v markdownlint-cli2` または `npx --no-install markdownlint-cli2 --version`
- §7.5 削除に伴う影響範囲は grep で全特定: `grep -rn "§7\.5\|7\.5 Markdownlint\|operations-release\.sh lint" skills/`
- hook スクリプトのファイル名・配置は Construction Phase 設計時に確定し、design.md の I/O 表に記録

## 関連Issue

- #609

## 実装優先度

High

## 見積もり

M（Medium、実装範囲大きめ）: hook 新規実装 + 手順書整合 + regression 検証 4 観点（matcher / 拡張子 / 未インストール / 既存 hook 連鎖）。Construction Phase 着手時に L へ繰り上げ要否を再評価する。1-2 セッション想定

---

## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-28
- **完了日**: 2026-04-28
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
