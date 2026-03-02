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

`docs/aidlc.toml` の `[project]` セクションから `starter_kit_repo` を取得し、`ghq root` 経由でパスを解決する。

1. 事前にBashで以下を順に実行し、結果を変数に格納:

```bash
# 1. ghq root を取得
ghq root
```

```bash
# 2. docs/aidlc.toml から starter_kit_repo を取得（デフォルト: ghq:github.com/ikeisuke/ai-dlc-starter-kit）
docs/aidlc/bin/read-config.sh project.starter_kit_repo --default "ghq:github.com/ikeisuke/ai-dlc-starter-kit"
```

2. 取得した値を使ってパスを組み立て:
   - `GHQ_ROOT`: 手順1の出力
   - `RAW_REPO`: 手順2の出力
   - `REPO`: RAW_REPOから `ghq:` プレフィックスを除去
   - `SETUP_PATH`: `{GHQ_ROOT}/{REPO}/prompts/setup-prompt.md`

解決したパスのファイルを読み込む。

**重要**: Glob等の再帰検索は行わないこと。解決できない場合は `docs/aidlc.toml` の設定を確認する。

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
