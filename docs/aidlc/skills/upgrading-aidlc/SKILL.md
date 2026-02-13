---
name: upgrading-aidlc
description: Upgrades the AI-DLC environment to the latest version. Syncs prompts and templates from the starter kit. Use when the user says "AIDLCアップデート", "update aidlc", or "start upgrade".
argument-hint: (引数なし)
---

# AI-DLC Upgrade

AI-DLC環境を最新バージョンにアップグレードするスキル。

## 実行方法

以下の手順で `setup-prompt.md` を特定し、読み込んでください。

### setup-prompt.md 検索フロー

1. `prompts/setup-prompt.md` の存在を確認する（1回のみ）
2. **存在する場合**: そのまま読み込む

   ```text
   prompts/setup-prompt.md を読み込んで、AI-DLC 環境をアップグレードしてください
   ```

3. **存在しない場合**: `docs/aidlc.toml` の `[project]` セクションから `starter_kit_repo` を取得し、`ghq root` 経由でパスを解決する

   ```bash
   # 1. ghq root を取得
   GHQ_ROOT=$(ghq root)
   # 2. docs/aidlc.toml から starter_kit_repo を取得（デフォルト: github.com/ikeisuke/ai-dlc-starter-kit）
   REPO=$(docs/aidlc/bin/read-config.sh project.starter_kit_repo --default "github.com/ikeisuke/ai-dlc-starter-kit")
   # 3. パスを組み立て
   SETUP_PATH="${GHQ_ROOT}/${REPO}/prompts/setup-prompt.md"
   ```

   解決したパスのファイルを読み込む。

**重要**: Glob等の再帰検索は行わないこと。上記の2ステップ（ローカル確認 → toml経由解決）で必ず特定できる。

## 処理内容

アップグレードでは以下が実行されます:

1. **バージョン確認**: 現在のバージョンと最新バージョンを比較
2. **ファイル同期**: `prompts/package/` から `docs/aidlc/` へrsync
3. **設定マイグレーション**: 新しい設定セクションの追加
4. **コミット**: 変更をGitコミット

## 更新対象

| ディレクトリ | 内容 |
|-------------|------|
| `docs/aidlc/prompts/` | フェーズプロンプト |
| `docs/aidlc/templates/` | ドキュメントテンプレート |
| `docs/aidlc/guides/` | ガイドドキュメント |
| `docs/aidlc/bin/` | ユーティリティスクリプト |
| `docs/aidlc/skills/` | スキルファイル |

## 注意事項

- `docs/aidlc.toml` の既存設定は保持されます
- `docs/cycles/rules.md` はプロジェクト固有のため上書きされません
- アップグレード完了後は新しいセッションで作業を開始してください
