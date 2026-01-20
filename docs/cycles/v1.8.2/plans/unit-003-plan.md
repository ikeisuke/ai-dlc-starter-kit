# Unit 003 計画: その他のAIツール対応ドキュメント

## 概要

Claude Code以外のAIツール（Codex CLI、Gemini CLI、KiroCLI等）でAIスキルを利用する方法をドキュメント化する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/prompts/AGENTS.md` | 各AIツールでのスキル参照方法セクションを追加 |
| `prompts/package/guides/skill-usage-guide.md` | 新規作成: 各ツール向けスキル利用ガイド |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 各AIツールの特性とスキル参照方式を整理
2. **論理設計**: ドキュメント構成とセクション設計

### Phase 2: 実装

1. **スキル利用ガイド作成**: `prompts/package/guides/skill-usage-guide.md`
   - Codex CLI でのスキル利用方法
   - Gemini CLI でのスキル利用方法
   - KiroCLI でのスキル利用方法
   - 各ツールの制約と注意点

2. **AGENTS.md更新**: 既存のKiroCLI対応セクションを拡充し、他のツールも追加

## 完了条件チェックリスト

- [ ] 各AIツールでのスキル参照方法を文書化
  - [ ] Codex CLI: プロジェクト内ファイルの直接参照
  - [ ] Gemini: MCP経由でのファイル読み取り
  - [ ] KiroCLI: `resources` フィールドへのスキル追加例
- [ ] AGENTS.md の各ツール対応セクションを更新
- [ ] 必要に応じてスキルファイル内に各ツール向けの説明を追加

## 備考

- スキルファイルは Unit 001 で `prompts/package/skills/` に配置済み
- セットアップスクリプトは Unit 002 で `docs/aidlc/skills/` への同期対応済み
- 既存の KiroCLI 対応セクションは AGENTS.md に存在（拡充対象）
