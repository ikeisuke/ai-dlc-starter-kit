# Unit 006 計画: aidlc.tomlテンプレート化

## 概要

新規セットアップ時にaidlc.tomlをテンプレートファイルから生成できるようにする。これにより設定項目の一元管理と新規セットアップの簡素化を実現する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup/templates/aidlc.toml.template` | 新規作成 - aidlc.tomlのテンプレートファイル |
| `prompts/setup-prompt.md` | 修正 - セクション7.2でテンプレートファイルを参照するよう変更 |

## 実装計画

### Phase 1: テンプレートファイル作成

1. `prompts/setup/templates/aidlc.toml.template` を新規作成
   - 現在の `setup-prompt.md` セクション7.2のインラインテンプレートを抽出
   - プレースホルダーを使用（`{{CURRENT_DATE}}`, `{{VERSION}}`, `{{PROJECT_NAME}}` 等）
   - 全設定セクションとコメントを含める

### Phase 2: setup-prompt.md修正

1. セクション7.2「aidlc.toml の内容」を修正
   - インラインテンプレートを削除
   - テンプレートファイルを参照する指示に変更
   - プレースホルダーの置換ルールを記載

### 後方互換性の確認

- 新規セットアップ: テンプレートから `docs/aidlc.toml` を生成
- アップグレード: マイグレーションセクション（7.4）は変更なし（既存設定値を保持）

## 完了条件チェックリスト

- [ ] aidlc.toml.templateファイルが作成されている
- [ ] setup-prompt.mdの新規セットアップ時にテンプレートから生成するよう修正されている
- [ ] 既存のアップグレード時のマイグレーションロジックは維持されている

## 技術的考慮事項

- テンプレートファイルのパス: `prompts/setup/templates/aidlc.toml.template`
- `prompts/setup/` はセットアップ時のみ使用されるため、rsync対象外（docs/aidlc/には同期されない）
- これにより、セットアップ専用のテンプレートとして適切に分離される
