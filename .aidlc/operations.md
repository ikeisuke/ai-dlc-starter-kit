# 運用引き継ぎ情報

Operations Phaseで決定した運用設定・方針をサイクル横断で引き継ぐためのファイルです。

---

## デプロイ方針

### デプロイ方式

- **方式**: GitHubリポジトリとして公開
- **リリース方法**: mainブランチへのマージ + タグ作成
- **バージョニング**: セマンティックバージョニング（v1.2.1形式）

### リリース手順

1. サイクルブランチで開発完了
2. `version.txt` を新バージョンに更新（`bin/update-version.sh --version {{CYCLE}}` で一括更新）
3. `README.md`を更新
4. Operations Phase完了コミット
5. PRを作成（`gh pr create`）
6. PRをマージ
7. GitHub Actionsが自動でタグ作成
8. 必要に応じてGitHub Releasesでリリースノート作成

### CI/CDフロー要点

- **自動タグ付け**: mainブランチへのpush時に `version.txt` からバージョンを読み取り、`v{VERSION}` タグを自動作成（`.github/workflows/auto-tag.yml`）
- **PRチェック**: Markdownlint、Bash Substitution Check、defaults.toml同期チェックによる自動チェック（`.github/workflows/pr-check.yml`）

### ロールバック方法

```bash
# 前のバージョンに戻す場合
git checkout v1.2.0
```

---

## 既知の問題・注意点

### 運用で発覚した問題

| 問題 | ワークアラウンド | 根本対応予定 |
|------|-----------------|-------------|
| なし | - | - |

### 運用時の注意点

- メタ開発の意識: AI-DLCスターターキット自体を開発していることを常に意識
- セットアップ時の動作確認: 変更後は別ディレクトリでセットアップをテスト

---

## メタ開発特有のOperations Phase手順【重要】

このプロジェクトはメタ開発のため、Operations Phaseで以下の追加手順が必要です。

### defaults.toml同期確認

`skills/aidlc/config/defaults.toml`（正本）を変更した場合、`skills/aidlc-setup/config/defaults.toml`（コピー）も同期してください。

```bash
bin/check-defaults-sync.sh
```

- **sync:ok（終了コード0）**: 同期済み。次のステップへ進む
- **sync:mismatch（終了コード1）**: 正本の内容をコピーに反映してから再実行。コピー先のファイル冒頭の同期用コメント（`# 正本:` で始まる行）は保持すること
- **error:not-found（終了コード2）**: 該当ファイルが不在。ファイルの存在を確認

**タイミング**: Construction Phase で `skills/aidlc/config/defaults.toml` を変更した場合、Unit完了前に実行。CIでもPR時に自動チェック��れる。

### 完了前のサイズチェック

プロンプトファイルが肥大化していないか確認します。

```bash
bin/check-size.sh
```

**警告が出た場合の対応**:

- 警告メッセージで超過しているファイルとサイズを確認
- 以下の対応を検討:
  1. ファイルを分割する（共通部分を別ファイルに外部化）
  2. 冗長な記述を削減する
  3. 閾値を調整する（`.aidlc/config.toml`の`[rules.size_check]`セクション）
- 対応後、再度チェックを実行して警告が解消されていることを確認

