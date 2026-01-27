# 実装記録: version.txt参照問題修正

## Unit情報

- **Unit番号**: 001
- **Unit名**: version.txt参照問題修正
- **関連Issue**: #126

## 実装概要

`prompts/setup-prompt.md` のバージョンファイル参照記述を明確化し、AIが誤って `prompts/version.txt` を参照する問題を解消した。

## 変更内容

### 変更ファイル

| ファイル | 変更種別 | 変更内容 |
|---------|---------|---------|
| `prompts/setup-prompt.md` | 修正 | 128行目のパス表記を明確化 |

### 変更詳細

**変更前**:
```
また、このファイル（setup-prompt.md）のディレクトリから `../version.txt` を読み込み
```

**変更後**:
```
また、プロジェクトルートの `version.txt`（リポジトリルート直下）を読み込み
```

## テスト結果

### 動作確認

```bash
$ prompts/setup/bin/check-version.sh
version_status:current
```

正常動作を確認。

## 完了状態

- **状態**: 完了
- **完了日**: 2026-01-27
