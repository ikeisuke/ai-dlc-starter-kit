# CI/CD設定 v1.11.0

## 現状確認

### 既存ワークフロー

| ワークフロー | 目的 | トリガー |
|--------------|------|----------|
| auto-tag.yml | 自動タグ作成 | main push |
| pr-check.yml | Markdownlint | PR作成時 |

### auto-tag.yml

- mainブランチへのpush時に実行
- version.txt からバージョン読み取り
- 同名タグが存在しなければ作成・push
- **変更不要**

### pr-check.yml

- PRでMarkdownlintを実行
- 対象: `docs/translations/**/*.md`, `prompts/**/*.md`, `*.md`
- **変更不要**

## 今サイクルでの変更

なし（既存設定で運用継続）

## 将来検討事項

- テンプレート整合性チェックの自動化
- セットアップテストの自動化
