# Unit 001 計画: プラグインディレクトリ構造構築

## 概要

AI-DLCスターターキットをClaude Codeプラグインリポジトリ構造に変換する。`skills/aidlc/steps/` を唯一の正本（Single Source of Truth）とし、`prompts/package/prompts/` を配布用ミラーとして一方向同期で整備する。

## 非対象（Unit境界の明確化）

- **SKILL.md の意味変更・ARGUMENTSパーシング仕様変更** → Unit 002
- **v1残存資産の全削除（rsync処理、defaults.tomlパス修正、スターターキットパス判定）** → Unit 003
- Unit 001 は **配布構造の整備と同期経路の確立** に限定する

## 現状分析

### 既に完了している構造

- `skills/aidlc/` にSKILL.md、steps/、config/、scripts/、templates/ が配置済み
- `skills/aidlc/steps/` にモジュラーステップファイルが配置済み（common/15ファイル、construction/4、inception/6、operations/5、setup/3、migrate/3）
- `skills/{aidlc-setup,reviewing-*,squash-unit}` が配置済み
- `.claude/skills/` にシンボリックリンクが設定済み（`../../skills/*` を参照）
- `.claude-plugin/marketplace.json` が存在
- ルートの CLAUDE.md / AGENTS.md が `skills/aidlc/` へリダイレクト済み

### 未完了の作業

1. **`prompts/package/prompts/` のモジュラー化**: v1のモノリシック構造（`construction.md`, `inception.md` 等）のまま。`skills/aidlc/steps/`（正本）と同期されていない
2. **`docs/aidlc/prompts/` の更新**: `prompts/package/` の rsync コピーのため、同じくモノリシック構造。`--delete` オプションで旧ファイル削除が必要
3. **旧パス参照の棚卸し**: `prompts/package/guides/`、`docs/aidlc/guides/`、`prompts/setup-prompt.md` 等が旧モノリシックパス（`prompts/construction.md` 等）を参照している可能性
4. **marketplace.json のバージョン**: 1.22.1（v2.0.4 にすべき）
5. **task-management.md の不足**: `prompts/package/prompts/common/` に `task-management.md` がない

## 変更対象ファイル

### 1. prompts/package/prompts/ のモジュラー化（正本 → ミラーの一方向同期）

**方針**: `skills/aidlc/steps/` の各ファイルを `prompts/package/prompts/` にコピーする。手動コピーではなく、同期スクリプトまたはコマンドで一方向同期を確立する。

- **削除**: `prompts/package/prompts/construction.md`（モノリシック）
- **削除**: `prompts/package/prompts/inception.md`（モノリシック）
- **削除**: `prompts/package/prompts/operations.md`（モノリシック）
- **削除**: `prompts/package/prompts/operations-release.md`（モノリシック）
- **削除**: `prompts/package/prompts/setup.md`（モノリシック）
- **新規作成**: `prompts/package/prompts/construction/` ディレクトリ（01-setup.md ～ 04-completion.md）
- **新規作成**: `prompts/package/prompts/inception/` ディレクトリ（01-setup.md ～ 06-backtrack.md）
- **新規作成**: `prompts/package/prompts/operations/` ディレクトリ（01-setup.md ～ 04-completion.md + operations-release.md）
- **新規作成**: `prompts/package/prompts/setup/` ディレクトリ（01-detect.md ～ 03-migrate.md）
- **新規作成**: `prompts/package/prompts/migrate/` ディレクトリ（01-preflight.md ～ 03-verify.md）
- **新規**: `prompts/package/prompts/common/task-management.md`
- **更新**: `prompts/package/prompts/AGENTS.md`, `CLAUDE.md` を `skills/aidlc/` の内容と同期

### 2. docs/aidlc/prompts/ の更新

- `sync-package.sh --delete` を使用して `prompts/package/` → `docs/aidlc/` を同期（`--delete` で旧モノリシックファイルを確実に削除）
- 事前に `--delete` オプションの利用可否を確認

### 3. 旧パス参照の棚卸しと更新

- `prompts/package/guides/` 内の旧パス参照（`prompts/construction.md` 等）を新パス（`prompts/construction/01-setup.md` 等）に更新
- `docs/aidlc/guides/` は sync-package.sh で自動反映
- `prompts/setup-prompt.md` の旧パス参照を更新
- `README.md` の旧パス参照があれば更新

### 4. .claude-plugin/marketplace.json

- version を現在のサイクルに合わせて更新

## 実装計画

1. **旧パス参照の棚卸し**: `grep -r` で旧モノリシックパス参照箇所を洗い出す
2. **prompts/package/prompts/ のモジュラー化**: `skills/aidlc/steps/` から一方向コピーで同期。旧モノリシックファイルを削除
3. **旧パス参照の更新**: 棚卸し結果に基づき、guides・setup-prompt.md・README.md のパス参照を新構造に修正
4. **marketplace.json のバージョン更新**
5. **docs/aidlc/ の同期**: `sync-package.sh --delete` で旧ファイル含め一括同期
6. **差分確認・テスト**: 同期結果の検証、パス参照切れがないことの確認

## 完了条件チェックリスト

- [ ] `skills/aidlc/` にオーケストレーターSKILL.md とステップファイルが配置されている
- [ ] `prompts/package/prompts/` が `skills/aidlc/steps/` と同一構造（モジュラー化済み、旧モノリシックファイル削除済み）
- [ ] `docs/aidlc/prompts/` の内容が `skills/aidlc/steps/` と同一構造（`--delete` 同期済み）
- [ ] 旧モノリシックパス参照が更新され、参照切れがない
- [ ] 既存スキル（reviewing-*, squash-unit, aidlc-setup）が `skills/` 配下に統合されている
- [ ] プラグインルートの CLAUDE.md / AGENTS.md が整備されている
- [ ] marketplace.json のバージョンが更新されている
