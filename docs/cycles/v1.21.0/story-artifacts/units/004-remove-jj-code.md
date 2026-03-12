# Unit: jj関連コード削除

## 概要
jj（Jujutsu）VCSに関連するコードをスターターキット本体から完全に削除する。v1.19.0で非推奨化済みのため、互換期間不要。

## 含まれるユーザーストーリー
- ストーリー 5: jj関連コードの削除

## 責務
- **削除前退避**: `prompts/package/skills/versioning-with-jj/` の移行元ファイル一式（SKILL.md、jj-support.md）を `docs/cycles/v1.21.0/` に退避・記録
- `prompts/package/skills/versioning-with-jj/` ディレクトリの削除
- 各スクリプトからjj関連コードの削除:
  - `aidlc-git-info.sh`: `.jj` 検出と `jj log`/`jj diff` 分岐
  - `aidlc-cycle-info.sh`: jj検出と `jj log -r @` 分岐
  - `squash-unit.sh`: `--vcs jj` オプション、`find_base_commit_jj()`, `squash_jj()`
  - `aidlc-env-check.sh`: `jj` コマンドチェック
- `docs/aidlc.toml` の `[rules.jj]` セクション削除
- プロンプトファイル（rules.md, commit-flow.md, inception.md, construction.md, operations.md）のjj参照削除
- シンボリックリンク削除（`.claude/skills/versioning-with-jj`, `.kiro/skills/versioning-with-jj`）
- `aidlc-setup.sh` にjj設定検出時の移行案内を追加（暫定文言。Unit 005で `jj-migration.md` 作成後に参照先を更新）

## 境界
- jjスキルの外部リポジトリへの移行はUnit 005で扱う
- jjの機能自体の代替手段の提供は行わない

## 依存関係

### 依存する Unit
- 001-rename-aidlc-setup（依存理由: jj移行案内を `aidlc-setup.sh`（リネーム後）に組み込むため）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 削除対象ファイルは `prompts/package/` 側を編集（メタ開発ルール）
- 移行案内は `aidlc-setup.sh` のマイグレーション処理に組み込む
- 削除後に `grep -r` でjj関連コード残留がないことを確認

## 実装優先度
High

## 見積もり
中〜大規模（10+ファイルの編集・削除＋退避＋移行案内追加）

## 関連Issue
- #276

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
