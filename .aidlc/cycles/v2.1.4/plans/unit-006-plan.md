# Unit 006: skills/直接参照チェック導入 - 計画

## 概要

`skills/`以下のファイルでプロジェクトルート相対パス（`skills/aidlc/`）による参照違反をCIで自動検出するスクリプトを作成し、GitHub Actionsに統合する。

## 変更対象ファイル

- `bin/check-skill-references.sh` - 新規作成。`skills/`配下のファイルで`skills/aidlc/`パスの直接参照を検出
- `.github/workflows/skill-reference-check.yml` - 新規workflow。独立したpathsトリガーでskill参照チェックを実行

## 実装計画

### 1. チェックスクリプト作成（bin/check-skill-references.sh）

`bin/check-bash-substitution.sh`を参考に、以下の構造で作成:

- **検出パターン**: `skills/aidlc/` で始まるパス文字列（正規表現: `skills/aidlc/`）
- **対象ファイル**: `skills/`以下の `.md`, `.sh`, `.toml` ファイル
- **除外**: スクリプト自身（self-reference防止）
- **スコープ判定**: 自己完結。`skills/`ディレクトリの存在で判定（`_check_scope`のようなconfig依存は使わない。被検査対象側のスクリプトに依存しない）
- **終了コード**: 0=違反なし、1=違反あり、2=スクリプトエラー
- **コメント内も検出対象**

### 2. CI統合（.github/workflows/pr-check.yml）

独立workflowとして`skill-reference-check.yml`を新規作成（既存pr-check.ymlのpathsを汚染しない）:
- `paths`トリガー: `skills/**`, `bin/check-skill-references.sh`
- `run: bash bin/check-skill-references.sh`

## 完了条件チェックリスト

- [x] チェックスクリプト（`bin/check-skill-references.sh`）が作成されている
- [x] GitHub ActionsのCIジョブに追加されている
