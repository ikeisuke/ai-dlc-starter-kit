# 既存コードベース分析

## ディレクトリ構造・ファイル構成

変更対象に関連する主要ディレクトリ:

```
prompts/package/
├── prompts/          # フェーズプロンプト（inception.md, construction.md, operations.md）
├── templates/        # 22個のテンプレート（intent, user_stories, unit_definition等）
├── guides/           # ガイドドキュメント
├── config/           # defaults.toml（デフォルト設定）
docs/aidlc/           # prompts/package/ のrsyncコピー（直接編集禁止）
docs/aidlc.toml       # プロジェクト設定
.claude/skills/       # レビュースキル
├── reviewing-architecture/SKILL.md
├── reviewing-inception/SKILL.md
├── reviewing-code/SKILL.md
├── reviewing-security/SKILL.md
```

## アーキテクチャ・パターン

- **設定管理**: `docs/aidlc.toml` + `docs/aidlc/config/defaults.toml` の2層構成。`read-config.sh` が `docs/aidlc.local.toml` も含めたマージ読み込みを提供
- **スキルパターン**: 全レビュースキルが統一されたデュアルモード構造（外部CLI通常モード + セルフレビューフォールバック）を採用
- **メタ開発構造**: `prompts/package/` が正本、`docs/aidlc/` はrsyncコピー

## 技術スタック

| 項目 | 値 | 根拠ファイル |
|------|-----|-------------|
| 設定形式 | TOML | docs/aidlc.toml |
| スクリプト | Bash (シェルスクリプト) | docs/aidlc/bin/*.sh |
| 設定パーサ | dasel | docs/aidlc/bin/read-config.sh |
| レビューツール | codex / claude / gemini | .claude/skills/reviewing-*/SKILL.md |

## 依存関係

- **reviewing-architectureスキル** → `docs/aidlc.toml` の設定参照（v1.28.0で追加予定）
- **reviewing-inceptionスキル** → Inception Phaseプロンプトのレビュー観点に依存
- **Inception Phaseプロンプト** → テンプレート群（`templates/`）に依存
- **`docs/aidlc/`** → `prompts/package/` のrsyncコピー（Operations Phaseで同期）

## 特記事項

- `docs/aidlc.toml` の `[rules]` セクションには17個のサブセクションが既存。`[rules.architecture]` は未定義
- `defaults.toml` にも `[rules.architecture]` は未定義。新規追加が必要
- reviewing-architecture の現在の観点は構造・パターン・API設計・依存関係の4カテゴリ。toml設定参照による検証は未実装
- reviewing-inception の現在の観点はIntent品質・ユーザーストーリー品質・Unit定義品質の3カテゴリ。AIDLC固有の観点拡張は未実装
- Inception Phaseプロンプトに意思決定記録に関する記述は現時点でなし
- テンプレートカタログに意思決定記録用テンプレートは未存在
