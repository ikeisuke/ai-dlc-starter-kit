# Unit 005 計画: jjスキル移行準備

## 概要

jjスキルの移行手順ドキュメントを作成し、skillsリポジトリへの追加Issueを作成する。
また、migrate-config.sh に `[rules.jj]` 検出時の移行案内（警告出力のみ）を追加する。

## 前提条件の確認

Unit 004（jj関連コード削除）で以下が完了済み:

- jjスキルファイルが `docs/cycles/v1.21.0/jj-backup/` に退避済み
- `prompts/package/` からjj関連コード・設定・プロンプト記述が削除済み
- migrate-config.sh から `[rules.jj]` 追加処理が削除済み

**注意**: Unit 004の論理設計では `aidlc-setup.sh` に暫定移行案内文言の追加が計画されていたが、実装では追加されていない。本Unitで `migrate-config.sh` に移行案内（警告出力のみ）を追加する。

## 変更対象ファイル

| ファイル (SoT) | 操作 | 説明 |
|---------------|------|------|
| `prompts/package/guides/jj-migration.md` | 新規作成 | jjスキル移行手順ドキュメント |
| `prompts/package/bin/migrate-config.sh` | 修正 | `[rules.jj]` 検出時の警告出力追加 |

## 実装計画

### 1. jj-migration.md の作成

`prompts/package/guides/jj-migration.md` に以下を含む移行ガイドを作成:

- **概要**: v1.21.0でjjサポートがスターターキット本体から削除された経緯
- **マーケットプレイス方式でのインストール手順**: skillsリポジトリが公開された後の手順（将来の手順として記載）
- **手動インストール手順**: skillsリポジトリからファイルをコピーしてプロジェクトに配置する方法
- **設定の移行**: `aidlc.toml` から `[rules.jj]` セクションを安全に削除する手順
- **参考情報**: jjスキルの元ファイルはskillsリポジトリ（公開後）から取得可能であることを案内。サイクル固有のバックアップパスは参照しない（コンテキスト境界の分離）

### 2. migrate-config.sh への移行検出・警告追加

`[rules.jj]` セクションが既存の `aidlc.toml` に残っている場合の検出・警告処理を追加。

**責務分離**: `migrate-config.sh` は検出と警告出力のみに限定する。ドキュメント（`rules.md`）への自動追記は行わない（Dependabotパターンとは異なるアプローチ）。

**インターフェース契約**:

- 検出時の出力: `warn:deprecated-config:rules.jj`
- `_has_warnings=true` を設定（終了コード2を返す契機）
- `--dry-run` 時: 同一の警告メッセージを出力（`migrate:deprecate:rules.jj` ではなく `warn:` のみ）
- 未検出時: `skip:not-found:rules.jj` を出力

**ユーザー向けメッセージ**: 警告出力と合わせて、stderr に移行ガイドへの参照を案内する。

**パス規約**:

- **SoT（編集対象）**: `prompts/package/guides/jj-migration.md`
- **ユーザー向けパス（rsync同期後）**: `docs/aidlc/guides/jj-migration.md`
- migrate-config.sh のメッセージではユーザー向けパスを使用する（ユーザーが実際に参照するパス）

### 3. skillsリポジトリへのIssue作成

**Issue作成先**: `ikeisuke/ai-dlc-starter-kit` リポジトリ（jjスキルの公開用skillsリポジトリがまだ存在しないため、本リポジトリにIssueを作成）。

**Issueの内容**:

- タイトル: `[Backlog] feat: jjスキルをskillsリポジトリとして公開`
- ラベル: `backlog,type:feature,priority:medium`
- 本文:
  - 退避済みファイル（SKILL.md、references/jj-support.md）の移行先
  - 新規skillsリポジトリの作成手順
  - marketplace.json への登録手順
  - AI-DLC移行ガイド（`jj-migration.md`）のマーケットプレイス方式セクション更新

## 完了条件チェックリスト

- [ ] 移行手順ドキュメント（`prompts/package/guides/jj-migration.md`）が作成されている
- [ ] skillsリポジトリへのインストール手順（マーケットプレイス方式）が記載されている
- [ ] 手動インストール手順（マーケットプレイス未使用の場合）が記載されている
- [ ] migrate-config.sh に `[rules.jj]` 検出時の警告出力が追加されている（`warn:deprecated-config:rules.jj`、`--dry-run` 対応）
- [ ] skillsリポジトリへの追加 Issue が `ikeisuke/ai-dlc-starter-kit` に作成されている
