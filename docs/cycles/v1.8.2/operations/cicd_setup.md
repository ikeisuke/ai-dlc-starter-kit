# CI/CD設定

サイクル: v1.8.2

## 現状のCI/CD設定

### GitHub Actions ワークフロー

| ワークフロー | ファイル | 用途 |
|------------|---------|------|
| Auto Tag on Main | `.github/workflows/auto-tag.yml` | mainブランチpush時に自動タグ作成 |
| PR Check | `.github/workflows/pr-check.yml` | PRでMarkdown変更時にlintチェック |

### 自動タグ付け（auto-tag.yml）

- **トリガー**: mainブランチへのpush
- **処理内容**:
  1. version.txtからバージョン読み取り
  2. タグが存在しない場合のみ作成
  3. `v{VERSION}` 形式でタグをpush

### PRチェック（pr-check.yml）

- **トリガー**: mainブランチへのPR（.mdファイル変更時）
- **対象ファイル**:
  - `docs/translations/**/*.md`
  - `prompts/**/*.md`
  - `*.md`
- **チェック内容**: markdownlint-cli2によるlintチェック

## v1.8.2での変更

変更なし。既存のCI/CD設定で対応可能。

### v1.8.2の主な変更内容

1. スキルファイル対応
2. セットアップスクリプト化
3. KiroCLIドキュメント追加
4. AIレビュー設定強化（ai_tools対応）
5. jjサポート強化（よくあるミスと対処法）

これらはすべてドキュメント・設定ファイルの変更であり、既存のCI/CDワークフローで対応可能。

## 将来検討事項

- シェルスクリプトのlintチェック追加（shellcheck）
- テンプレート整合性チェック
- セットアップテストの自動化
