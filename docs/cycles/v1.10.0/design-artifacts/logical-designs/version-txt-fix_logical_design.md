# 論理設計: version.txt参照問題修正

## 概要

`prompts/setup-prompt.md` のバージョンファイル参照記述を明確化する。

## 変更対象

### ファイル: `prompts/setup-prompt.md`

**位置**: 128行目

**変更前**:
```markdown
**dasel未インストールの場合**（`setup_type:` と空値が返る場合）: AIは `docs/aidlc.toml` を読み込み、`starter_kit_version` の値を取得してください。また、このファイル（setup-prompt.md）のディレクトリから `../version.txt` を読み込み、スターターキットのバージョンと比較してください。
```

**変更後**:
```markdown
**dasel未インストールの場合**（`setup_type:` と空値が返る場合）: AIは `docs/aidlc.toml` を読み込み、`starter_kit_version` の値を取得してください。また、プロジェクトルートの `version.txt`（リポジトリルート直下）を読み込み、スターターキットのバージョンと比較してください。
```

## 変更のポイント

1. 「このファイル（setup-prompt.md）のディレクトリから」という相対的な説明を削除
2. 「プロジェクトルートの」という明確な位置指定を追加
3. 「リポジトリルート直下」という補足を追加してAIの誤解を防止

## 影響範囲

- `check-version.sh`: 変更なし（パス解決ロジックは維持）
- `prompts/package/prompts/setup.md`: 変更なし（GitHub URL参照は維持）
- AIの動作: `prompts/version.txt` ではなく正しく `version.txt` を参照するようになる

## テスト方法

1. `prompts/setup/bin/check-version.sh` を実行し、正常動作を確認
2. 修正後のプロンプトを読んだAIが正しいパスを参照することを確認
