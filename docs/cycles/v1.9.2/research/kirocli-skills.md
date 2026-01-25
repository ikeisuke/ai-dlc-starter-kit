# KiroCLI Skills機能 調査レポート

## 調査概要

- **調査日**: 2026-01-26
- **調査目的**: KiroCLI Skills機能を調査し、AI-DLCスキルとの統合方法を明確化する
- **対象バージョン**: KiroCLI v1.24.0以降

## 調査結果

### Skills機能の特徴

| 項目 | 内容 |
|------|------|
| ファイル形式 | Markdown + YAMLフロントマター |
| 必須フィールド | `name`, `description` |
| 読み込み方式 | プログレッシブローディング |
| 参照方式 | `skill://` URIスキーム |
| パス指定 | 絶対パス・相対パス両対応、グロブパターン可 |

### プログレッシブローディング

KiroCLI Skillsはコンテキスト効率化のため、2段階で読み込まれる：

1. **Stage 1（起動時）**: メタデータ（name, description）のみ読み込み
2. **Stage 2（必要時）**: エージェントが必要と判断した時点で全文読み込み

これにより、多数のスキルを持つエージェントでもコンテキストウィンドウを圧迫しない。

### SKILL.mdファイル形式

```yaml
---
name: skill-identifier
description: スキルの説明。エージェントがいつ読み込むべきか判断できる具体的な記述。
---

# スキルタイトル

本文コンテンツ...
```

**ベストプラクティス**: descriptionは「どのような状況でこのスキルを使うか」が明確にわかるよう具体的に記述する。

### エージェント設定でのスキル参照

```json
{
  "resources": [
    "skill://path/to/SKILL.md",
    "skill://.kiro/skills/**/SKILL.md"
  ]
}
```

- 特定ファイルの指定: `skill://docs/aidlc/skills/codex/SKILL.md`
- グロブパターン: `skill://docs/aidlc/skills/*/SKILL.md`

## 既存スキルとの互換性

### AI-DLC既存スキルの分析

| スキル | フロントマター | 形式 | KiroCLI互換 |
|--------|---------------|------|-------------|
| codex | name, description | Markdown | **互換** |
| claude | name, description | Markdown | **互換** |
| gemini | name, description | Markdown | **互換** |

### 互換性の根拠

既存スキルはすべて以下を満たしている：
- YAMLフロントマターに `name` と `description` を含む
- Markdown形式で記述
- CLIコマンドの使い方を本文に記載

**結論**: 既存スキルは変更なしでKiroCLIから利用可能。

## 設計への反映

### 採用した方針

- **セットアップ時に自動生成**: `.kiro/agents/aidlc.json` をセットアップ時に自動生成
- **直接参照**: `skill://docs/aidlc/skills/*/SKILL.md` でスキルを直接参照
- **既存スキル変更なし**: 互換性があるためそのまま利用
- **AGENTS.md参照**: `file://docs/aidlc/prompts/AGENTS.md` でAI-DLC指示を参照

### 却下した方針

- `.kiro/skills/` へのコピー: 冗長であり、同期の手間が発生するため却下
- `kiro/SKILL.md` スキルファイル作成: セットアップで自動生成する方が簡便

### 変更したファイル

- `prompts/setup-prompt.md`: KiroCLIエージェント設定の自動生成処理を追加
- `prompts/package/prompts/AGENTS.md`: KiroCLI対応セクションを更新

## 参考資料

- [Agent configuration reference - Kiro Docs](https://kiro.dev/docs/cli/custom-agents/configuration-reference/)
- [Creating custom agents - Kiro Docs](https://kiro.dev/docs/cli/custom-agents/creating/)
- [Agent Examples - Kiro Docs](https://kiro.dev/docs/cli/custom-agents/examples/)
