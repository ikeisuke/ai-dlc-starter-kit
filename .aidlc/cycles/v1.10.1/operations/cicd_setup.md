# CI/CD設定

## サイクル情報

- **サイクル**: v1.10.1
- **確認日**: 2026-01-28

## 現在のCI/CD構成

### GitHub Actions ワークフロー

| ワークフロー | ファイル | 目的 |
|------------|---------|------|
| 自動タグ付け | `.github/workflows/auto-tag.yml` | mainブランチへのpush時にversion.txtからタグを自動作成 |
| PRチェック | `.github/workflows/pr-check.yml` | Markdownlintによる自動チェック |

### 自動タグ付けの仕組み

1. mainブランチにpush
2. `version.txt` からバージョンを読み取り
3. 同名タグが存在しなければ `v{VERSION}` タグを作成・push

### PRチェックの対象

- `docs/translations/**/*.md`
- `prompts/**/*.md`
- `*.md`

## 今回のサイクルでの変更

- **変更なし** - 既存のCI/CD設定で対応可能

## 将来検討事項

- テンプレート整合性チェック
- セットアップテストの自動化
- Skill ファイルの構文チェック

## 参照

- 運用引き継ぎ情報: `docs/cycles/operations.md`
