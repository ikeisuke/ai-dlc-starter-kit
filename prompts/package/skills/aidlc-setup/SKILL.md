---
name: aidlc-setup
description: Upgrades the AI-DLC environment to the latest version. Syncs prompts and templates from the starter kit. Use when the user says "AIDLCアップデート", "update aidlc", "aidlc setup", "start setup", or "/aidlc-setup".
argument-hint: (引数なし)
---

# AI-DLC Setup

AI-DLC環境を最新バージョンにアップグレードするスキル。

## 実行方法

### 事前準備

1. アップグレードスクリプトの存在を確認:

```bash
ls docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh
```

スクリプトが存在しない場合、AI-DLCのバージョンが古い可能性があります。
以下の手順で `setup-prompt.md` を特定し、読み込んで手動アップグレードしてください:

1. 事前にBashで以下を順に実行し、結果を変数に格納:

```bash
ghq root
```

```bash
docs/aidlc/bin/read-config.sh project.starter_kit_repo
```

2. 取得した値を使ってパスを組み立て:
   - `GHQ_ROOT`: 手順1の出力
   - `RAW_REPO`: 手順2の出力
   - `REPO`: RAW_REPOから `ghq:` プレフィックスを除去
   - `SETUP_PATH`: `{GHQ_ROOT}/{REPO}/prompts/setup-prompt.md`

3. 解決したパスのファイルを読み込む

### アップグレード実行

1. dry-runで変更内容を確認:

```bash
docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh --dry-run
```

2. 結果をユーザーに提示し、続行の承認を得る

   **出力の読み方**:

   | キー | 意味 |
   |------|------|
   | `setup_type:upgrade:X:Y` | バージョンXからYへのアップグレード |
   | `skip:already-current:X` | バージョンXで最新、アップグレード不要 |
   | `sync_added:<file>` | 新規追加されるファイル |
   | `sync_updated:<file>` | 更新されるファイル |
   | `sync_deleted:<file>` | 削除されるファイル |

   `skip:already-current` の場合はアップグレード不要。ユーザーに伝えて終了。
   `error:` の場合はエラー内容を表示して終了。

3. アップグレード用ブランチを作成:

   事前にBashで現在のブランチ名を取得:
   ```bash
   git branch --show-current
   ```

   取得したブランチ名を `BASE_BRANCH` とし、アップグレードブランチを作成:
   ```bash
   git checkout -b upgrade/vX.X.X
   ```
   （X.X.Xはdry-run出力の `version_to:` の値）

4. アップグレードを実行:

```bash
docs/aidlc/skills/aidlc-setup/bin/aidlc-setup.sh
```

5. 変更をコミット:

```bash
git add docs/aidlc/ docs/aidlc.toml .claude/ .kiro/
```

```bash
git commit -m "chore: AI-DLCをバージョンX.X.Xにアップグレード"
```

6. プッシュ＆PR作成（gh利用可能時）:

   ```bash
   git push -u origin upgrade/vX.X.X
   ```

   Writeツールで一時ファイルを作成（内容: PR本文）:

   ```text
   ## AI-DLC アップグレード

   バージョン X.X.X → Y.Y.Y へのアップグレード

   ### 変更内容
   - [dry-run出力のsync_added/sync_updated/sync_deleted行を要約]
   ```

   ```bash
   gh pr create --title "chore: AI-DLCをバージョンY.Y.Yにアップグレード" --base BASE_BRANCH --body-file <一時ファイルパス>
   ```

   一時ファイルを削除

   **gh未認証時・ネットワークエラー時**: PR作成をスキップし、手動でPR作成するようユーザーに案内

7. セッション終了を案内:

```text
AI-DLCのアップグレードが完了しました！

アップグレード用PRが作成されました: [PR URL]

**次のステップ**:
1. PRをレビュー・マージしてください
2. マージ後、新しいセッションで「start inception」と指示してください
```

## 更新対象

| ディレクトリ | 内容 |
|-------------|------|
| `docs/aidlc/prompts/` | フェーズプロンプト |
| `docs/aidlc/templates/` | ドキュメントテンプレート |
| `docs/aidlc/guides/` | ガイドドキュメント |
| `docs/aidlc/bin/` | ユーティリティスクリプト |
| `docs/aidlc/skills/` | スキルファイル |
| `docs/aidlc/kiro/` | KiroCLIエージェント設定 |

## 注意事項

- `docs/aidlc.toml` の既存設定は保持されます
- `docs/cycles/rules.md` はプロジェクト固有のため上書きされません
- アップグレード完了後は新しいセッションで作業を開始してください
- `--force` オプションで同バージョンでも強制アップグレードが可能です
