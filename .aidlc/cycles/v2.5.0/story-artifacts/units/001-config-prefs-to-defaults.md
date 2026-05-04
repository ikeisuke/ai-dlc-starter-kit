# Unit: 個人好みキーの defaults.toml 集約

## 概要

`config.toml.template` から「個人好み」7 キー（`rules.reviewing.mode` / `rules.reviewing.tools` / `rules.automation.mode` / `rules.git.squash_enabled` / `rules.git.ai_author` / `rules.git.ai_author_auto_detect` / `rules.linting.enabled`）を除去し、`skills/aidlc/config/defaults.toml` に既定値を集約する。4 階層マージ仕様で既存プロジェクトの project 共有値が上書きしない後方互換を維持する。本サイクル内全ファイルで同一の正規キー集合（user_stories.md ストーリー 1 を参照）を使用する。

## 含まれるユーザーストーリー

- ストーリー 1: 個人好みキーを skill defaults へ集約

## 責務

- `skills/aidlc-setup/templates/config.toml.template` から対象 7 キー削除
- `skills/aidlc/config/defaults.toml` における対象 7 キーの既定値**同等性確認**（Construction Phase で確認した結果、対象 7 キーは既に `defaults.toml` に template 旧値と完全一致する形で収録済み。本 Unit では新規追加・編集を行わず、`bin/check-defaults-sync.sh` での正本／コピー sync 維持と bats テストでの値同等性検証のみを行う）
- `skills/aidlc/config/config.toml.example` を template と同等のスタンスで対象 7 キーから整理（実値もコメント例も削除）
- 既存設定読み取り経路の整合性（`scripts/read-config.sh` バッチ＋単一キー両対応）を bats テストで検証（観点 B1: defaults 採用 / 観点 B2: project 値優先による後方互換 NFR）
- `tests/config-defaults/` 配下に bats テストと fixture を追加し、`.github/workflows/migration-tests.yml` の検出 regex／実行コマンドを拡張

## 境界

- ウィザード UI 案内の追加は Unit 002 で実施する（本 Unit はテンプレート差分のみ）
- migrate スクリプトの提案ロジック追加は Unit 003 で実施する
- retrospective 関連設定（`rules.retrospective.*`）は Unit 004 以降で defaults.toml に追加する

## 依存関係

### 依存する Unit

- なし（本サイクルの最初の Unit）

### 外部依存

- `dasel` v3+（既存依存、defaults.toml 読み取りに使用）

## 非機能要件（NFR）

- **後方互換**: 既存プロジェクトの `.aidlc/config.toml` に同キーが残っていても 4 階層マージで読み取れる（破壊的変更なし）
- **既定値同等性**: defaults.toml に移した値は `config.toml.template` の現値と一致（既定動作の意図しない変化を防ぐ）

## 技術的考慮事項

- `config.toml.template` 削除箇所のテスト: 新規 setup 後の `.aidlc/config.toml` から対象 7 キーが消えていることを `grep -L` で確認
- `defaults.toml` 追加箇所のテスト: `read-config.sh rules.reviewing.mode` 等が defaults 値を返すこと

## 関連Issue

- #592（部分対応: 実装スコープ 1, 2 を担当）

## 実装優先度

High（#590 系 Unit のすべての前提）

## 見積もり

0.5 セッション（小規模、テンプレート差分主体）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-04-29
- **完了日**: 2026-04-29
- **担当**: Claude Code
- **エクスプレス適格性**: -
- **適格性理由**: -
