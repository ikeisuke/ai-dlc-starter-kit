# jjサポート有効化フラグ

- **発見日**: 2026-01-11
- **発見フェーズ**: Operations
- **発見サイクル**: v1.7.0
- **優先度**: 低

## 概要

`[rules.jj].enabled` フラグを追加し、jjサポートの有効/無効を切り替えられるようにする。

## 詳細

### 現状
- jj-support.md（ガイド）はv1.7.0で追加済み
- 有効化フラグがないため、ガイドを参照するかどうかはユーザー判断

### 提案する設定

```toml
[rules.jj]
# jjサポート設定（v1.8.0で追加予定）
# enabled: true | false
# - true: プロンプト内でjjコマンドを優先的に案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false
```

### フォールバック動作
- 設定がない場合: `enabled = false` として扱う（git使用）
- AIレビュー設定と同様のパターン

### プロンプトへの影響
- `enabled = true` の場合:
  - コミット操作時に `jj describe` + `jj new` を案内
  - ブランチ操作時に `jj bookmark` を案内
  - jj-support.md への参照を追加
- `enabled = false` の場合:
  - 従来通りgitコマンドを使用

## 関連

- feature-aidlc-toml-local.md（個人設定サポート）
- jj-support.md（既存ガイド）

## 推奨対応サイクル

v1.8.0（aidlc.toml.localと同時対応が望ましい）
