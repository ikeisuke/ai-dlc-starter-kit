# Unit 005 計画: KiroCLI Skills対応

## 概要

KiroCLI Skills機能を調査し、セットアップ時にKiroCLIエージェント設定を自動生成する。

## 変更対象ファイル

- `docs/cycles/v1.9.2/research/kirocli-skills.md`（新規作成 - 調査レポート）
- `prompts/setup-prompt.md`（変更 - KiroCLIエージェント設定生成処理を追加）

## 実装計画

### Phase 1: 設計（調査）

1. **ドメインモデル設計**: KiroCLI Skills機能の概念モデルを調査・定義
2. **論理設計**: スキルファイルの構造と記述方法を設計
3. **設計レビュー**: ユーザー承認を得る

### Phase 2: 実装

4. **調査レポート作成**: 調査結果をドキュメント化
5. **スキルファイル作成**: KiroCLI用SKILL.mdを作成
6. **統合とレビュー**: 既存スキルとの共存確認、最終レビュー

## 完了条件チェックリスト

- [ ] KiroCLI Skills機能の調査が完了している
- [ ] 調査レポートが作成されている
- [ ] KiroCLI用スキルファイルが作成されている
- [ ] 既存スキルとの共存が確認されている

## 技術的考慮事項

### 調査項目

| 項目 | 説明 |
|------|------|
| フロントマター形式 | スキルファイルのメタデータ形式 |
| 必須セクション | 必要なセクション構成 |
| resources指定方法 | 依存ファイルの指定方法 |
| 既存スキルとの違い | Claude Code/Codex/Geminiスキルとの差異 |

### 参考リソース

- KiroCLI公式ドキュメント（v1.24.0以降）
- 既存スキル: `prompts/package/skills/codex/SKILL.md`, `claude/SKILL.md`, `gemini/SKILL.md`

### 想定される成果物構造

```
prompts/package/skills/kiro/
└── SKILL.md
```
