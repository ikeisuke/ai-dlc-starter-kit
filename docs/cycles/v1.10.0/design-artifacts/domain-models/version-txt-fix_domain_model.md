# ドメインモデル: version.txt参照問題修正

## 概要

AIがバージョン情報を取得する際のパス参照の曖昧さを解消する。

## 問題ドメイン

### 現状のバージョン参照構造

```
リポジトリルート/
├── version.txt              # スターターキットのバージョン (1.9.3)
├── docs/
│   └── aidlc.toml           # プロジェクトのバージョン (starter_kit_version)
└── prompts/
    ├── setup-prompt.md      # 問題箇所: 「../version.txt」という曖昧な記述
    └── setup/
        └── bin/
            └── check-version.sh  # 正しくパス解決している
```

### 問題のエンティティ

| 要素 | 現状 | あるべき姿 |
|------|------|-----------|
| setup-prompt.md の記述 | `../version.txt` | プロジェクトルートの `version.txt` |
| AIの解釈 | `prompts/version.txt` | `version.txt` (ルート) |

## 修正方針

相対パス表記 `../version.txt` を、AIが誤解しない明確な表現に変更する。

**変更前**:
> このファイル（setup-prompt.md）のディレクトリから `../version.txt` を読み込み

**変更後**:
> プロジェクトルートの `version.txt`（リポジトリルート直下）を読み込み

## 境界条件

- `check-version.sh` のパス解決ロジックは変更しない（正常動作中）
- `prompts/package/prompts/setup.md` の GitHub URL 参照は変更しない（正常動作中）
