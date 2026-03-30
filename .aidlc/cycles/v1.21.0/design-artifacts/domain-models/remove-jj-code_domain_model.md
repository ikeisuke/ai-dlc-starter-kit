# ドメインモデル: jj関連コード削除

## 概要

jj（Jujutsu）VCSサポートをスターターキットから完全削除するための、削除対象の構造と依存関係の整理。新規の恒久ドメイン概念はなく（移行ポリシーのみ追加）、既存の「jjサポート」ドメインの除去が目的。

## 削除対象ドメイン概念

### VCS抽象化レイヤー（削除対象）

現在のスクリプト群は git/jj の両方をサポートするためのVCS抽象化を持つ。削除後は git 固定となり、抽象化レイヤーが不要になる。

- **detect_vcs()**: `.jj` ディレクトリとコマンドの存在で VCS を判定する関数 → git固定に簡素化
- **VCS分岐ロジック**: `if [[ "$vcs" == "jj" ]]` による条件分岐 → jjブランチ全削除
- **--vcs パラメータ**: squash-unit.sh の VCS選択オプション → jj値を無効化（`--vcs git` のみ受理。後方互換のためオプション自体は残す）

### jjスキル（削除対象）

- **versioning-with-jj スキル**: SKILL.md + jj-support.md で構成される非推奨スキル → 退避後に削除
- **スキル登録**: ai-tools.md のスキルテーブル、セットアップのシンボリックリンク → 登録解除

### jj設定（削除対象）

- **[rules.jj] セクション**: aidlc.toml, defaults.toml, migrate-config.sh → セクションごと削除
- **設定参照**: rules.md, commit-flow.md 等のread-config呼び出し → 参照削除

### jjコマンドallowlist（削除対象）

- **ai-agent-allowlist.md**: jjコマンドの読み取り専用・書き込み許可リスト → エントリ削除

## 追加ドメイン概念

### マイグレーション案内（追加）

- **aidlc-setup.sh の移行検出**: ユーザーの既存 `aidlc.toml` に `[rules.jj]` が残っている場合の案内メッセージ
- 暫定文言とし、Unit 005 で `jj-migration.md` 作成後に参照先を更新

## 影響範囲

削除後、以下の振る舞いが変化する:

1. **env-info.sh / aidlc-env-check.sh**: `jj:available` 行が出力されなくなる
2. **aidlc-git-info.sh**: `vcs_type` は常に `git` または `unknown`
3. **squash-unit.sh**: `--vcs` は後方互換のため残すが `git` 以外はエラー終了
4. **aidlc-cycle-info.sh**: jj bookmark 検出をスキップ、git のみ使用

## ユビキタス言語

- **jj**: Jujutsu VCS（削除対象の外部ツール）
- **bookmark**: jj における git ブランチ相当の概念
- **SoT (Source of Truth)**: `prompts/package/` が正本、`docs/aidlc/` はミラー
- **退避**: 削除前にファイルをサイクルディレクトリに保存する操作
