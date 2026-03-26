# Unit 2: 変数具体例削除 - 実装計画

## 概要
セットアップテンプレート内の変数一覧から具体例（v1.0.1等）を削除し、AIの誤解を防止する

## 対象ファイル
- `prompts/setup/common.md`

## 変更内容

### 変更前（19〜36行目）
```markdown
| 変数名 | 説明 | 例 |
|--------|------|-----|
| `{{PROJECT_NAME}}` | プロジェクト名 | AI-DLC Starter Kit |
| `{{CYCLE}}` | サイクル識別子 | v1.0.1 |
| `{{BRANCH}}` | ブランチ名 | feature/v1.0.1 |
| `{{DEVELOPMENT_TYPE}}` | 開発タイプ | greenfield / brownfield |
| `{{PROJECT_TYPE}}` | プロジェクトタイプ | ios / android / web / backend / general |
| `{{AIDLC_ROOT}}` | 共通ファイルルート | docs/aidlc |
| `{{CYCLES_ROOT}}` | サイクルルート | docs/cycles |
| `{{ROLE_INCEPTION}}` | Inception役割 | プロダクトマネージャー兼ビジネスアナリスト |
| `{{ROLE_CONSTRUCTION}}` | Construction役割 | ソフトウェアアーキテクト兼エンジニア |
| `{{ROLE_OPERATIONS}}` | Operations役割 | DevOpsエンジニア兼SRE |
| `{{SETUP_PROMPT_PATH}}` | セットアッププロンプトのパス | /path/to/setup-prompt.md |
| `{{PROJECT_SUMMARY}}` | プロジェクト概要（1行） | [セットアップ時に設定] |
| `{{LANGUAGE}}` | 使用言語 | 日本語 |
| `{{DEVELOPER_EXPERTISE}}` | 開発者の専門分野 | ソフトウェア開発 |
| `{{PROJECT_README}}` | プロジェクトREADMEパス | /README.md |
| `{{CYCLE_TYPE}}` | サイクルタイプ | Full / Lite |
```

### 変更後
```markdown
| 変数名 | 説明 |
|--------|------|
| `{{PROJECT_NAME}}` | プロジェクト名 |
| `{{CYCLE}}` | サイクル識別子 |
| `{{BRANCH}}` | ブランチ名 |
| `{{DEVELOPMENT_TYPE}}` | 開発タイプ（greenfield / brownfield） |
| `{{PROJECT_TYPE}}` | プロジェクトタイプ（ios / android / web / backend / general） |
| `{{AIDLC_ROOT}}` | 共通ファイルルート |
| `{{CYCLES_ROOT}}` | サイクルルート |
| `{{ROLE_INCEPTION}}` | Inception役割 |
| `{{ROLE_CONSTRUCTION}}` | Construction役割 |
| `{{ROLE_OPERATIONS}}` | Operations役割 |
| `{{SETUP_PROMPT_PATH}}` | セットアッププロンプトのパス |
| `{{PROJECT_SUMMARY}}` | プロジェクト概要（1行） |
| `{{LANGUAGE}}` | 使用言語 |
| `{{DEVELOPER_EXPERTISE}}` | 開発者の専門分野 |
| `{{PROJECT_README}}` | プロジェクトREADMEパス |
| `{{CYCLE_TYPE}}` | サイクルタイプ（Full / Lite） |
```

## 変更の理由

1. **具体例が誤解を招く**: `v1.0.1` などの具体的な値がAIに「これが正しい値」と誤解される可能性
2. **選択肢型の変数**: `DEVELOPMENT_TYPE`、`PROJECT_TYPE`、`CYCLE_TYPE` は選択肢なので説明に含める
3. **シンプルな構造**: 例列を削除し、2列構成に統一

## 設計フェーズ

このUnitは単純なテキスト修正のため、詳細なドメインモデル・論理設計は省略し、計画のみで実装に進む。

## テスト方法

1. 変更後のテーブルが正しくマークダウンとして表示されることを確認
2. 変数の説明が十分に理解可能であることを確認

## 作成日
2024-12-04
