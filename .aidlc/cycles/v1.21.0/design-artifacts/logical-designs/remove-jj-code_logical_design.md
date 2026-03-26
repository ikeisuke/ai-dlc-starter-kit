# 論理設計: jj関連コード削除

## 概要

jj関連コードの削除における実装順序と各スクリプトの修正方針を定義する。

## コンポーネント修正方針

### 1. aidlc-git-info.sh

**現状**: `detect_vcs()` 関数で `.jj` ディレクトリと `jj` コマンドの存在を検出し、git/jj を分岐。

**修正方針**:

- `detect_vcs()` 関数: `.jj` 検出ロジックを削除し、git のみ検出に簡素化
- ブランチ取得: `if [[ "$vcs" == "jj" ]]` ブロック全削除
- ワークツリー状態: jj diff 分岐削除
- 最近のコミット: jj log 分岐削除
- 非推奨警告出力: `warn:jj-deprecated` 出力削除
- 出力フォーマットの `vcs_type` は `git` または `unknown` のみ

### 2. aidlc-cycle-info.sh

**現状**: `get_current_branch()` で jj を優先的に検出。

**修正方針**:

- jj優先ブロック（`.jj` 検出 + `jj log -r @`）を削除
- git のみの分岐に簡素化
- コメントの「git/jj両対応」を「git」に修正

### 3. squash-unit.sh

**現状**: `--vcs` オプションで git/jj を切り替え。jj用の関数群あり。

**修正方針**:

- `--vcs` オプション: jj値を無効化。`--vcs git` のみ受理（後方互換のためオプション自体は残す）。jj指定時はエラー終了
- `VCS_TYPE` 変数とjj判定ロジックを削除
- `find_base_commit_jj()` 関数を削除
- `squash_jj()` 関数を削除
- helpテキストのjj関連記述を削除

### 4. aidlc-env-check.sh

**現状**: `jj:available|not-installed` を出力。

**修正方針**: jjチェック行とhelpテキストから jj 記述を削除

### 5. env-info.sh

**現状**: jjツールチェックとbookmark検出ロジックあり。

**修正方針**:

- `get_current_branch()` 内のjj bookmark 検出ブロックを削除
- `echo "jj:$(check_tool jj)"` 行を削除
- helpテキスト・出力例からjj記述を削除

### 6. migrate-config.sh

**現状**: `[rules.jj]` セクションを追加するマイグレーション処理あり。

**修正方針**: `_add_section "rules\\.jj"` ブロックを削除

### 7. aidlc-setup.sh

**現状**: jjに関する処理なし。

**修正方針**: ユーザーの既存 `aidlc.toml` に `[rules.jj]` セクションが存在する場合の移行案内を追加。具体的には、マイグレーション処理内で `[rules.jj]` の存在を検出し、削除済みであること・移行方法を案内するメッセージを出力する。

## 設定ファイル修正方針

### docs/aidlc.toml

`[rules.jj]` セクション（enabled = false とコメント含む）を削除。

### prompts/package/config/defaults.toml

`[rules.jj]` セクションを削除。

## プロンプトファイル修正方針

各ファイルから jj 関連の記述（条件分岐の説明、非推奨注記、jj固有の手順）を削除。git のみの手順として簡素化する。

## スキルファイル修正方針

### squash-unit SKILL.md

`--vcs` のデフォルト値解決に `rules.jj.enabled` を参照している箇所を修正。jj分岐を削除し、`--vcs` のデフォルトを `git` 固定に簡素化。

## ガイドファイル修正方針

- **config-merge.md**: jj設定のマージ例を削除
- **skill-usage-guide.md**: versioning-with-jj のスキル行を削除
- **ai-agent-allowlist.md**: jjコマンドのallowlistエントリ（読み取り・書き込み・JSON設定例）を全削除

## セットアップ系ファイル修正方針

### prompts/setup-prompt.md

jj関連の記述（jjステータス参照、jj設定の説明、jjコマンド例等）を削除。

### prompts/setup/templates/aidlc.toml.template

`[rules.jj]` セクションを削除。

## 実装順序

1. 退避（データ保全を最優先）
2. ファイル・リンク削除（物理的な削除）
3. スクリプト修正（依存先から順に）
4. 設定・プロンプト・ガイド修正（参照側）
5. aidlc-setup.sh 移行案内追加（新規追加）
6. ミラー同期
7. 残留確認

## 不明点と質問

なし（コード削除のため新しい設計判断は不要）
