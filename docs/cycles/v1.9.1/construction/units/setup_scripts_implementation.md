# 実装記録: Unit 003 確認系処理のスクリプト化

## 概要

setup-prompt.md 内の確認系処理（バージョン比較、セットアップ種類判定）をスクリプト化し、プロンプトを簡素化した。

## 実装日

2026-01-24

## 成果物

### 新規作成ファイル

| ファイル | 説明 |
|----------|------|
| `prompts/package/bin/check-version.sh` | バージョン比較スクリプト |
| `prompts/package/bin/check-setup-type.sh` | セットアップ種類判定スクリプト |

### 変更ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-prompt.md` | セクション2のインライン処理をスクリプト呼び出しに置換 |

## 実装詳細

### check-version.sh

- プロジェクトとスターターキットのバージョンを比較
- 出力形式: `version_status:{状態}`
- セマンティックバージョン形式の検証を含む
- dasel未インストール時は空値を返す

### check-setup-type.sh

- 設定ファイル状態とバージョン情報からセットアップ種類を判定
- 出力形式: `setup_type:{種類}`
- check-version.sh を内部で呼び出す

### setup-prompt.md

- セクション2のインライン bash コードを削除
- `check-setup-type.sh` の呼び出しに置換
- ケース A〜E の判定条件をスクリプト出力に対応

## テスト結果

```text
$ prompts/package/bin/check-version.sh
version_status:current

$ prompts/package/bin/check-setup-type.sh
setup_type:cycle_start
```

## レビュー

### 設計レビュー

- AIレビュー（Codex）: 6ラウンドの反復レビュー後 LGTM

### 実装レビュー

- AIレビュー（Codex）: 2ラウンドの反復レビュー後 LGTM
- 修正内容: dasel が null を返した場合の処理追加、セマンティックバージョン形式検証

## 状態

完了
