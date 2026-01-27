# CI/CD設定 v1.10.0

## 現状のCI/CD構成

### ワークフロー一覧

| ワークフロー | ファイル | 目的 | トリガー |
|------------|---------|------|---------|
| Auto Tag | `.github/workflows/auto-tag.yml` | mainブランチへのpush時に自動でバージョンタグを作成 | push to main |
| PR Check | `.github/workflows/pr-check.yml` | Markdownlintによる自動チェック | PR to main (*.md変更時) |

### 各ワークフローの詳細

#### 1. Auto Tag（自動タグ付け）

**トリガー**: mainブランチへのpush

**処理内容**:
1. `version.txt` からバージョンを読み取り
2. 同名タグ（`v{VERSION}`）が存在しないか確認
3. 存在しなければタグを作成・push

**依存**: `version.txt` の内容

#### 2. PR Check（PRチェック）

**トリガー**: mainブランチへのPR（`**.md`, `.markdownlint.json`, `.github/workflows/pr-check.yml` 変更時）

**処理内容**:
1. Markdownlintを実行
2. 対象: `docs/translations/**/*.md`, `prompts/**/*.md`, `*.md`

## v1.10.0での変更

**新規ワークフロー**: なし

**変更点**: なし（既存のワークフローで対応可能）

## リリースフロー

1. サイクルブランチで `version.txt` を更新（完了: 1.10.0）
2. PRを作成・マージ
3. GitHub Actions が自動で `v1.10.0` タグを作成

## 今後の検討事項

- テンプレート整合性チェック（setup-prompt.md実行後の差分確認）
- セットアップテストの自動化
