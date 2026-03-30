# Unit 003 計画: アップグレードチェックスキップ機能

## 概要

aidlc.tomlの設定でInception Phase開始時のアップグレードチェック（ステップ5）をスキップできる機能を追加する。

## 変更対象ファイル

1. `prompts/package/prompts/common/rules.md` - `[rules.upgrade_check]` セクションの仕様定義を追加
2. `prompts/package/prompts/inception.md` - ステップ5冒頭にread-config.sh呼び出しと条件分岐を追加
3. `docs/aidlc.toml` - `[rules.upgrade_check]` セクション追加（コメント付きデフォルト値）

## 実装計画

1. `docs/aidlc.toml` に `[rules.upgrade_check]` セクションを追加
   - `enabled = true`（デフォルト、従来動作維持）
   - 既存セクション（`[rules.squash]`, `[rules.feedback]` 等）と同じパターン

2. `rules.md` に `rules.upgrade_check.enabled` の仕様を追加（Depth Level仕様と同様のパターン）
   - 有効値: `true` / `false`
   - デフォルト: `true`（従来動作維持）
   - 読み取り失敗時（終了コード2）: 警告表示し `true` にフォールバック
   - 非boolean値（`true`/`false`以外）: 警告表示し `true` にフォールバック
   - 警告文言: 既存パターン（`rules.cycle.mode` 等）と統一

3. `inception.md` のステップ5冒頭に条件分岐を追加
   - `read-config.sh rules.upgrade_check.enabled --default "true"` で設定値を取得
   - `false` の場合: ステップ5のバージョン確認処理をスキップし、ステップ5.5（サイクルモード確認）へ直接遷移
   - `true` の場合: 従来通りバージョン確認を実行（既存ロジックそのまま）
   - スキップ対象はステップ5のみ（ステップ5.5以降は常に実行）

## 完了条件チェックリスト

- [ ] docs/aidlc.tomlに[rules.upgrade_check]セクション追加
- [ ] rules.mdにupgrade_check仕様セクション追加（有効値、デフォルト、失敗時契約、警告文言）
- [ ] inception.mdステップ5に条件分岐追加（スキップ時はステップ5.5へ遷移）
