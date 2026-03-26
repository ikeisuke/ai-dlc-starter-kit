# CI/CD セットアップ

## 現状確認

既存のCI/CD設定を確認し、v1.5.4リリースに必要な変更がないことを確認しました。

## 設定ファイル

### 1. 自動タグ付け（auto-tag.yml）

**パス**: `.github/workflows/auto-tag.yml`

**トリガー**: mainブランチへのpush

**動作**:
1. version.txtからバージョンを読み取り
2. 同名タグが存在しなければ`v{VERSION}`タグを作成・push

**ステータス**: 変更不要

### 2. PRチェック（pr-check.yml）

**パス**: `.github/workflows/pr-check.yml`

**トリガー**: mainブランチへのPR（Markdownファイル変更時）

**動作**:
- markdownlint-cli2-actionでMarkdownファイルをリント

**ステータス**: 変更不要

## v1.5.4での確認事項

- [x] auto-tag.ymlが正しく設定されている
- [x] pr-check.ymlが正しく設定されている
- [x] version.txt（1.5.4）と整合している

## リリースフロー

```
サイクルブランチ (cycle/v1.5.4)
       │
       ▼ PRマージ
    main
       │
       ▼ auto-tag.ymlがトリガー
    タグ作成 (v1.5.4)
```

## 備考

今回のサイクル（v1.5.4）ではCI/CD設定の変更は不要です。
既存の設定で自動タグ付けとMarkdownリントが正しく動作します。
