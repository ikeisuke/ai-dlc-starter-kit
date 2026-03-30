# 論理設計: lib/ディレクトリrsync同期追加

## コンポーネント構成

変更対象コンポーネント: `aidlc-setup.sh`（セットアップスクリプト）

## 変更内容

### SYNC_DIRS配列

```text
変更前: ["prompts", "templates", "guides", "bin", "skills", "kiro"]
変更後: ["prompts", "templates", "guides", "bin", "skills", "kiro", "lib"]
```

### データフロー

```text
prompts/package/lib/ --[rsync -a]--> docs/aidlc/lib/
```

## インターフェース

既存の同期ループインターフェースをそのまま使用。新規インターフェースの追加なし。

## 依存関係

- rsyncコマンド（既存依存、新規追加なし）
- `prompts/package/lib/`ディレクトリの存在（ソース不在時はスキップ）
