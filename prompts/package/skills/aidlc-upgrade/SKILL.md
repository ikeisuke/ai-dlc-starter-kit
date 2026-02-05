---
name: aidlc-upgrade
description: AI-DLC環境をアップグレードする。スターターキットの最新バージョンにプロンプト・テンプレートを更新。「AIDLCアップデート」「update aidlc」「start upgrade」と指示された場合に使用。
argument-hint: (引数なし)
---

# AI-DLC Upgrade

AI-DLC環境を最新バージョンにアップグレードするスキル。

## 実行方法

`prompts/setup-prompt.md` を読み込んでください。

```text
prompts/setup-prompt.md を読み込んで、AI-DLC 環境をアップグレードしてください
```

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
