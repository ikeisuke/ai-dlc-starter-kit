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
2. `version.txt` を新バージョンに更新
3. `README.md`を更新
4. Operations Phase完了コミット
5. PRを作成（`gh pr create`）
6. PRをマージ
7. GitHub Actionsが自動でタグ作成
8. 必要に応じてGitHub Releasesでリリースノート作成

### CI/CDフロー要点

- **自動タグ付け**: mainブランチへのpush時に `version.txt` からバージョンを読み取り、`v{VERSION}` タグを自動作成（`.github/workflows/auto-tag.yml`）
- **PRチェック**: Markdownlintによる自動チェック（`.github/workflows/pr-check.yml`）

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
  3. 閾値を調整する（`docs/aidlc.toml`の`[rules.size_check]`セクション）
- 対応後、再度チェックを実行して警告が解消されていることを確認

### Operations Phaseステップ5と6の間で実行する処理

**タイミング**: Operations Phaseのステップ5（バックログ整理）完了後、ステップ6（リリース準備）開始前（詳細は `docs/aidlc/prompts/operations.md` を参照）

1. **setup-prompt.mdを読み込んでアップグレード処理を実行**

   ```text
   prompts/setup-prompt.md を読み込んで、AI-DLC 環境をアップグレードしてください
   ```

2. **アップグレード処理の内容**
   - rsyncによる `prompts/package/` → `docs/aidlc/` 同期
   - aidlc.tomlのマイグレーション（新設定セクション追加）
   - starter_kit_versionの更新

3. **確認事項**
   - 削除対象ファイルがあれば確認・承認
   - 新設定セクションが追加されたことを確認

**理由**: `prompts/package/` で変更したプロンプト・テンプレートを `docs/aidlc/` に反映し、aidlc.tomlのマイグレーションも確実に実行するため。
